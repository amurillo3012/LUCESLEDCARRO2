// MARK: - Complete LED CAR 01 Effects Catalog
// Este archivo contiene TODOS los efectos disponibles en la ROM de la caja

import Foundation

struct LEDEffect: Identifiable, Hashable {
    let id: UInt8
    let name: String
    let category: EffectCategory
    let requiresSpeed: Bool
    let description: String
    let defaultSpeed: UInt8
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}

enum EffectCategory: String, CaseIterable {
    case solid = "Colores Sólidos"
    case dynamic = "Dinámicos"
    case breathing = "Respiración"
    case blinking = "Parpadeo"
    case special = "Especiales"
}

// MARK: - Efect Database
class LEDEffectDatabase {
    static let shared = LEDEffectDatabase()
    
    var allEffects: [LEDEffect] = []
    
    init() {
        loadEffects()
    }
    
    private func loadEffects() {
        // SOLID COLORS (0x80-0x86)
        allEffects += [
            LEDEffect(
                id: 0x80,
                name: "Rojo Sólido",
                category: .solid,
                requiresSpeed: false,
                description: "Color rojo puro sin efectos",
                defaultSpeed: 0
            ),
            LEDEffect(
                id: 0x81,
                name: "Verde Sólido",
                category: .solid,
                requiresSpeed: false,
                description: "Color verde puro sin efectos",
                defaultSpeed: 0
            ),
            LEDEffect(
                id: 0x82,
                name: "Azul Sólido",
                category: .solid,
                requiresSpeed: false,
                description: "Color azul puro sin efectos",
                defaultSpeed: 0
            ),
            LEDEffect(
                id: 0x83,
                name: "Amarillo Sólido",
                category: .solid,
                requiresSpeed: false,
                description: "Color amarillo puro sin efectos",
                defaultSpeed: 0
            ),
            LEDEffect(
                id: 0x84,
                name: "Cian Sólido",
                category: .solid,
                requiresSpeed: false,
                description: "Color cian (azul-verde) sin efectos",
                defaultSpeed: 0
            ),
            LEDEffect(
                id: 0x85,
                name: "Magenta Sólido",
                category: .solid,
                requiresSpeed: false,
                description: "Color magenta puro sin efectos",
                defaultSpeed: 0
            ),
            LEDEffect(
                id: 0x86,
                name: "Blanco Sólido",
                category: .solid,
                requiresSpeed: false,
                description: "Color blanco puro sin efectos",
                defaultSpeed: 0
            ),
        ]
        
        // DYNAMIC EFFECTS - Jump (0x87-0x88)
        allEffects += [
            LEDEffect(
                id: 0x87,
                name: "Salto RGB",
                category: .dynamic,
                requiresSpeed: true,
                description: "Cambia abruptamente entre Rojo, Verde y Azul",
                defaultSpeed: 50
            ),
            LEDEffect(
                id: 0x88,
                name: "Salto Arcoíris",
                category: .dynamic,
                requiresSpeed: true,
                description: "Salta entre los 7 colores principales",
                defaultSpeed: 50
            ),
        ]
        
        // GRADIENT EFFECTS (0x89-0x94)
        allEffects += [
            LEDEffect(
                id: 0x89,
                name: "Gradiente RGB",
                category: .dynamic,
                requiresSpeed: true,
                description: "Transición suave entre Rojo, Verde y Azul",
                defaultSpeed: 50
            ),
            LEDEffect(
                id: 0x8A,
                name: "Gradiente Arcoíris",
                category: .dynamic,
                requiresSpeed: true,
                description: "Transición suave entre 7 colores",
                defaultSpeed: 50
            ),
            LEDEffect(
                id: 0x8B,
                name: "Gradiente Rojo",
                category: .dynamic,
                requiresSpeed: true,
                description: "Gradiente solo en tonos rojos",
                defaultSpeed: 50
            ),
            LEDEffect(
                id: 0x8C,
                name: "Gradiente Verde",
                category: .dynamic,
                requiresSpeed: true,
                description: "Gradiente solo en tonos verdes",
                defaultSpeed: 50
            ),
            LEDEffect(
                id: 0x8D,
                name: "Gradiente Azul",
                category: .dynamic,
                requiresSpeed: true,
                description: "Gradiente solo en tonos azules",
                defaultSpeed: 50
            ),
            LEDEffect(
                id: 0x8E,
                name: "Gradiente Amarillo",
                category: .dynamic,
                requiresSpeed: true,
                description: "Gradiente solo en tonos amarillos",
                defaultSpeed: 50
            ),
            LEDEffect(
                id: 0x8F,
                name: "Gradiente Cian",
                category: .dynamic,
                requiresSpeed: true,
                description: "Gradiente solo en tonos cian",
                defaultSpeed: 50
            ),
            LEDEffect(
                id: 0x90,
                name: "Gradiente Magenta",
                category: .dynamic,
                requiresSpeed: true,
                description: "Gradiente solo en tonos magenta",
                defaultSpeed: 50
            ),
            LEDEffect(
                id: 0x91,
                name: "Gradiente Blanco",
                category: .dynamic,
                requiresSpeed: true,
                description: "Gradiente solo en tonos blancos",
                defaultSpeed: 50
            ),
            LEDEffect(
                id: 0x92,
                name: "Gradiente Rojo-Verde",
                category: .dynamic,
                requiresSpeed: true,
                description: "Transición gradual de rojo a verde",
                defaultSpeed: 50
            ),
            LEDEffect(
                id: 0x93,
                name: "Gradiente Rojo-Azul",
                category: .dynamic,
                requiresSpeed: true,
                description: "Transición gradual de rojo a azul",
                defaultSpeed: 50
            ),
            LEDEffect(
                id: 0x94,
                name: "Gradiente Verde-Azul",
                category: .dynamic,
                requiresSpeed: true,
                description: "Transición gradual de verde a azul",
                defaultSpeed: 50
            ),
        ]
        
        // BLINK EFFECTS (0x95-0x9C)
        allEffects += [
            LEDEffect(
                id: 0x95,
                name: "Parpadeo Arcoíris",
                category: .blinking,
                requiresSpeed: true,
                description: "Parpadea cíclicamente entre los 7 colores",
                defaultSpeed: 50
            ),
            LEDEffect(
                id: 0x96,
                name: "Parpadeo Rojo",
                category: .blinking,
                requiresSpeed: true,
                description: "Parpadea en rojo",
                defaultSpeed: 50
            ),
            LEDEffect(
                id: 0x97,
                name: "Parpadeo Verde",
                category: .blinking,
                requiresSpeed: true,
                description: "Parpadea en verde",
                defaultSpeed: 50
            ),
            LEDEffect(
                id: 0x98,
                name: "Parpadeo Azul",
                category: .blinking,
                requiresSpeed: true,
                description: "Parpadea en azul",
                defaultSpeed: 50
            ),
            LEDEffect(
                id: 0x99,
                name: "Parpadeo Amarillo",
                category: .blinking,
                requiresSpeed: true,
                description: "Parpadea en amarillo",
                defaultSpeed: 50
            ),
            LEDEffect(
                id: 0x9A,
                name: "Parpadeo Cian",
                category: .blinking,
                requiresSpeed: true,
                description: "Parpadea en cian",
                defaultSpeed: 50
            ),
            LEDEffect(
                id: 0x9B,
                name: "Parpadeo Magenta",
                category: .blinking,
                requiresSpeed: true,
                description: "Parpadea en magenta",
                defaultSpeed: 50
            ),
            LEDEffect(
                id: 0x9C,
                name: "Parpadeo Blanco",
                category: .blinking,
                requiresSpeed: true,
                description: "Parpadea en blanco",
                defaultSpeed: 50
            ),
        ]
        
        // PULSE EFFECTS (0x9D-0x9F)
        allEffects += [
            LEDEffect(
                id: 0x9D,
                name: "Pulso Rojo",
                category: .breathing,
                requiresSpeed: true,
                description: "Efecto pulsante suave en rojo",
                defaultSpeed: 30
            ),
            LEDEffect(
                id: 0x9E,
                name: "Pulso Verde",
                category: .breathing,
                requiresSpeed: true,
                description: "Efecto pulsante suave en verde",
                defaultSpeed: 30
            ),
            LEDEffect(
                id: 0x9F,
                name: "Pulso Azul",
                category: .breathing,
                requiresSpeed: true,
                description: "Efecto pulsante suave en azul",
                defaultSpeed: 30
            ),
        ]
        
        // BREATHING EFFECTS (0xA0-0xA5)
        allEffects += [
            LEDEffect(
                id: 0xA0,
                name: "Respiración Rojo",
                category: .breathing,
                requiresSpeed: true,
                description: "Respiración suave de rojo (encendido/apagado)",
                defaultSpeed: 30
            ),
            LEDEffect(
                id: 0xA1,
                name: "Respiración Verde",
                category: .breathing,
                requiresSpeed: true,
                description: "Respiración suave de verde",
                defaultSpeed: 30
            ),
            LEDEffect(
                id: 0xA2,
                name: "Respiración Azul",
                category: .breathing,
                requiresSpeed: true,
                description: "Respiración suave de azul",
                defaultSpeed: 30
            ),
            LEDEffect(
                id: 0xA3,
                name: "Respiración Magenta",
                category: .breathing,
                requiresSpeed: true,
                description: "Respiración suave de magenta",
                defaultSpeed: 30
            ),
            LEDEffect(
                id: 0xA4,
                name: "Respiración Cian",
                category: .breathing,
                requiresSpeed: true,
                description: "Respiración suave de cian",
                defaultSpeed: 30
            ),
            LEDEffect(
                id: 0xA5,
                name: "Respiración Arcoíris",
                category: .breathing,
                requiresSpeed: true,
                description: "Respiración suave cíclica entre colores",
                defaultSpeed: 30
            ),
        ]
        
        // ADVANCED EFFECTS (0xA6-0xB3)
        allEffects += [
            LEDEffect(
                id: 0xA6,
                name: "Onda RGB",
                category: .dynamic,
                requiresSpeed: true,
                description: "Efecto de onda suave entre colores",
                defaultSpeed: 50
            ),
            LEDEffect(
                id: 0xA7,
                name: "Persecución RGB",
                category: .dynamic,
                requiresSpeed: true,
                description: "Efecto de persecución animada entre colores",
                defaultSpeed: 50
            ),
            LEDEffect(
                id: 0xA8,
                name: "Persecución Arcoíris",
                category: .dynamic,
                requiresSpeed: true,
                description: "Persecución animada entre 7 colores",
                defaultSpeed: 50
            ),
            LEDEffect(
                id: 0xA9,
                name: "Destello Aleatorio",
                category: .special,
                requiresSpeed: true,
                description: "Destellos aleatorios en colores variados",
                defaultSpeed: 50
            ),
            LEDEffect(
                id: 0xAA,
                name: "Destello Rojo",
                category: .special,
                requiresSpeed: true,
                description: "Destellos rápidos en rojo",
                defaultSpeed: 70
            ),
            LEDEffect(
                id: 0xAB,
                name: "Desvanecimiento RGB",
                category: .dynamic,
                requiresSpeed: true,
                description: "Desvanecimiento suave entre R-G-B",
                defaultSpeed: 50
            ),
            LEDEffect(
                id: 0xAC,
                name: "Desvanecimiento Arcoíris",
                category: .dynamic,
                requiresSpeed: true,
                description: "Desvanecimiento suave entre 7 colores",
                defaultSpeed: 50
            ),
            LEDEffect(
                id: 0xAD,
                name: "Chispa",
                category: .special,
                requiresSpeed: true,
                description: "Efecto de chispas/parpadeo aleatorio",
                defaultSpeed: 60
            ),
            LEDEffect(
                id: 0xAE,
                name: "Ciclo Arcoíris",
                category: .dynamic,
                requiresSpeed: true,
                description: "Ciclo continuo del arcoíris completo",
                defaultSpeed: 50
            ),
            LEDEffect(
                id: 0xAF,
                name: "Fuego",
                category: .special,
                requiresSpeed: true,
                description: "Simulación de efecto fuego (naranja/rojo)",
                defaultSpeed: 40
            ),
            LEDEffect(
                id: 0xB0,
                name: "Policía",
                category: .special,
                requiresSpeed: true,
                description: "Efecto de luces policiales (rojo/azul)",
                defaultSpeed: 70
            ),
            LEDEffect(
                id: 0xB1,
                name: "Ambulancia",
                category: .special,
                requiresSpeed: true,
                description: "Efecto de ambulancia (rojo/blanco)",
                defaultSpeed: 60
            ),
            LEDEffect(
                id: 0xB2,
                name: "Chimenea",
                category: .special,
                requiresSpeed: true,
                description: "Efecto de chimenea/fuego suave",
                defaultSpeed: 35
            ),
            LEDEffect(
                id: 0xB3,
                name: "Tormenta",
                category: .special,
                requiresSpeed: true,
                description: "Efecto de tormenta (azul/blanco destellos)",
                defaultSpeed: 55
            ),
        ]
    }
    
