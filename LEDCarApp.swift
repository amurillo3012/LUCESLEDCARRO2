import SwiftUI
import CoreBluetooth
import MediaPlayer

// MARK: - Models
struct LEDDevice: Identifiable, Hashable {
    let id: UUID
    let name: String
    let peripheral: CBPeripheral
    var isConnected: Bool = false
    var signalStrength: Int = 0
    var isMaster: Bool = false
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}

struct ColorPreset: Identifiable, Codable {
    let id: UUID
    let name: String
    let r: UInt8
    let g: UInt8
    let b: UInt8
    let brightness: UInt8
    
    init(id: UUID = UUID(), name: String, r: UInt8, g: UInt8, b: UInt8, brightness: UInt8 = 100) {
        self.id = id
        self.name = name
        self.r = r
        self.g = g
        self.b = b
        self.brightness = brightness
    }
}

struct EffectPreset: Identifiable, Codable {
    let id: UUID
    let name: String
    let effectCode: UInt8
    let speed: UInt8
    
    init(id: UUID = UUID(), name: String, effectCode: UInt8, speed: UInt8 = 50) {
        self.id = id
        self.name = name
        self.effectCode = effectCode
        self.speed = speed
    }
}

// MARK: - Bluetooth Manager
class BluetoothManager: NSObject, ObservableObject {
    @Published var devices: [LEDDevice] = []
    @Published var connectedDevice: LEDDevice?
    @Published var isScanning = false
    @Published var statusMessage = ""
    
    private var centralManager: CBCentralManager!
    private var discoveredPeripherals: [UUID: CBPeripheral] = [:]
    private var writeCharacteristic: CBCharacteristic?
    
    // BLE UUIDs para LED CAR 01
    private let serviceUUID = CBUUID(string: "0000FFE0-0000-1000-8000-00805F9B34FB")
    private let writeCharacteristicUUID = CBUUID(string: "0000FFE1-0000-1000-8000-00805F9B34FB")
    
    override init() {
        super.init()
        centralManager = CBCentralManager(delegate: self, queue: .main)
    }
    
    func startScanning() {
        guard centralManager.state == .poweredOn else {
            statusMessage = "Bluetooth no disponible"
            return
        }
        isScanning = true
        centralManager.scanForPeripherals(withServices: [serviceUUID], options: nil)
        statusMessage = "Buscando dispositivos..."
    }
    
    func stopScanning() {
        centralManager.stopScan()
        isScanning = false
    }
    
    func connect(to device: LEDDevice) {
        centralManager.connect(device.peripheral, options: nil)
        statusMessage = "Conectando a \(device.name)..."
    }
    
    func disconnect() {
        if let device = connectedDevice {
            centralManager.cancelPeripheralConnection(device.peripheral)
        }
    }
    
    // MARK: - LED Commands
    func sendCommand(_ bytes: [UInt8]) {
        guard let device = connectedDevice,
              let characteristic = writeCharacteristic else {
            statusMessage = "No hay dispositivo conectado"
            return
        }
        
        let data = Data(bytes)
        device.peripheral.writeValue(data, for: characteristic, type: .withoutResponse)
    }
    
    func setColor(r: UInt8, g: UInt8, b: UInt8) {
        // Comando: 7e 00 05 03 R G B 00 ef
        let command: [UInt8] = [0x7e, 0x00, 0x05, 0x03, r, g, b, 0x00, 0xef]
        sendCommand(command)
    }
    
    func setBrightness(_ brightness: UInt8) {
        // Comando: 7e 00 01 brightness 00 00 00 00 ef
        let brightValue = min(brightness, 100)
        let command: [UInt8] = [0x7e, 0x00, 0x01, brightValue, 0x00, 0x00, 0x00, 0x00, 0xef]
        sendCommand(command)
    }
    
    func setEffectSpeed(_ speed: UInt8) {
        // Comando: 7e 00 02 speed 00 00 00 00 ef
        let speedValue = min(speed, 100)
        let command: [UInt8] = [0x7e, 0x00, 0x02, speedValue, 0x00, 0x00, 0x00, 0x00, 0xef]
        sendCommand(command)
    }
    
    func setEffect(_ effectCode: UInt8) {
        // Comando: 7e 00 03 effect 03 00 00 00 ef
        let command: [UInt8] = [0x7e, 0x00, 0x03, effectCode, 0x03, 0x00, 0x00, 0x00, 0xef]
        sendCommand(command)
    }
    
