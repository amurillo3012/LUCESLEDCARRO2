import SwiftUI
import CoreBluetooth
import MediaPlayer
import Vision

// MARK: - Advanced Spotify Manager with Color Extraction
class AdvancedSpotifyManager: NSObject, ObservableObject {
    @Published var isConnected = false
    @Published var currentTrack = ""
    @Published var currentArtist = ""
    @Published var albumArtURL: URL?
    @Published var dominantColor: Color = .cyan
    @Published var isPlaying = false
    @Published var currentBPM: Int = 100
    @Published var energyLevel: Double = 0.5
    @Published var danceability: Double = 0.5
    @Published var valence: Double = 0.5
    @Published var syncMode = SyncMode.color
    
    private let clientID = "YOUR_CLIENT_ID"
    private let redirectURI = "ledcar01://callback"
    private var accessToken: String?
    private var currentTrackID: String?
    private var refreshTimer: Timer?
    
    enum SyncMode {
        case color           // Sincronizar solo color
        case energy          // Sincronizar color + velocidad efecto
        case beat            // Sincronizar con beat (cambio rápido)
        case mood            // Sincronizar según valence + energy
    }
    
    func connectToSpotify() {
        let scopes = [
            "streaming",
            "user-read-private",
            "user-read-email",
            "user-read-playback-state",
            "user-modify-playback-state",
            "user-read-currently-playing"
        ]
        
        let authURL = buildAuthURL(scopes: scopes)
        
        if let url = authURL {
            DispatchQueue.main.async {
                UIApplication.shared.open(url)
            }
        }
    }
    
    func handleCallback(url: URL) {
        guard let components = URLComponents(url: url, resolvingAgainstBaseURL: true),
              let code = components.queryItems?.first(where: { $0.name == "code" })?.value
        else { return }
        
        exchangeCodeForToken(code: code)
    }
    
    private func exchangeCodeForToken(code: String) {
        var request = URLRequest(url: URL(string: "https://accounts.spotify.com/api/token")!)
        request.httpMethod = "POST"
        
        let body = [
            "grant_type": "authorization_code",
            "code": code,
            "redirect_uri": redirectURI,
            "client_id": clientID,
            "client_secret": "YOUR_CLIENT_SECRET"
        ]
        
        request.httpBody = encodeFormData(body)
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        
        URLSession.shared.dataTask(with: request) { [weak self] data, _, _ in
            guard let data = data,
                  let response = try? JSONDecoder().decode(TokenResponse.self, from: data)
            else { return }
            
            self?.accessToken = response.access_token
            DispatchQueue.main.async {
                self?.isConnected = true
                self?.startSyncingWithSpotify()
            }
        }.resume()
    }
    