    func effectsByCategory(_ category: EffectCategory) -> [LEDEffect] {
        return allEffects.filter { $0.category == category }.sorted { $0.id < $1.id }
    }
    
    func effectFor(id: UInt8) -> LEDEffect? {
        return allEffects.first { $0.id == id }
    }
    
    func searchEffects(_ query: String) -> [LEDEffect] {
        return allEffects.filter { effect in
            effect.name.lowercased().contains(query.lowercased()) ||
            effect.description.lowercased().contains(query.lowercased())
        }
    }
}

// MARK: - Effect Grid View Component
struct EffectGridView: View {
    let btManager: BluetoothManager
    @State private var selectedCategory: EffectCategory = .dynamic
    @State private var searchText = ""
    
    private var filteredEffects: [LEDEffect] {
        let effects = searchText.isEmpty 
            ? LEDEffectDatabase.shared.effectsByCategory(selectedCategory)
            : LEDEffectDatabase.shared.searchEffects(searchText)
        
        return effects.sorted { $0.id < $1.id }
    }
    
    var body: some View {
        VStack(spacing: 16) {
            // Search Bar
            HStack(spacing: 10) {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.white.opacity(0.5))
                
                TextField("Buscar efectos...", text: $searchText)
                    .textFieldStyle(.plain)
                    .foregroundColor(.white)
                
                if !searchText.isEmpty {
                    Button(action: { searchText = "" }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.white.opacity(0.5))
                    }
                }
            }
            .padding(10)
            .background(Color.white.opacity(0.05))
            .cornerRadius(8)
            .padding(.horizontal, 20)
            