    func setPower(on: Bool) {
        // Comando: 7e 00 04 is_on 00 00 00 00 ef
        let value: UInt8 = on ? 0x01 : 0x00
        let command: [UInt8] = [0x7e, 0x00, 0x04, value, 0x00, 0x00, 0x00, 0x00, 0xef]
        sendCommand(command)
    }
}

// MARK: - CBCentralManagerDelegate
extension BluetoothManager: CBCentralManagerDelegate {
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        switch central.state {
        case .poweredOn:
            statusMessage = "Bluetooth activado"
        case .poweredOff:
            statusMessage = "Bluetooth desactivado"
        case .unauthorized:
            statusMessage = "Acceso Bluetooth denegado"
        case .unavailable:
            statusMessage = "Bluetooth no disponible"
        case .resetting:
            statusMessage = "Bluetooth reseteando..."
        @unknown default:
            statusMessage = "Estado desconocido"
        }
    }
    
    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {
        let name = peripheral.name ?? "Desconocido"
        
        if !devices.contains(where: { $0.peripheral.identifier == peripheral.identifier }) {
            let device = LEDDevice(
                id: peripheral.identifier,
                name: name,
                peripheral: peripheral,
                isMaster: name.contains("01")
            )
            devices.append(device)
            discoveredPeripherals[peripheral.identifier] = peripheral
        }
    }
    
    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        peripheral.delegate = self
        peripheral.discoverServices([serviceUUID])
        
        if let index = devices.firstIndex(where: { $0.peripheral.identifier == peripheral.identifier }) {
            devices[index].isConnected = true
            connectedDevice = devices[index]
        }
        statusMessage = "Conectado"
    }
    
    func centralManager(_ central: CBCentralManager, didFailToConnect peripheral: CBPeripheral, error: Error?) {
        statusMessage = "Error de conexión"
    }
    
    func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
        if let index = devices.firstIndex(where: { $0.peripheral.identifier == peripheral.identifier }) {
            devices[index].isConnected = false
        }
        connectedDevice = nil
        statusMessage = "Desconectado"
    }
}

// MARK: - CBPeripheralDelegate
extension BluetoothManager: CBPeripheralDelegate {
    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        guard let services = peripheral.services else { return }
        
        for service in services {
            peripheral.discoverCharacteristics([writeCharacteristicUUID], for: service)
        }
    }
    
    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        guard let characteristics = service.characteristics else { return }
        
        for characteristic in characteristics {
            if characteristic.uuid == writeCharacteristicUUID {
                writeCharacteristic = characteristic
                statusMessage = "Listo para enviar comandos"
            }
        }
    }
}

// MARK: - Spotify Manager
class SpotifyManager: NSObject, ObservableObject {
    @Published var isConnected = false
    @Published var currentTrack = ""
    @Published var isPlaying = false
    
    func connectToSpotify() {
        // Aquí iría la integración con Spotify API
        // Por ahora, usamos MPMediaPlayer como fallback
        let query = MPMediaQuery.songs()
        if let songs = query.items {
            isConnected = true
        }
    }
    
    func syncWithMusic(btManager: BluetoothManager) {
        // Sincronizar colores con el beat de la música
        guard isPlaying else { return }
        
        // Ejemplo: cambiar intensidad con el beat
        let colors: [(r: UInt8, g: UInt8, b: UInt8)] = [
            (255, 0, 0),     // Rojo
            (0, 255, 0),     // Verde
            (0, 0, 255),     // Azul
            (255, 255, 0),   // Amarillo
            (255, 0, 255),   // Magenta
            (0, 255, 255)    // Cian
        ]
        
        // Rotar colores en sincronización
        if let color = colors.randomElement() {
            btManager.setColor(r: color.r, g: color.g, b: color.b)
        }
    }
}

// MARK: - Main App View
struct ContentView: View {
    @StateObject private var btManager = BluetoothManager()
    @StateObject private var spotifyManager = SpotifyManager()
    @State private var selectedTab = 0
    @State private var selectedColor = Color.red
    @State private var brightness: Double = 100
    @State private var effectSpeed: Double = 50
    @State private var showColorPicker = false
    @State private var colorPresets: [ColorPreset] = ColorPreset.defaultPresets()
    @State private var effectPresets: [EffectPreset] = EffectPreset.defaultPresets()
    
