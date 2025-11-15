# Complete DI Guide: From Koin (Android) to iOS

Your PokéDex app now implements professional Dependency Injection following the exact patterns used in your Android Koin setup. Here's the complete comparison.

## Architecture Overview

### Your Android Koin Setup
```
┌─────────────────────────────────────┐
│        Koin Container               │
├─────────────────────────────────────┤
│                                     │
│  single { NetworkService() }        │ ← Singleton
│  single { UserRepository(...) }     │ ← Singleton
│  factory { UserUseCase(...) }       │ ← Factory (new each time)
│  viewModel { UserViewModel(...) }   │ ← ViewModel
│                                     │
└─────────────────────────────────────┘
         ↓ get() or inject
      ViewModels/Activities
```

### Your New iOS Setup
```
┌──────────────────────────────────────┐
│    DependencyContainer (Singleton)   │
├──────────────────────────────────────┤
│                                      │
│  lazy var apiClient: APIClient       │ ← Singleton
│  lazy var repository: Repository     │ ← Singleton  
│  func makeUseCase(): UseCase         │ ← Factory
│  func makeViewModel(): ViewModel     │ ← ViewModel
│                                      │
└──────────────────────────────────────┘
         ↓ resolve() or init
      ViewModels/Views
```

## File Structure

```
PokeDex/
├── Domain/
│   ├── Models/
│   │   └── Pokemon.swift              # Models + protocols
│   └── UseCases/
│       └── PokemonListUseCase.swift   # Use cases (interface + impl + mock)
│
├── Data/
│   ├── Network/
│   │   └── APIClient.swift           # HTTP wrapper
│   └── Repository/
│       └── PokemonRepository.swift    # Repository implementation
│
├── Presentation/
│   ├── PokemonList/
│   │   ├── PokemonListView.swift
│   │   ├── PokemonListViewModel.swift
│   │   └── PokemonCardView.swift
│   └── Common/
│       └── ViewState.swift           # State enum
│
└── Di/
    ├── DependencyContainer.swift      # Manual DI (current)
    └── FactoryPattern.swift           # Example Factory pattern (optional)
```

## Koin vs iOS DI - Step by Step

### Step 1: Define Repository Interface (Domain Layer)

#### Android (Koin)
```kotlin
// domain/repository/UserRepository.kt
interface UserRepository {
    suspend fun getUser(): User
}

// data/repository/UserRepositoryImpl.kt
class UserRepositoryImpl(
    private val service: NetworkService
) : UserRepository {
    override suspend fun getUser(): User = service.fetchUser()
}
```

#### iOS
```swift
// Domain/Models/User.swift
protocol UserRepository {
    func getUser() async throws -> User
}

// Data/Repository/UserRepository.swift
class UserRepositoryImpl: UserRepository {
    private let service: NetworkService
    
    init(service: NetworkService) {
        self.service = service
    }
    
    func getUser() async throws -> User {
        try await service.fetchUser()
    }
}
```

### Step 2: Create Use Case (Domain Layer)

#### Android (Koin)
```kotlin
// domain/usecase/GetUserUseCase.kt
class GetUserUseCase(
    private val repository: UserRepository
) {
    suspend operator fun invoke(): User {
        return repository.getUser()
    }
}
```

#### iOS
```swift
// Domain/UseCases/GetUserUseCase.swift
protocol GetUserUseCase {
    func execute() async throws -> User
}

class DefaultGetUserUseCase: GetUserUseCase {
    private let repository: UserRepository
    
    init(repository: UserRepository) {
        self.repository = repository
    }
    
    func execute() async throws -> User {
        try await repository.getUser()
    }
}
```

### Step 3: Register in DI Container

#### Android (Koin)
```kotlin
// di/AppModule.kt
val appModule = module {
    single { NetworkService() }
    
    single<UserRepository> { 
        UserRepositoryImpl(service = get()) 
    }
    
    factory { 
        GetUserUseCase(repository = get()) 
    }
    
    viewModel { 
        UserViewModel(useCase = get()) 
    }
}

// MainActivity.kt
startKoin {
    modules(appModule)
}
```

#### iOS (Manual DI - Your Current Approach)
```swift
// Di/DependencyContainer.swift
class DependencyContainer {
    static let shared = DependencyContainer()
    
    // Singleton (reused)
    private lazy var networkService: NetworkService = {
        NetworkService()
    }()
    
    private lazy var userRepository: UserRepository = {
        UserRepositoryImpl(service: networkService)
    }()
    
    // Factory (new instance each time)
    func makeGetUserUseCase() -> GetUserUseCase {
        DefaultGetUserUseCase(repository: userRepository)
    }
    
    func makeUserViewModel() -> UserViewModel {
        UserViewModel(useCase: makeGetUserUseCase())
    }
}
```

#### iOS (With Factory Library - Optional)
```swift
// Di/ContainerFactory.swift
import FactoryKit

extension Container {
    var networkService: Factory<NetworkService> {
        self { NetworkService() }
            .singleton
    }
    
    var userRepository: Factory<UserRepository> {
        self { UserRepositoryImpl(service: self.networkService()) }
            .singleton
    }
    
    var getUserUseCase: Factory<GetUserUseCase> {
        self { DefaultGetUserUseCase(repository: self.userRepository()) }
    }
    
    var userViewModel: Factory<UserViewModel> {
        self { UserViewModel(useCase: self.getUserUseCase()) }
    }
}
```

### Step 4: Use in ViewModel

#### Android (Koin)
```kotlin
class UserViewModel(
    private val useCase: GetUserUseCase
) : ViewModel() {
    
    fun loadUser() {
        viewModelScope.launch {
            val user = useCase()
        }
    }
}
```