            // Category Tabs
            if searchText.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 10) {
                        ForEach(EffectCategory.allCases, id: \.self) { category in
                            Button(action: { selectedCategory = category }) {
                                Text(category.rawValue)
                                    .font(.caption)
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 6)
                                    .background(selectedCategory == category ? Color.cyan : Color.white.opacity(0.1))
                                    .foregroundColor(.white)
                                    .cornerRadius(6)
                            }
                        }
                    }
                    .padding(.horizontal, 20)
                }
            }
            
            // Effects Grid
            ScrollView {
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                    ForEach(filteredEffects) { effect in
                        EffectCard(
                            effect: effect,
                            btManager: btManager
                        )
                    }
                }
                .padding(20)
            }
        }
    }
}

struct EffectCard: View {
    let effect: LEDEffect
    let btManager: BluetoothManager
    
    var body: some View {
        Button(action: {
            btManager.setEffect(effect.id)
            if effect.requiresSpeed {
                btManager.setEffectSpeed(effect.defaultSpeed)
            }
        }) {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(effect.name)
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(.white)
                        
                        Text("0x\(String(effect.id, radix: 16).uppercased())")
                            .font(.caption2)
                            .foregroundColor(.cyan)
                    }
                    Spacer()
                    Image(systemName: "sparkles")
                        .foregroundColor(.cyan)
                        .font(.system(size: 16))
                }
                
                Text(effect.description)
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.6))
                    .lineLimit(2)
                
                HStack(spacing: 6) {
                    Text(effect.category.rawValue)
                        .font(.caption2)
                        .foregroundColor(.white)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 2)
                        .background(Color.white.opacity(0.1))
                        .cornerRadius(3)
                    
                    if effect.requiresSpeed {
                        Text("Adj. Vel")
                            .font(.caption2)
                            .foregroundColor(.orange)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 2)
                            .background(Color.orange.opacity(0.2))
                            .cornerRadius(3)
                    }
                    
                    Spacer()
                }
            }
            .padding(12)
            .background(Color.white.opacity(0.05))
            .cornerRadius(10)
        }
    }
}