    private func startSyncingWithSpotify() {
        refreshTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            self?.updateCurrentPlayback()
        }
    }
    
    private func updateCurrentPlayback() {
        guard let token = accessToken else { return }
        
        var request = URLRequest(url: URL(string: "https://api.spotify.com/v1/me/player/currently-playing")!)
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        
        URLSession.shared.dataTask(with: request) { [weak self] data, _, _ in
            guard let data = data,
                  let response = try? JSONDecoder().decode(CurrentPlaybackResponse.self, from: data)
            else { return }
            
            DispatchQueue.main.async {
                self?.isPlaying = response.is_playing
                
                if let item = response.item {
                    self?.currentTrack = item.name
                    self?.currentArtist = item.artists.first?.name ?? ""
                    self?.currentTrackID = item.id
                    
                    if let imageURL = item.album.images.first?.url {
                        self?.albumArtURL = URL(string: imageURL)
                        self?.extractDominantColor(from: imageURL)
                    }
                    
                    // Obtener características de audio
                    self?.fetchAudioFeatures(trackID: item.id)
                }
            }
        }.resume()
    }
    
    private func fetchAudioFeatures(trackID: String) {
        guard let token = accessToken else { return }
        
        let url = "https://api.spotify.com/v1/audio-features/\(trackID)"
        var request = URLRequest(url: URL(string: url)!)
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        
        URLSession.shared.dataTask(with: request) { [weak self] data, _, _ in
            guard let data = data,
                  let response = try? JSONDecoder().decode(AudioFeaturesResponse.self, from: data)
            else { return }
            
            DispatchQueue.main.async {
                self?.currentBPM = Int(response.tempo)
                self?.energyLevel = response.energy
                self?.danceability = response.danceability
                self?.valence = response.valence
            }
        }.resume()
    }
    
    // MARK: - Color Extraction from Album Art
    private func extractDominantColor(from urlString: String) {
        guard let url = URL(string: urlString) else { return }
        
        URLSession.shared.dataTask(with: url) { [weak self] data, _, _ in
            guard let data = data, let image = UIImage(data: data) else { return }
            
            DispatchQueue.main.async {
                self?.dominantColor = self?.extractColor(from: image) ?? .cyan
            }
        }.resume()
    }
    
    private func extractColor(from image: UIImage) -> Color {
        let cgImage = image.cgImage ?? image.cgImage!
        let nsImage = image
        
        // Redimensionar a pequeño tamaño para procesar rápido
        let width = 50
        let height = 50
        
        guard let resized = resizeImage(nsImage, toSize: CGSize(width: width, height: height)),
              let ciImage = CIImage(image: resized) else {
            return .cyan
        }
        
        // Usar Vision para obtener colores dominantes
        let colors = getColorHistogram(from: resized)
        
        if let dominantRGB = colors.first {
            return Color(
                red: Double(dominantRGB.0) / 255.0,
                green: Double(dominantRGB.1) / 255.0,
                blue: Double(dominantRGB.2) / 255.0
            )
        }
        
        return .cyan
    }
    
    private func resizeImage(_ image: UIImage, toSize size: CGSize) -> UIImage? {
        UIGraphicsBeginImageContextWithOptions(size, false, 0.0)
        image.draw(in: CGRect(origin: .zero, size: size))
        let resized = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return resized
    }
    
    private func getColorHistogram(from image: UIImage) -> [(UInt8, UInt8, UInt8)] {
        guard let cgImage = image.cgImage else { return [] }
        
        let width = cgImage.width
        let height = cgImage.height
        let bytesPerPixel = 4
        let bytesPerRow = bytesPerPixel * width
        let bitsPerComponent = 8
        
        var pixelData = [UInt8](repeating: 0, count: width * height * bytesPerPixel)
        
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        let context = CGContext(
            data: &pixelData,
            width: width,
            height: height,
            bitsPerComponent: bitsPerComponent,
            bytesPerRow: bytesPerRow,
            space: colorSpace,
            bitmapInfo: CGImageAlphaInfo.noneSkipLast.rawValue
        )
        
        guard let ctx = context else { return [] }
        ctx.draw(cgImage, in: CGRect(x: 0, y: 0, width: width, height: height))
        
        // Agrupar píxeles por color similar (k-means simplificado)
        var colorCounts: [String: Int] = [:]
        
        for i in stride(from: 0, to: pixelData.count, by: bytesPerPixel) {
            let r = pixelData[i]
            let g = pixelData[i + 1]
            let b = pixelData[i + 2]
            
            // Agrupar en cuantización de colores (divisor = 50 = 5 nivel)
            let quantized = "\(r/50),\(g/50),\(b/50)"
            colorCounts[quantized, default: 0] += 1
        }
        
        // Obtener 5 colores más frecuentes
        let topColors = colorCounts
            .sorted { $0.value > $1.value }
            .prefix(5)
            .compactMap { colorStr -> (UInt8, UInt8, UInt8)? in
                let components = colorStr.key.split(separator: ",").compactMap { UInt8($0) }
                guard components.count == 3 else { return nil }
                return (components[0] * 50, components[1] * 50, components[2] * 50)
            }
        
        return topColors
    }
    
    // MARK: - Sincronización Inteligente
    func generateSyncCommand(for btManager: BluetoothManager) {
        switch syncMode {
        case .color:
            syncByColor(btManager)
        case .energy:
            syncByEnergy(btManager)
        case .beat:
            syncByBeat(btManager)
        case .mood:
            syncByMood(btManager)
        }
    }
    
    private func syncByColor(_ btManager: BluetoothManager) {
        let comps = UIColor(dominantColor).cgColor.components ?? [0, 0, 1, 1]
        let r = UInt8(comps[0] * 255)
        let g = UInt8(comps[1] * 255)
        let b = UInt8(comps[2] * 255)
        
        btManager.setColor(r: r, g: g, b: b)
    }
    
    private func syncByEnergy(_ btManager: BluetoothManager) {
        // Color del album + velocidad según energía
        let comps = UIColor(dominantColor).cgColor.components ?? [0, 0, 1, 1]
        let r = UInt8(comps[0] * 255)
        let g = UInt8(comps[1] * 255)
        let b = UInt8(comps[2] * 255)
        
        btManager.setColor(r: r, g: g, b: b)
        
        // Mayor energía = efecto más rápido
        let speed = UInt8(energyLevel * 100)
        btManager.setEffectSpeed(speed)
        
        // Mayor energía = efecto más dinámico
        let effectCode: UInt8 = energyLevel > 0.7 ? 0x87 : 0x89  // Jump vs Gradient
        btManager.setEffect(effectCode)
    }
    
    private func syncByBeat(_ btManager: BluetoothManager) {
        // Cambio rápido de color al beat
        // BPM = beats per minute
        let interval = 60.0 / Double(currentBPM)  // Segundos por beat
        
        let colors: [(r: UInt8, g: UInt8, b: UInt8)] = [
            (255, 0, 0),      // Rojo
            (0, 255, 0),      // Verde
            (0, 0, 255),      // Azul
            (255, 255, 0),    // Amarillo
            (255, 0, 255),    // Magenta
            (0, 255, 255),    // Cian
        ]
        
        // Alternar entre colores a cada beat
        let colorIndex = Int(Date().timeIntervalSince1970 / interval) % colors.count
        let color = colors[colorIndex]
        
        btManager.setColor(r: color.r, g: color.g, b: color.b)
    }
    
    private func syncByMood(_ btManager: BluetoothManager) {
        // Valence = felicidad/tristeza
        // Energy = intensidad
        // Danceability = ritmo
        
        var r: UInt8, g: UInt8, b: UInt8
        
        // Mapear valence (0=triste/azul, 1=feliz/amarillo)
        if valence > 0.6 {
            // Música feliz - colores cálidos
            r = UInt8(valence * 255)
            g = UInt8(valence * 200)
            b = 0
        } else if valence < 0.4 {
            // Música triste - colores fríos
            r = 0
            g = UInt8((1 - valence) * 150)
            b = UInt8((1 - valence) * 255)
        } else {
            // Neutral - mezcla
            r = UInt8(energyLevel * 255)
            g = UInt8((1 - energyLevel) * 150)
            b = UInt8(danceability * 200)
        }
        
        btManager.setColor(r: r, g: g, b: b)
        
        // Efecto según danceability
        let effectCode: UInt8 = danceability > 0.5 ? 0x87 : 0x89
        btManager.setEffect(effectCode)
        
        // Velocidad según energía
        let speed = UInt8(energyLevel * 100)
        btManager.setEffectSpeed(speed)
    }
    
    private func buildAuthURL(scopes: [String]) -> URL? {
        let baseURL = "https://accounts.spotify.com/authorize"
        let scopeString = scopes.joined(separator: "%20")
        let urlString = "\(baseURL)?client_id=\(clientID)&response_type=code&redirect_uri=\(redirectURI)&scope=\(scopeString)"
        
        return URL(string: urlString)
    }
    
    private func encodeFormData(_ data: [String: String]) -> Data? {
        let components = data.map { "\($0.key)=\($0.value.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "")" }
        return components.joined(separator: "&").data(using: .utf8)
    }
}

