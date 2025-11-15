import Foundation
import Combine

// MARK: - Use Case Protocol

protocol PokemonListUseCase {
    func fetchPokemonList(pageSize: Int, offset: Int) async throws -> [Pokemon]
    func searchPokemon(query: String) async throws -> [Pokemon]
}

// MARK: - Default Implementation

class DefaultPokemonListUseCase: PokemonListUseCase {
    private let repository: PokemonAPIProvider

    init(repository: PokemonAPIProvider) {
        self.repository = repository
    }

    func fetchPokemonList(pageSize: Int, offset: Int) async throws -> [Pokemon] {
        try await repository.fetchPokemonList(limit: pageSize, offset: offset)
    }

    func searchPokemon(query: String) async throws -> [Pokemon] {
        try await repository.searchPokemon(query: query)
    }
}

// MARK: - Mock Implementation (for testing)

class MockPokemonListUseCase: PokemonListUseCase {
    var mockPokemon: [Pokemon] = [
        Pokemon(id: "bulbasaur", name: "Bulbasaur", number: 1, imageUrl: "https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/pokemon/1.png", types: ["Grass", "Poison"]),
        Pokemon(id: "ivysaur", name: "Ivysaur", number: 2, imageUrl: "https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/pokemon/2.png", types: ["Grass", "Poison"]) 
    ]

    var shouldThrowError = false
    var mockError: Error?

    func fetchPokemonList(pageSize: Int, offset: Int) async throws -> [Pokemon] {
        if shouldThrowError { throw mockError ?? NSError(domain: "MockError", code: -1) }
        return mockPokemon
    }

    func searchPokemon(query: String) async throws -> [Pokemon] {
        if shouldThrowError { throw mockError ?? NSError(domain: "MockError", code: -1) }
        return mockPokemon.filter { $0.name.lowercased().contains(query.lowercased()) }
    }
}