#### iOS
```swift
class UserViewModel: ObservableObject {
    private let useCase: GetUserUseCase
    
    init(useCase: GetUserUseCase = DependencyContainer.shared.makeGetUserUseCase()) {
        self.useCase = useCase
    }
    
    func loadUser() async {
        do {
            let user = try await useCase.execute()
            // ...
        } catch {
            // ...
        }
    }
}
```

### Step 5: Use in View/Activity

#### Android (Koin)
```kotlin
class MainActivity : AppCompatActivity() {
    private val viewModel: UserViewModel by viewModel()
    
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        viewModel.loadUser()
    }
}
```

#### iOS
```swift
struct ContentView: View {
    @StateObject private var viewModel = UserViewModel()
    
    var body: some View {
        VStack {
            Text("User App")
        }
        .task {
            await viewModel.loadUser()
        }
    }
}

// Or with manual initialization
struct ContentView: View {
    @StateObject private var viewModel = 
        StateObject(initialValue: DependencyContainer.shared.makeUserViewModel())
    
    var body: some View {
        VStack {
            Text("User App")
        }
    }
}
```

## Testing

### Android (Koin)
```kotlin
@Test
fun testViewModel() {
    val testModule = module {
        single { MockUserRepository() }
        factory { GetUserUseCase(repository = get()) }
        viewModel { UserViewModel(useCase = get()) }
    }
    
    startKoin {
        modules(testModule)
    }
    
    val viewModel = getViewModel<UserViewModel>()
    // Test
}
```

### iOS (Manual DI)
```swift
func testViewModel() {
    // Create mock repository
    let mockRepository = MockUserRepository()
    
    // Create use case with mock
    let useCase = DefaultGetUserUseCase(repository: mockRepository)
    
    // Create view model
    let viewModel = UserViewModel(useCase: useCase)
    
    // Test
    XCTAssertNotNil(viewModel)
}
```

### iOS (With Factory Library)
```swift
import FactoryKit

func testViewModel() {
    // Override dependency
    Container.shared.userRepository.register { MockUserRepository() }
    
    // Get view model (will use mock)
    let viewModel = Container.shared.userViewModel()
    
    // Test
    XCTAssertNotNil(viewModel)
    
    // Reset for next test
    Container.shared.reset()
}
```

## Terminology Mapping

| Concept | Android/Koin | iOS (Current) | iOS (Factory) |
|---------|---|---|---|
| **Container** | Koin | DependencyContainer | Container |
| **Singleton** | `single { }` | `private lazy var` | `.singleton` |
| **Factory** | `factory { }` | `func make...()` | (default) |
| **Resolution** | `get()` | `DependencyContainer.shared.make...()` | `Container.shared.service()` |
| **Injection** | `by inject()` | Constructor | `@Injected(\.service)` |
| **ViewModel** | `viewModel { }` | `func makeViewModel()` | `var viewModel: Factory<VM>` |

## Current State of Your Project

✅ **Implemented:**
- Domain layer protocols (PokemonAPIProvider, PokemonListUseCase)
- Domain layer implementations (DefaultPokemonListUseCase)
- Data layer (PokemonRepository)
- Presentation layer (PokemonListViewModel)
- ViewState enum for state management
- Manual DI Container

⚠️ **Optional Improvements:**
- Add Factory library for type-safe DI
- Add more comprehensive test mocks
- Add Swinject if full-featured DI becomes necessary

## Recommended Next Steps

### Immediate (Current Setup is Fine)
1. Keep using manual DI (DependencyContainer)
2. Add more screens with same pattern
3. Add tests using constructor injection

### When App Grows (5+ screens)
1. Consider adding Factory library
2. Migration is trivial (same API)
3. Just change one file: `Di/ContainerFactory.swift`

### If You Need Advanced Features
1. Add Swinject library
2. Create `Di/SwinjectContainer.swift`
3. More features but more complexity

## Why This Approach Rocks

1. **Familiar Concepts**: If you know Koin, you understand this
2. **Layered Architecture**: Domain → Data → Presentation
3. **Use Cases**: Business logic separated from ViewModels
4. **Testable**: Easy to inject mocks
5. **Type Safe**: Compile-time dependency verification
6. **Flexible**: Can migrate to Factory or Swinject anytime

## Quick Reference

### Create a New Feature

1. **Domain Layer** (`Domain/Models/Feature.swift`)
```swift
protocol FeatureRepository { /* interface */ }
```

2. **Domain UseCases** (`Domain/UseCases/FeatureUseCase.swift`)
```swift
protocol FeatureUseCase { /* interface */ }
class DefaultFeatureUseCase: FeatureUseCase {
    init(repository: FeatureRepository)
}
```

3. **Data Layer** (`Data/Repository/FeatureRepository.swift`)
```swift
class FeatureRepositoryImpl: FeatureRepository {
    init(apiClient: APIClient)
}
```

4. **Register in DI** (`Di/DependencyContainer.swift`)
```swift
private lazy var featureRepository: FeatureRepository = {
    FeatureRepositoryImpl(apiClient: apiClient)
}()
```

5. **Use in ViewModel** (`Presentation/Feature/FeatureViewModel.swift`)
```swift
class FeatureViewModel: ObservableObject {
    init(useCase: FeatureUseCase = 
         DependencyContainer.shared.makeFeatureUseCase())
}
```

## Resources

- **Current Setup**: Based on industry best practices
- **Factory Library**: https://github.com/hmlongco/Factory
- **Swinject Library**: https://github.com/Swinject/Swinject
- **iOS DI Patterns**: https://www.raywenderlich.com/14223279-dependency-injection-tutorial-for-ios-getting-started

Your iOS DI setup is production-ready and follows the exact same principles as your Android Koin setup! 🎉