    var body: some View {
        ZStack {
            // Gradiente de fondo
            LinearGradient(
                gradient: Gradient(colors: [Color(#colorLiteral(red: 0.1, green: 0.1, blue: 0.15, alpha: 1)), Color(#colorLiteral(red: 0.15, green: 0.1, blue: 0.2, alpha: 1))]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Header
                VStack(spacing: 10) {
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("LED CAR 01")
                                .font(.system(size: 24, weight: .bold))
                                .foregroundColor(.white)
                            
                            HStack(spacing: 6) {
                                Circle()
                                    .fill(btManager.connectedDevice != nil ? Color.green : Color.gray)
                                    .frame(width: 8, height: 8)
                                
                                Text(btManager.connectedDevice?.name ?? "No conectado")
                                    .font(.caption)
                                    .foregroundColor(.white.opacity(0.7))
                            }
                        }
                        Spacer()
                    }
                    .padding(.horizontal, 20)
                    
                    // Status bar
                    Text(btManager.statusMessage)
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.6))
                }
                .padding(.vertical, 16)
                .background(Color.black.opacity(0.3))
                
                TabView(selection: $selectedTab) {
                    // Tab 1: Control de Colores
                    ColorControlView(
                        btManager: btManager,
                        selectedColor: $selectedColor,
                        brightness: $brightness,
                        colorPresets: $colorPresets
                    )
                    .tag(0)
                    
                    // Tab 2: Efectos
                    EffectsView(
                        btManager: btManager,
                        effectSpeed: $effectSpeed,
                        effectPresets: $effectPresets
                    )
                    .tag(1)
                    
                    // Tab 3: Dispositivos
                    DevicesView(
                        btManager: btManager,
                        devices: $btManager.devices
                    )
                    .tag(2)
                    
                    // Tab 4: Spotify
                    SpotifyView(
                        spotifyManager: spotifyManager,
                        btManager: btManager
                    )
                    .tag(3)
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                
                // Tab indicators
                HStack(spacing: 12) {
                    ForEach(0..<4, id: \.self) { index in
                        Capsule()
                            .fill(index == selectedTab ? Color.cyan : Color.white.opacity(0.3))
                            .frame(height: 4)
                            .onTapGesture { selectedTab = index }
                    }
                }
                .padding(.vertical, 16)
                .padding(.horizontal, 20)
            }
        }
    }
}

// MARK: - Color Control View
struct ColorControlView: View {
    let btManager: BluetoothManager
    @Binding var selectedColor: Color
    @Binding var brightness: Double
    @Binding var colorPresets: [ColorPreset]
    @State private var showColorPicker = false
    
    var body: some View {
        VStack(spacing: 20) {
            // Rueda de colores
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            gradient: Gradient(colors: [
                                selectedColor.opacity(0.2),
                                selectedColor.opacity(0.5)
                            ]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(height: 280)
                
                Circle()
                    .stroke(Color.white.opacity(0.3), lineWidth: 2)
                    .frame(height: 280)
                
                VStack(spacing: 10) {
                    Image(systemName: "paintpalette.fill")
                        .font(.system(size: 40))
                        .foregroundColor(selectedColor)
                    
                    Text("Seleccionar color")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.7))
                }
                .onTapGesture { showColorPicker = true }
            }
            .padding(.horizontal, 30)
            
            // Brillo
            VStack(spacing: 10) {
                HStack {
                    Text("Brillo")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.white)
                    Spacer()
                    Text("\(Int(brightness))%")
                        .font(.caption)
                        .foregroundColor(.cyan)
                }
                
                Slider(value: $brightness, in: 0...100)
                    .onChange(of: brightness) { newValue in
                        btManager.setBrightness(UInt8(newValue))
                    }
                    .tint(.cyan)
            }
            .padding(.horizontal, 20)
            
            // Presets
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    ForEach(colorPresets) { preset in
                        VStack {
                            Rectangle()
                                .fill(Color(red: Double(preset.r)/255, green: Double(preset.g)/255, blue: Double(preset.b)/255))
                                .frame(height: 40)
                                .cornerRadius(8)
                            
                            Text(preset.name)
                                .font(.caption2)
                                .foregroundColor(.white)
                        }
                        .frame(width: 70)
                        .onTapGesture {
                            btManager.setColor(r: preset.r, g: preset.g, b: preset.b)
                            btManager.setBrightness(preset.brightness)
                        }
                    }
                }
                .padding(.horizontal, 20)
            }
            
            Spacer()
        }
        .padding(.vertical, 20)
        .sheet(isPresented: $showColorPicker) {
            ColorPickerSheet(
                selectedColor: $selectedColor,
                btManager: btManager
            )
        }
    }
}

