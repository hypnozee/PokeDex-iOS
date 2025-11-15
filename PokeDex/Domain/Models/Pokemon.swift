import Foundation

// MARK: - Domain Layer Protocol for API

protocol PokemonAPIProvider {
    func fetchPokemonList(limit: Int, offset: Int) async throws -> [Pokemon]
    func searchPokemon(query: String) async throws -> [Pokemon]
}

// MARK: - API Response Models (Codable for JSON parsing)

struct PokemonListResponse: Codable {
    let count: Int
    let next: String?
    let previous: String?
    let results: [PokemonRef]
}

struct PokemonRef: Codable, Identifiable {
    let id = UUID()
    let name: String
    let url: String
    
    enum CodingKeys: String, CodingKey {
        case name
        case url
    }
    
    var number: Int? {
        // Robust parsing: use URL's lastPathComponent to support urls with/without trailing slash
        if let u = URL(string: url) {
            let last = u.lastPathComponent
            return Int(last)
        }
        // Fallback: attempt the old split approach
        return url.split(separator: "/").last.flatMap { Int($0) }
    }
}

struct PokemonDetail: Codable {
    let id: Int
    let name: String
    let sprites: Sprites
    let types: [TypeSlot]
    let height: Int
    let weight: Int
}

struct Sprites: Codable {
    let frontDefault: String?
    let backDefault: String?
    
    enum CodingKeys: String, CodingKey {
        case frontDefault = "front_default"
        case backDefault = "back_default"
    }
}

struct TypeSlot: Codable {
    let type: TypeInfo
}

struct TypeInfo: Codable {
    let name: String
}

// MARK: - Domain Model (UI representation)

struct Pokemon: Identifiable, Codable {
    let id: String
    let name: String
    let number: Int?
    let imageUrl: String?
    let types: [String]
    
    init(from ref: PokemonRef) {
        self.id = ref.name
        self.name = ref.name.capitalized
        self.number = ref.number
        if let num = ref.number {
            self.imageUrl = "https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/pokemon/\(num).png"
        } else {
            self.imageUrl = nil
        }
        self.types = []
    }
    
    // For testing/preview
    init(id: String, name: String, number: Int?, imageUrl: String?, types: [String]) {
        self.id = id
        self.name = name
        self.number = number
        self.imageUrl = imageUrl
        self.types = types
    }
}