// MARK: - Response Models
struct TokenResponse: Decodable {
    let access_token: String
    let token_type: String
    let expires_in: Int
    let refresh_token: String?
}

struct CurrentPlaybackResponse: Decodable {
    let is_playing: Bool
    let item: Track?
}

struct Track: Decodable {
    let id: String
    let name: String
    let artists: [Artist]
    let album: Album
}

struct Artist: Decodable {
    let name: String
}

struct Album: Decodable {
    let name: String
    let images: [Image]
}

struct Image: Decodable {
    let url: String
    let height: Int?
    let width: Int?
}

struct AudioFeaturesResponse: Decodable {
    let tempo: Double
    let energy: Double
    let danceability: Double
    let valence: Double
    let key: Int
    let mode: Int
}

// MARK: - Enhanced Spotify View
struct EnhancedSpotifyView: View {
    @ObservedObject var spotifyManager: AdvancedSpotifyManager
    let btManager: BluetoothManager
    @State private var isSyncing = false
    @State private var syncTimer: Timer?
    
    var body: some View {
        VStack(spacing: 20) {
            // Album Art + Info
            VStack(spacing: 12) {
                if let artURL = spotifyManager.albumArtURL {
                    AsyncImage(url: artURL) { image in
                        image
                            .resizable()
                            .scaledToFill()
                            .frame(height: 200)
                            .cornerRadius(12)
                            .clipped()
                    } placeholder: {
                        Image(systemName: "music.note")
                            .frame(height: 200)
                            .foregroundColor(.white.opacity(0.3))
                    }
                }
                
                VStack(spacing: 6) {
                    Text(spotifyManager.currentTrack)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.white)
                        .lineLimit(2)
                    
                    Text(spotifyManager.currentArtist)
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.7))
                    
                    HStack(spacing: 12) {
                        Image(systemName: "metronome")
                            .foregroundColor(.cyan)
                        Text("\(spotifyManager.currentBPM) BPM")
                            .font(.caption)
                            .foregroundColor(.white)
                        
                        Spacer()
                        
                        Image(systemName: "bolt.fill")
                            .foregroundColor(.orange)
                        Text("\(Int(spotifyManager.energyLevel * 100))% Energy")
                            .font(.caption)
                            .foregroundColor(.white)
                    }
                }
                .padding(.horizontal, 12)
            }
            .padding(12)
            .background(Color.white.opacity(0.05))
            .cornerRadius(12)
            .padding(.horizontal, 20)
            
            // Sync Mode Selector
            VStack(spacing: 10) {
                Text("Modo de Sincronización")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.white)
                    .padding(.horizontal, 20)
                
                VStack(spacing: 8) {
                    SyncModeButton(
                        title: "Color Album",
                        icon: "paintpalette.fill",
                        isSelected: spotifyManager.syncMode == .color
                    ) {
                        spotifyManager.syncMode = .color
                    }
                    
                    SyncModeButton(
                        title: "Energía",
                        icon: "bolt.fill",
                        isSelected: spotifyManager.syncMode == .energy
                    ) {
                        spotifyManager.syncMode = .energy
                    }
                    
                    SyncModeButton(
                        title: "Beat Sync",
                        icon: "metronome",
                        isSelected: spotifyManager.syncMode == .beat
                    ) {
                        spotifyManager.syncMode = .beat
                    }
                    
                    SyncModeButton(
                        title: "Mood",
                        icon: "smiley.fill",
                        isSelected: spotifyManager.syncMode == .mood
                    ) {
                        spotifyManager.syncMode = .mood
                    }
                }
                .padding(.horizontal, 20)
            }
            
            // Stats
            VStack(spacing: 10) {
                StatsRow(label: "Danceability", value: "\(Int(spotifyManager.danceability * 100))%", color: .green)
                StatsRow(label: "Mood (Valence)", value: "\(Int(spotifyManager.valence * 100))%", color: .yellow)
                StatsRow(label: "Energy", value: "\(Int(spotifyManager.energyLevel * 100))%", color: .orange)
            }
            .padding(.horizontal, 20)
            
            // Control Buttons
            VStack(spacing: 10) {
                Button(action: {
                    spotifyManager.connectToSpotify()
                }) {
                    HStack {
                        Image(systemName: spotifyManager.isConnected ? "checkmark.circle.fill" : "key.fill")
                        Text(spotifyManager.isConnected ? "Conectado a Spotify" : "Conectar Spotify")
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 50)
                    .background(spotifyManager.isConnected ? Color.green : Color.cyan)
                    .foregroundColor(.black)
                    .cornerRadius(12)
                    .font(.system(size: 16, weight: .semibold))
                }
                
                Button(action: {
                    isSyncing.toggle()
                    
                    if isSyncing {
                        syncTimer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { _ in
                            spotifyManager.generateSyncCommand(for: btManager)
                        }
                    } else {
                        syncTimer?.invalidate()
                    }
                }) {
                    HStack {
                        Image(systemName: isSyncing ? "pause.circle.fill" : "play.circle.fill")
                        Text(isSyncing ? "Pausar Sincronización" : "Iniciar Sincronización")
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 50)
                    .background(isSyncing ? Color.red : Color.cyan)
                    .foregroundColor(.black)
                    .cornerRadius(12)
                    .font(.system(size: 16, weight: .semibold))
                }
            }
            .padding(.horizontal, 20)
            
            Spacer()
        }
        .padding(.vertical, 20)
    }
}

struct SyncModeButton: View {
    let title: String
    let icon: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.system(size: 16))
                Text(title)
                    .font(.system(size: 14, weight: .semibold))
                Spacer()
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 16))
                }
            }
            .foregroundColor(.white)
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(isSelected ? Color.cyan.opacity(0.3) : Color.white.opacity(0.05))
            .cornerRadius(8)
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(isSelected ? Color.cyan : Color.clear, lineWidth: 1)
            )
        }
    }
}

struct StatsRow: View {
    let label: String
    let value: String
    let color: Color
    
    var body: some View {
        HStack {
            Text(label)
                .font(.caption)
                .foregroundColor(.white.opacity(0.6))
            Spacer()
            HStack(spacing: 4) {
                Circle()
                    .fill(color)
                    .frame(width: 8, height: 8)
                Text(value)
                    .font(.caption)
                    .foregroundColor(.white)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(Color.white.opacity(0.02))
        .cornerRadius(6)
    }
}

#Preview {
    EnhancedSpotifyView(
        spotifyManager: AdvancedSpotifyManager(),
        btManager: BluetoothManager()
    )
}