// MARK: - Color Picker Sheet
struct ColorPickerSheet: View {
    @Binding var selectedColor: Color
    let btManager: BluetoothManager
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        VStack(spacing: 20) {
            Text("Seleccionar Color")
                .font(.title2.bold())
                .foregroundColor(.white)
            
            ColorPicker("", selection: $selectedColor)
                .frame(height: 300)
                .padding()
            
            Button(action: {
                let comps = UIColor(selectedColor).cgColor.components ?? [1, 0, 0, 1]
                let r = UInt8(comps[0] * 255)
                let g = UInt8(comps[1] * 255)
                let b = UInt8(comps[2] * 255)
                
                btManager.setColor(r: r, g: g, b: b)
                dismiss()
            }) {
                Text("Aplicar")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.black)
                    .frame(maxWidth: .infinity)
                    .frame(height: 50)
                    .background(Color.cyan)
                    .cornerRadius(12)
            }
            .padding(.horizontal, 20)
            
            Spacer()
        }
        .padding()
        .background(Color(#colorLiteral(red: 0.1, green: 0.1, blue: 0.15, alpha: 1)))
    }
}

// MARK: - Effects View
struct EffectsView: View {
    let btManager: BluetoothManager
    @Binding var effectSpeed: Double
    @Binding var effectPresets: [EffectPreset]
    
    let effectGrid = [
        EffectPreset(name: "Rojo", effectCode: 0x80, speed: 0),
        EffectPreset(name: "Verde", effectCode: 0x81, speed: 0),
        EffectPreset(name: "Azul", effectCode: 0x82, speed: 0),
        EffectPreset(name: "Amarillo", effectCode: 0x83, speed: 0),
        EffectPreset(name: "Cian", effectCode: 0x84, speed: 0),
        EffectPreset(name: "Magenta", effectCode: 0x85, speed: 0),
        EffectPreset(name: "Blanco", effectCode: 0x86, speed: 0),
        EffectPreset(name: "Jump RGB", effectCode: 0x87, speed: 50),
        EffectPreset(name: "Gradient", effectCode: 0x89, speed: 50),
        EffectPreset(name: "Blink", effectCode: 0x95, speed: 50),
    ]
    
    var body: some View {
        VStack(spacing: 20) {
            VStack(spacing: 10) {
                HStack {
                    Text("Velocidad del efecto")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.white)
                    Spacer()
                    Text("\(Int(effectSpeed))")
                        .font(.caption)
                        .foregroundColor(.cyan)
                }
                
                Slider(value: $effectSpeed, in: 0...100)
                    .onChange(of: effectSpeed) { newValue in
                        btManager.setEffectSpeed(UInt8(newValue))
                    }
                    .tint(.cyan)
            }
            .padding(.horizontal, 20)
            
            Text("Efectos disponibles")
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(.white)
                .padding(.horizontal, 20)
            
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                ForEach(effectGrid) { effect in
                    Button(action: {
                        btManager.setEffect(effect.effectCode)
                        if effect.speed > 0 {
                            btManager.setEffectSpeed(effect.speed)
                        }
                    }) {
                        VStack(spacing: 8) {
                            Image(systemName: "sparkles")
                                .font(.system(size: 20))
                            Text(effect.name)
                                .font(.caption)
                                .lineLimit(1)
                        }
                        .frame(maxWidth: .infinity)
                        .frame(height: 80)
                        .background(Color.white.opacity(0.1))
                        .foregroundColor(.cyan)
                        .cornerRadius(12)
                    }
                }
            }
            .padding(.horizontal, 20)
            
            Spacer()
        }
        .padding(.vertical, 20)
    }
}

// MARK: - Devices View
struct DevicesView: View {
    let btManager: BluetoothManager
    @Binding var devices: [LEDDevice]
    
    var body: some View {
        VStack(spacing: 16) {
            if btManager.isScanning {
                ProgressView()
                    .foregroundColor(.cyan)
                Text("Buscando dispositivos...")
                    .foregroundColor(.white)
            }
            
            if devices.isEmpty && !btManager.isScanning {
                VStack(spacing: 12) {
                    Image(systemName: "wifi.slash")
                        .font(.system(size: 40))
                        .foregroundColor(.white.opacity(0.5))
                    Text("No se encontraron dispositivos")
                        .foregroundColor(.white.opacity(0.7))
                }
                .frame(maxHeight: .infinity)
            } else {
                ScrollView {
                    VStack(spacing: 12) {
                        ForEach(devices) { device in
                            DeviceRow(device: device, btManager: btManager)
                        }
                    }
                    .padding(.horizontal, 20)
                }
            }
            
            Button(action: {
                if btManager.isScanning {
                    btManager.stopScanning()
                } else {
                    btManager.startScanning()
                }
            }) {
                HStack {
                    Image(systemName: btManager.isScanning ? "stop.circle.fill" : "magnifyingglass")
                    Text(btManager.isScanning ? "Detener" : "Buscar")
                }
                .frame(maxWidth: .infinity)
                .frame(height: 50)
                .background(Color.cyan)
                .foregroundColor(.black)
                .cornerRadius(12)
                .font(.system(size: 16, weight: .semibold))
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 20)
        }
        .padding(.vertical, 20)
    }
}

