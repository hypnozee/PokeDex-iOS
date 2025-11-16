import Foundation

// MARK: - Dependency Container (Factory Pattern - No External Dependency)

class DependencyContainer {
    // Singleton instance
    static let shared = DependencyContainer()
    
    // MARK: - Network Layer (Singletons - shared across app)
    
    private lazy var apiClient: APIClient = {
        APIClient()
    }()
    
    // MARK: - Data Layer (Singletons)
    
    private lazy var pokemonRepository: PokemonAPIProvider = {
        PokemonRepository(apiClient: apiClient)
    }()
    
    // MARK: - Domain Layer (Use Cases - Factory pattern)
    
    private lazy var pokemonListUseCase: PokemonListUseCase = {
        DefaultPokemonListUseCase(repository: pokemonRepository)
    }()

    private lazy var pokemonDetailUseCase: PokemonDetailUseCase = {
        DefaultPokemonDetailUseCase(repository: pokemonRepository)
    }()
    
    // MARK: - Presentation Layer (ViewModels - Factory pattern)
    
    func makePokemonListViewModel() -> PokemonListViewModel {
        PokemonListViewModel(useCase: pokemonListUseCase)
    }

    func makePokemonDetailViewModel(nameOrId: String) -> PokemonDetailViewModel {
        PokemonDetailViewModel(nameOrId: nameOrId, useCase: pokemonDetailUseCase)
    }
    
    // MARK: - Public Resolution Methods
    
    func resolvePokemonRepository() -> PokemonAPIProvider {
        pokemonRepository
    }
    
    func resolvePokemonListUseCase() -> PokemonListUseCase {
        pokemonListUseCase
    }
    
    func resolvePokemonListViewModel() -> PokemonListViewModel {
        makePokemonListViewModel()
    }

    func resolvePokemonDetailUseCase() -> PokemonDetailUseCase {
        pokemonDetailUseCase
    }
    
    // MARK: - Testing Support
    
    /// Reset all dependencies (useful for testing)
    func reset() {
        // This would reset all lazy properties if needed
        // For now, we rely on creating a new instance for tests
    }
}
