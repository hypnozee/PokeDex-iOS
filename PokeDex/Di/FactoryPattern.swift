import Foundation

// MARK: - Factory Pattern Container (Alternative to Manual DI)
// This shows how to use the Factory pattern manually without external dependencies.
// For a more feature-rich solution, consider using the Factory library:
// https://github.com/hmlongco/Factory

/// A lightweight Factory-based DI container similar to Koin
/// Usage:
/// ```
/// extension Container {
///     var pokemonRepository: Factory<PokemonAPIProvider> {
///         Factory { PokemonRepository(apiClient: self.apiClient()) }
///     }
/// }
/// ```

class Container {
    static let shared = Container()
    
    private var factories: [String: Any] = [:]
    private var singletons: [String: Any] = [:]
    
    /// Register a singleton factory
    func singleton<T>(_ key: String, factory: @escaping () -> T) {
        factories[key] = factory
    }
    
    /// Register a transient factory
    func transient<T>(_ key: String, factory: @escaping () -> T) {
        factories[key] = factory
    }
    
    /// Resolve a registered type
    func resolve<T>(_ key: String, type: T.Type) -> T? {
        if let singleton = singletons[key] as? T {
            return singleton
        }
        
        guard let factory = factories[key] as? () -> T else {
            return nil
        }
        
        let instance = factory()
        singletons[key] = instance
        return instance
    }
    
    /// Reset all singletons (useful for testing)
    func reset() {
        singletons.removeAll()
    }
}

// MARK: - Example Extension for PokéDex App
/*
extension Container {
    // Singletons
    var apiClient: Factory<APIClient> {
        Factory { APIClient() }
            .singleton(self)
    }
    
    var pokemonRepository: Factory<PokemonAPIProvider> {
        Factory { PokemonRepository(apiClient: self.apiClient()) }
            .singleton(self)
    }
    
    // Use Cases
    var pokemonListUseCase: Factory<PokemonListUseCase> {
        Factory { DefaultPokemonListUseCase(repository: self.pokemonRepository()) }
    }
    
    // ViewModels
    var pokemonListViewModel: Factory<PokemonListViewModel> {
        Factory { PokemonListViewModel(useCase: self.pokemonListUseCase()) }
    }
}

// Usage
let useCase = Container.shared.pokemonListUseCase()
let viewModel = Container.shared.pokemonListViewModel()
*/
