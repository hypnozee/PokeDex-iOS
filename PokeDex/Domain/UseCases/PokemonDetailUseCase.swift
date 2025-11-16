import Foundation

protocol PokemonDetailUseCase {
    func fetchPokemonDetail(nameOrId: String) async throws -> PokemonDetail
}

struct DefaultPokemonDetailUseCase: PokemonDetailUseCase {
    private let repository: PokemonAPIProvider

    init(repository: PokemonAPIProvider) {
        self.repository = repository
    }

    func fetchPokemonDetail(nameOrId: String) async throws -> PokemonDetail {
        try await repository.fetchPokemonDetail(nameOrId: nameOrId)
    }
}
