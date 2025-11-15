# Setting Up Factory (Recommended) or Swinject DI

This guide shows how to integrate professional DI libraries into your PokéDex app.

## Option 1: Factory Library (Recommended) ⭐

### Step 1: Install Factory via SPM

1. In Xcode, go to **File → Add Packages**
2. Paste URL: `https://github.com/hmlongco/Factory.git`
3. Select Version: **2.5.3** or later
4. Choose **PokeDex** target
5. Click **Add Package**

### Step 2: Create Container Extension

Create a new file: `Di/ContainerFactory.swift`

```swift
import FactoryKit
import Foundation

extension Container {
    // MARK: - Network Layer (Singleton)
    
    var apiClient: Factory<APIClient> {
        self { APIClient() }
            .singleton
    }
    
    // MARK: - Data Layer (Singleton)
    
    var pokemonRepository: Factory<PokemonAPIProvider> {
        self { 
            PokemonRepository(apiClient: self.apiClient()) 
        }
        .singleton
    }
    
    // MARK: - Domain Layer (Use Cases - New Instance Each Time)
    
    var pokemonListUseCase: Factory<PokemonListUseCase> {
        self { 
            DefaultPokemonListUseCase(repository: self.pokemonRepository()) 
        }
        // .transient is default, no modifier needed
    }
    
    // MARK: - Presentation Layer (ViewModels)
    
    var pokemonListViewModel: Factory<PokemonListViewModel> {
        self { 
            PokemonListViewModel(useCase: self.pokemonListUseCase()) 
        }
    }
}
```

### Step 3: Use in ViewModel

Update `PokemonListViewModel.swift`:

```swift
import FactoryKit

@MainActor
class PokemonListViewModel: ObservableObject {
    @Published var viewState: ViewState<[Pokemon]> = .idle
    @Published var searchQuery: String = ""
    
    private let useCase: PokemonListUseCase
    
    // Inject directly via property wrapper
    @Injected(\.pokemonListUseCase) private var injectedUseCase
    
    // Or pass via initializer
    init(useCase: PokemonListUseCase = Container.shared.pokemonListUseCase()) {
        self.useCase = useCase
    }
    
    // ... rest of code
}
```

### Step 4: Use in SwiftUI View

```swift
import FactoryKit

struct PokemonListView: View {
    // Option 1: Property wrapper injection (automatic)
    @StateObject @Injected(\.pokemonListViewModel) 
    private var viewModel
    
    // Option 2: Manual creation
    @StateObject private var viewModel = Container.shared.pokemonListViewModel()
    
    var body: some View {
        // ... rest of code
    }
}
```

### Step 5: Testing with Factory

```swift
import XCTest
import FactoryKit

class PokemonListViewModelTests: XCTestCase {
    
    override func setUp() {
        super.setUp()
        Container.shared.reset()
    }
    
    func testLoadingState() async {
        // Register mock
        Container.shared.pokemonRepository.register { 
            MockPokemonRepository() 
        }
        
        // Create view model with mocked dependency
        let viewModel = Container.shared.pokemonListViewModel()
        
        // Test
        await viewModel.loadPokemonList()
        XCTAssertTrue(viewModel.viewState.value != nil)
    }
    
    func testErrorState() async {
        // Register error mock
        Container.shared.pokemonRepository.register { 
            MockErrorPokemonRepository() 
        }
        
        let viewModel = Container.shared.pokemonListViewModel()
        await viewModel.loadPokemonList()
        
        XCTAssertTrue(viewModel.viewState.errorMessage != nil)
    }
}
```

### Factory Scopes Explained

```swift
extension Container {
    // Creates NEW instance every time
    var service1: Factory<MyService> {
        self { MyService() }
        // .transient is default
    }
    
    // Singleton - ONE instance for entire app lifetime
    var service2: Factory<MyService> {
        self { MyService() }
            .singleton
    }
    
    // Cached - Instance persists until cache reset
    var service3: Factory<MyService> {
        self { MyService() }
            .cached
    }
    
    // Shared - Weakly held, survives as long as someone references it
    var service4: Factory<MyService> {
        self { MyService() }
            .shared
    }
    
    // Custom scope (e.g., per-session)
    var service5: Factory<MyService> {
        self { MyService() }
            .scope(.session)
    }
}
```

---

## Option 2: Swinject Library (Alternative)

### Step 1: Install Swinject via SPM

1. In Xcode, go to **File → Add Packages**
2. Paste URL: `https://github.com/Swinject/Swinject.git`
3. Select Version: **2.8.0** or later
4. Choose **PokeDex** target
5. Click **Add Package**

### Step 2: Create Container Setup

Create a new file: `Di/SwinjectContainer.swift`