// MARK: - Device Row
struct DeviceRow: View {
    let device: LEDDevice
    let btManager: BluetoothManager
    
    var body: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 6) {
                    Text(device.name)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.white)
                    
                    if device.isMaster {
                        Text("MAESTRO")
                            .font(.caption2)
                            .foregroundColor(.orange)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 2)
                            .background(Color.orange.opacity(0.2))
                            .cornerRadius(4)
                    }
                }
                
                Text(device.id.uuidString.prefix(8))
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.5))
            }
            
            Spacer()
            
            Button(action: {
                if device.isConnected {
                    btManager.disconnect()
                } else {
                    btManager.connect(to: device)
                }
            }) {
                Circle()
                    .fill(device.isConnected ? Color.green : Color.gray)
                    .frame(width: 12, height: 12)
                    .padding(8)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(Color.white.opacity(0.05))
        .cornerRadius(12)
    }
}

// MARK: - Spotify View
struct SpotifyView: View {
    let spotifyManager: SpotifyManager
    let btManager: BluetoothManager
    @State private var isSyncing = false
    
    var body: some View {
        VStack(spacing: 20) {
            VStack(spacing: 12) {
                Image(systemName: "music.note")
                    .font(.system(size: 40))
                    .foregroundColor(.green)
                
                Text("Sincronización Spotify")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.white)
                
                Text("Sincroniza los colores con el beat de tu música")
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.6))
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 20)
            .background(Color.green.opacity(0.1))
            .cornerRadius(12)
            .padding(.horizontal, 20)
            
            VStack(spacing: 10) {
                Button(action: {
                    spotifyManager.connectToSpotify()
                }) {
                    HStack {
                        Image(systemName: "key.fill")
                        Text("Conectar con Spotify")
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 50)
                    .background(Color.green)
                    .foregroundColor(.white)
                    .cornerRadius(12)
                    .font(.system(size: 16, weight: .semibold))
                }
                
                Button(action: {
                    isSyncing.toggle()
                    if isSyncing {
                        Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { _ in
                            if isSyncing {
                                spotifyManager.syncWithMusic(btManager: btManager)
                            }
                        }
                    }
                }) {
                    HStack {
                        Image(systemName: isSyncing ? "pause.circle.fill" : "play.circle.fill")
                        Text(isSyncing ? "Detener sincronización" : "Iniciar sincronización")
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
            
            VStack(spacing: 12) {
                HStack {
                    Text("Estado")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.6))
                    Spacer()
                    HStack(spacing: 6) {
                        Circle()
                            .fill(spotifyManager.isConnected ? Color.green : Color.gray)
                            .frame(width: 8, height: 8)
                        Text(spotifyManager.isConnected ? "Conectado" : "Desconectado")
                            .font(.caption)
                            .foregroundColor(.white)
                    }
                }
                
                Divider()
                    .background(Color.white.opacity(0.2))
                
                HStack {
                    Text("Canción")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.6))
                    Spacer()
                    Text(spotifyManager.currentTrack.isEmpty ? "---" : spotifyManager.currentTrack)
                        .font(.caption)
                        .foregroundColor(.white)
                        .lineLimit(1)
                }
            }
            .padding(12)
            .background(Color.white.opacity(0.05))
            .cornerRadius(8)
            .padding(.horizontal, 20)
            
            Spacer()
        }
        .padding(.vertical, 20)
    }
}

// MARK: - Default Presets
extension ColorPreset {
    static func defaultPresets() -> [ColorPreset] {
        [
            ColorPreset(name: "Rojo", r: 255, g: 0, b: 0),
            ColorPreset(name: "Verde", r: 0, g: 255, b: 0),
            ColorPreset(name: "Azul", r: 0, g: 0, b: 255),
            ColorPreset(name: "Amarillo", r: 255, g: 255, b: 0),
            ColorPreset(name: "Magenta", r: 255, g: 0, b: 255),
            ColorPreset(name: "Cian", r: 0, g: 255, b: 255),
        ]
    }
}

extension EffectPreset {
    static func defaultPresets() -> [EffectPreset] {
        [
            EffectPreset(name: "Rojo", effectCode: 0x80),
            EffectPreset(name: "Verde", effectCode: 0x81),
            EffectPreset(name: "Azul", effectCode: 0x82),
        ]
    }
}

#Preview {
    ContentView()
}
