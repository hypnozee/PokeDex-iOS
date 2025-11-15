 # iOS Dependency Injection: Swinject vs Factory vs Manual DI

A comparison guide for transitioning from Android's Koin DI pattern.

## Quick Comparison

| Feature | Swinject | Factory | Manual DI |
|---------|----------|---------|-----------|
| **Popularity** | ⭐⭐⭐⭐ (6.7k stars) | ⭐⭐⭐ (2.6k stars) | N/A |
| **Learning Curve** | Steep | Moderate | Easy |
| **Compile-Time Safety** | ❌ No | ✅ Yes | ✅ Yes |
| **Type Safety** | ⚠️ Medium | ✅ High | ✅ High |
| **Syntax** | Verbose | Concise | Minimal |
| **Container-based** | ✅ Yes | ✅ Yes | N/A |
| **Scopes** | ✅ Rich | ✅ Rich | Manual |
| **Testing** | ✅ Good | ✅ Excellent | ✅ Good |
| **SwiftUI Integration** | ⚠️ OK | ✅ Excellent | ⚠️ Manual |
| **Size** | ~1.5k lines | ~1k lines | N/A |
| **Perfect for Koin Users** | ✅ **YES** | ✅ **YES** | ✅ Simpler |

## Best Choice for Your Android Background

Coming from **Android's Koin**, here are my recommendations:

### 🏆 **Recommended: Factory**
**Why?** Most similar to Koin's philosophy:
- **Lightweight**: Minimal boilerplate
- **Fluent API**: Chain-able configuration like Koin
- **Type-safe**: Compile-time verification
- **SwiftUI-native**: Best integration with modern Swift
- **Testing**: Easiest mocking for unit tests
- **Future-proof**: Under active development, aligns with Swift's direction

### 🥈 **Alternative: Swinject**
**If you prefer:**
- Full feature-rich container system
- Storyboard integration (if using UIKit)
- More Hilt-like experience
- Largest community

### 🥉 **Lightweight Option: Manual DI**
**If you prefer:**
- Zero external dependencies
- Simplicity
- Full control
- Current codebase approach

---

## Architecture Mapping: Android Koin → iOS DI

### Android (Koin)
```kotlin
// Module definition
val appModule = module {
    // Singletons
    single { NetworkService() }
    single { PokemonRepository(networkService = get()) }
    
    // Factory (new instance each time)
    factory { PokemonListUseCase(repository = get()) }
    
    // ViewModels
    viewModel { PokemonListViewModel(useCase = get()) }
}

// App setup
startKoin {
    modules(appModule)
}

// Usage in ViewModel
class PokemonListViewModel(val useCase: PokemonListUseCase) : ViewModel()
```

### iOS with Factory (Recommended)
```swift
// Container extension
extension Container {
    // Singletons
    var networkService: Factory<NetworkService> { 
        self { NetworkService() }
            .singleton
    }
    
    var pokemonRepository: Factory<PokemonRepositoryType> {
        self { PokemonRepository(networkService: self.networkService()) }
            .singleton
    }
    
    // Factory (new instance each time)
    var pokemonListUseCase: Factory<PokemonListUseCase> {
        self { PokemonListUseCase(repository: self.pokemonRepository()) }
    }
    
    // ViewModels
    var pokemonListViewModel: Factory<PokemonListViewModel> {
        self { PokemonListViewModel(useCase: self.pokemonListUseCase()) }
    }
}

// App setup
// (No setup needed - Container.shared is available immediately)

// Usage in ViewModel
class PokemonListViewModel: ObservableObject {
    private let useCase: PokemonListUseCase
    
    init(useCase: PokemonListUseCase = Container.shared.pokemonListUseCase()) {
        self.useCase = useCase
    }
}
```

### iOS with Swinject
```swift
// Container setup
let container = Container()

// Singletons
container.register(NetworkService.self) { _ in NetworkService() }
    .inObjectScope(.container)

container.register(PokemonRepositoryType.self) { r in
    PokemonRepository(networkService: r.resolve(NetworkService.self)!)
}
.inObjectScope(.container)

// Factory (new instance each time)
container.register(PokemonListUseCase.self) { r in
    PokemonListUseCase(repository: r.resolve(PokemonRepositoryType.self)!)
}

// ViewModels
container.register(PokemonListViewModel.self) { r in
    PokemonListViewModel(useCase: r.resolve(PokemonListUseCase.self)!)
}

// App setup (in AppDelegate or App)
AppDelegate.container = container

// Usage
let viewModel = AppDelegate.container.resolve(PokemonListViewModel.self)!
```

---

## Side-by-Side Code Examples

### 1. Simple Service Registration

#### Android (Koin)
```kotlin
val appModule = module {
    single { APIClient() }
}
```

#### iOS with Factory (Recommended)
```swift
extension Container {
    var apiClient: Factory<APIClient> {
        self { APIClient() }
            .singleton
    }
}

// Usage
let client = Container.shared.apiClient()
```

#### iOS with Swinject
```swift
container.register(APIClient.self) { _ in APIClient() }
    .inObjectScope(.container)

// Usage
let client = container.resolve(APIClient.self)!
```

---

### 2. Dependency Chain

#### Android (Koin)
```kotlin
val appModule = module {
    single { NetworkService() }
    single { UserRepository(service = get()) }
    single { UserUseCase(repository = get()) }
    viewModel { UserViewModel(useCase = get()) }
}
```