```swift
import Swinject
import Foundation

class SwinjectContainer {
    static let shared = {
        let container = Container()
        setupContainer(container)
        return container
    }()
    
    private static func setupContainer(_ container: Container) {
        // MARK: - Network Layer (Singleton)
        
        container.register(APIClient.self) { _ in
            APIClient()
        }
        .inObjectScope(.container)
        
        // MARK: - Data Layer (Singleton)
        
        container.register(PokemonAPIProvider.self) { r in
            PokemonRepository(apiClient: r.resolve(APIClient.self)!)
        }
        .inObjectScope(.container)
        
        // MARK: - Domain Layer (Use Cases - Transient)
        
        container.register(PokemonListUseCase.self) { r in
            DefaultPokemonListUseCase(
                repository: r.resolve(PokemonAPIProvider.self)!
            )
        }
        
        // MARK: - Presentation Layer (ViewModels - Transient)
        
        container.register(PokemonListViewModel.self) { r in
            PokemonListViewModel(
                useCase: r.resolve(PokemonListUseCase.self)!
            )
        }
    }
}
```

### Step 3: Use in ViewModel

```swift
import Swinject

@MainActor
class PokemonListViewModel: ObservableObject {
    @Published var viewState: ViewState<[Pokemon]> = .idle
    @Published var searchQuery: String = ""
    
    private let useCase: PokemonListUseCase
    
    init(useCase: PokemonListUseCase = 
         SwinjectContainer.shared.resolve(PokemonListUseCase.self)!) {
        self.useCase = useCase
    }
    
    // ... rest of code
}
```

### Step 4: Testing with Swinject

```swift
import XCTest
import Swinject

class PokemonListViewModelTests: XCTestCase {
    
    var container: Container!
    
    override func setUp() {
        super.setUp()
        container = Container()
    }
    
    func testLoadingState() async {
        // Register mock for this test
        container.register(PokemonAPIProvider.self) { _ in
            MockPokemonRepository()
        }
        
        container.register(PokemonListUseCase.self) { r in
            DefaultPokemonListUseCase(
                repository: r.resolve(PokemonAPIProvider.self)!
            )
        }
        
        let viewModel = PokemonListViewModel(
            useCase: container.resolve(PokemonListUseCase.self)!
        )
        
        await viewModel.loadPokemonList()
        XCTAssertTrue(viewModel.viewState.value != nil)
    }
}
```

### Swinject Object Scopes

```swift
// New instance every time (default)
container.register(MyService.self) { _ in MyService() }

// Singleton - ONE instance for entire app
container.register(MyService.self) { _ in MyService() }
    .inObjectScope(.container)

// Weak singleton - instance survives as long as someone holds it
container.register(MyService.self) { _ in MyService() }
    .inObjectScope(.weakSingleton)

// Transient with arguments
container.register(MyService.self) { _, param in 
    MyService(config: param) 
}
```

---

## Comparison: Current vs Factory vs Swinject

### Current Manual Setup (No External Dependency)

**Pros:**
- ✅ Zero external dependencies
- ✅ Full control
- ✅ Simple to understand
- ✅ Easy debugging

**Cons:**
- ❌ Manual singleton management
- ❌ No type-safe resolution
- ❌ More boilerplate for testing

### With Factory Library

**Pros:**
- ✅ Type-safe (compile-time)
- ✅ Fluent API
- ✅ Easy property wrapper injection
- ✅ Excellent testing support
- ✅ Best for SwiftUI
- ✅ Modern Swift

**Cons:**
- ⚠️ External dependency
- ⚠️ Small community (but active)

### With Swinject Library

**Pros:**
- ✅ Full-featured
- ✅ Large community
- ✅ Powerful configuration
- ✅ Good documentation

**Cons:**
- ❌ Runtime reflection (less type-safe)
- ⚠️ More verbose
- ⚠️ Harder to debug
- ⚠️ UIKit-centric

---

## Migration Path: Manual → Factory

If you start with manual DI and want to migrate to Factory later:

### Before (Manual)
```swift
// Di/DependencyContainer.swift
class DependencyContainer {
    static let shared = DependencyContainer()
    private lazy var useCase = DefaultPokemonListUseCase(repository: pokemonRepository)
}

// Usage
let useCase = DependencyContainer.shared.resolvePokemonListUseCase()
```

### After (Factory)
```swift
// Di/ContainerFactory.swift
extension Container {
    var pokemonListUseCase: Factory<PokemonListUseCase> {
        self { DefaultPokemonListUseCase(repository: self.pokemonRepository()) }
    }
}

// Usage (same!)
let useCase = Container.shared.pokemonListUseCase()
```

**The API is almost identical!**

---

## My Recommendation

### For This Project: Start with Manual DI

**Why:**
- You already have it working
- Zero dependencies
- Perfect for learning
- Easy to test

### When to Add Factory/Swinject

**Add when:**
- App grows to 5+ screens
- You need property wrapper injection
- Testing becomes complex
- Team wants standard practices

**Choose Factory if:**
- You value simplicity and type-safety
- Using modern SwiftUI
- Want best testing experience

**Choose Swinject if:**
- Team wants full-featured DI container
- Need UIKit Storyboard integration
- Want maximum flexibility

---

## Next Steps

1. **For now**: Stick with manual DI (already working)
2. **Later**: If needed, add Factory with just one file change
3. **Testing**: Use MockPokemonListUseCase for tests

Your current setup follows the exact same principles as both Factory and Swinject, just without the external library overhead!