#### iOS with Factory (Recommended)
```swift
extension Container {
    var networkService: Factory<NetworkService> {
        self { NetworkService() }
            .singleton
    }
    
    var userRepository: Factory<UserRepositoryType> {
        self { UserRepository(service: self.networkService()) }
            .singleton
    }
    
    var userUseCase: Factory<UserUseCase> {
        self { UserUseCase(repository: self.userRepository()) }
    }
    
    var userViewModel: Factory<UserViewModel> {
        self { UserViewModel(useCase: self.userUseCase()) }
    }
}

// Usage
let viewModel = Container.shared.userViewModel()
```

#### iOS with Swinject
```swift
container.register(NetworkService.self) { _ in 
    NetworkService() 
}
.inObjectScope(.container)

container.register(UserRepositoryType.self) { r in 
    UserRepository(service: r.resolve(NetworkService.self)!) 
}
.inObjectScope(.container)

container.register(UserUseCase.self) { r in 
    UserUseCase(repository: r.resolve(UserRepositoryType.self)!) 
}

container.register(UserViewModel.self) { r in 
    UserViewModel(useCase: r.resolve(UserUseCase.self)!) 
}
```

---

### 3. Testing / Mocking

#### Android (Koin)
```kotlin
@Test
fun testViewModel() {
    val testModule = module {
        single { MockUserRepository() }
        viewModel { UserViewModel(useCase = get()) }
    }
    
    startKoin {
        modules(testModule)
    }
    
    val viewModel = getViewModel<UserViewModel>()
    // Test
}
```

#### iOS with Factory (Recommended) ⭐
```swift
func testViewModel() {
    // Simply register a mock before creating the view model
    Container.shared.userRepository.register { MockUserRepository() }
    
    let viewModel = Container.shared.userViewModel()
    // Test
}
```

#### iOS with Swinject
```swift
func testViewModel() {
    let container = Container()
    
    container.register(UserRepositoryType.self) { _ in
        MockUserRepository()
    }
    
    container.register(UserViewModel.self) { r in
        UserViewModel(useCase: UserUseCase(repository: r.resolve(UserRepositoryType.self)!))
    }
    
    let viewModel = container.resolve(UserViewModel.self)!
    // Test
}
```

---

### 4. SwiftUI Preview / Testing

#### iOS with Factory (Recommended) ⭐
```swift
#Preview {
    // One-liner mock setup
    Container.shared.userRepository.preview { MockUserRepository() }
    
    return ContentView()
}
```

#### iOS with Swinject
```swift
#Preview {
    let container = Container()
    // ... complex setup ...
    
    return ContentViewWrapper(container: container)
}
```

---

## Installation & Setup

### Option 1: Factory (Recommended)

**Install via SPM:**
1. In Xcode: File → Add Packages
2. Paste: `https://github.com/hmlongco/Factory.git`
3. Select version 2.5.3+
4. Add to PokeDex target
5. Import in files: `import FactoryKit`

**Install via CocoaPods:**
```ruby
pod 'Factory'
```

### Option 2: Swinject

**Install via SPM:**
1. In Xcode: File → Add Packages
2. Paste: `https://github.com/Swinject/Swinject.git`
3. Select version 2.8.0+
4. Add to PokeDex target
5. Import in files: `import Swinject`

**Install via CocoaPods:**
```ruby
pod 'Swinject'
```

---

## Recommendation for Your Project

Given your Android Koin experience, I recommend **Factory** because:

1. **Familiar Concepts**
   - Koin's `single` → Factory's `.singleton`
   - Koin's `factory` → Factory's default (no modifier)
   - Koin's `get()` → Factory's `Container.shared.service()`

2. **Type-Safe**
   - Won't compile if a dependency is missing
   - No runtime surprises

3. **Testing-Friendly**
   - Easiest to mock for unit tests
   - Clean preview support

4. **SwiftUI-Native**
   - Best integration with modern iOS
   - Aligns with Swift's future direction

5. **Modern Approach**
   - Uses Swift's strong type system
   - No reflection or runtime magic
   - Less boilerplate than Swinject

---

## Comparison Matrix

| Use Case | Koin | Factory | Swinject |
|----------|------|---------|----------|
| Singleton registration | `single { }` | `.singleton` | `.inObjectScope(.container)` |
| Factory registration | `factory { }` | (default) | (default) |
| Transient registration | N/A | `.transient` | (default) |
| Scoped registration | `scoped { }` | `.session`, `.cached` | `.inObjectScope(.weakSingleton)` |
| Get dependency | `get()` | `get()` | `resolve()` |
| Named registration | `named("key")` | N/A | N/A |
| Circular dependencies | ✅ | ⚠️ | ✅ |
| Runtime safety | Medium | High | Medium |
| Compile-time safety | ❌ | ✅ | ❌ |
| Documentation | Good | Excellent | Good |
| Learning curve | Medium | Low | High |
| Community size | Large | Small | Medium |

---

## My Final Verdict

**Use Factory** if you want:
- The smoothest transition from Koin
- Modern Swift patterns
- Type safety
- Best testing support
- Least boilerplate

**Use Swinject** if you want:
- Feature parity with Hilt/Guice
- Larger community
- More configuration options
- UIKit Storyboard support

**Use Manual DI** if you want:
- Zero dependencies
- Simplicity
- Full control
- Current approach in your codebase

---

## Resources

- **Factory Documentation**: https://hmlongco.github.io/Factory/documentation/factorykit
- **Swinject GitHub**: https://github.com/Swinject/Swinject
- **Factory GitHub**: https://github.com/hmlongco/Factory
- **Swift DI Patterns**: https://www.raywenderlich.com/14223279-dependency-injection-tutorial-for-ios-getting-started
