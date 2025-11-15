# iOS Development Patterns & Examples for Android Developers

A practical guide with side-by-side code examples showing how Android patterns map to iOS.

## 1. State Management: MVI State vs iOS State

### Android (MVI Pattern)
```kotlin
// State class (sealed class)
sealed class PokemonListState {
    object Loading : PokemonListState()
    data class Success(val pokemon: List<Pokemon>) : PokemonListState()
    data class Error(val message: String) : PokemonListState()
}

// ViewModel
class PokemonListViewModel : ViewModel() {
    private val _state = MutableStateFlow<PokemonListState>(PokemonListState.Loading)
    val state: StateFlow<PokemonListState> = _state.asStateFlow()
    
    init {
        viewModelScope.launch {
            _state.value = try {
                val pokemon = repository.fetchPokemon()
                PokemonListState.Success(pokemon)
            } catch (e: Exception) {
                PokemonListState.Error(e.message ?: "Unknown error")
            }
        }
    }
}
```

### iOS (MVVM Pattern)
```swift
// ViewState enum (exactly the same concept!)
enum ViewState<T> {
    case loading
    case success(T)
    case error(String)
}

// ViewModel
class PokemonListViewModel: ObservableObject {
    @Published var viewState: ViewState<[Pokemon]> = .loading
    private let repository: PokemonAPIProvider
    
    init(repository: PokemonAPIProvider = PokemonRepository()) {
        self.repository = repository
    }
    
    func loadPokemonList() async {
        viewState = .loading
        do {
            let pokemon = try await repository.fetchPokemonList(limit: 250, offset: 0)
            viewState = .success(pokemon)
        } catch {
            viewState = .error(error.localizedDescription)
        }
    }
}
```

**Key Insight**: iOS `@Published` is the equivalent of Kotlin `MutableStateFlow`. Both notify observers when state changes!

---

## 2. Async Operations: Coroutines vs async/await

### Android (Coroutines)
```kotlin
// Coroutines with Flow
fun getPokemonList(): Flow<List<Pokemon>> = flow {
    try {
        val pokemon = apiClient.fetchPokemon()
        emit(pokemon)
    } catch (e: Exception) {
        // Handle error
    }
}

// Usage in ViewModel
init {
    viewModelScope.launch {
        repository.getPokemonList().collect { pokemon ->
            _state.value = PokemonListState.Success(pokemon)
        }
    }
}

// Or with suspend functions
suspend fun fetchPokemon(): List<Pokemon> {
    return withContext(Dispatchers.IO) {
        apiClient.fetchPokemon()
    }
}
```

### iOS (async/await)
```swift
// Async function (like suspend functions in Kotlin)
func fetchPokemonList() async throws -> [Pokemon] {
    let endpoint = "/pokemon?limit=250&offset=0"
    let response: PokemonListResponse = try await apiClient.fetch(endpoint)
    return response.results.map { Pokemon(from: $0) }
}

// Usage in ViewModel
func loadPokemonList() async {
    viewState = .loading
    do {
        let pokemon = try await repository.fetchPokemonList(limit: 250, offset: 0)
        viewState = .success(pokemon)
    } catch {
        viewState = .error(error.localizedDescription)
    }
}

// Usage in View
.task {
    await viewModel.loadPokemonList()
}
```

**Key Insight**: iOS `async/await` is very similar to Kotlin `suspend` functions! Both are designed for non-blocking operations.

---

## 3. Observable Updates: LiveData/StateFlow vs @Published

### Android (LiveData)
```kotlin
class UserViewModel : ViewModel() {
    private val _user = MutableLiveData<User>()
    val user: LiveData<User> = _user
    
    fun loadUser() {
        viewModelScope.launch {
            _user.value = repository.fetchUser()
        }
    }
}

// In Fragment/Activity
viewModel.user.observe(viewLifecycleOwner) { user ->
    // Update UI
}
```

### iOS (@Published)
```swift
class UserViewModel: ObservableObject {
    @Published var user: User?
    
    func loadUser() async {
        do {
            user = try await repository.fetchUser()
        } catch {
            // Handle error
        }
    }
}

// In SwiftUI View
@StateObject private var viewModel = UserViewModel()

var body: some View {
    // SwiftUI automatically re-renders when viewModel.user changes
    if let user = viewModel.user {
        Text(user.name)
    }
}
```

**Key Insight**: `@Published` is like `LiveData`. Both notify the UI layer when data changes, and the UI automatically updates.

---

## 4. Dependency Injection

### Android (Hilt)
```kotlin
// Module
@Module
@InstallIn(SingletonComponent::class)
object RepositoryModule {
    @Provides
    @Singleton
    fun providePokemonRepository(apiClient: APIClient): PokemonRepository {
        return PokemonRepository(apiClient)
    }
}

// Usage
class PokemonListViewModel @Inject constructor(
    private val repository: PokemonRepository
) : ViewModel()
```

### iOS (Manual + Environment)
```swift
// Simple dependency container
class DependencyContainer {
    static let shared = DependencyContainer()
    
    lazy var apiClient: APIClient = {
        APIClient()
    }()
    
    lazy var pokemonRepository: PokemonRepository = {
        PokemonRepository(apiClient: apiClient)
    }()
}

// Usage in ViewModel
class PokemonListViewModel: ObservableObject {
    private let repository: PokemonAPIProvider
    
    init(repository: PokemonAPIProvider = DependencyContainer.shared.pokemonRepository) {
        self.repository = repository
    }
}

// Or pass via @EnvironmentObject
@main
struct PokeDexApp: App {
    var body: some Scene {
        WindowGroup {
            PokemonListView()
                .environmentObject(DependencyContainer.shared.pokemonRepository as! PokemonRepository)
        }
    }
}
```

**Key Insight**: iOS doesn't have an out-of-the-box DI framework like Hilt. Use manual dependency containers or SwiftUI's `@EnvironmentObject`.

---

## 5. JSON Serialization: data class vs Codable

### Android (Kotlin)
```kotlin
// Automatic JSON serialization with kotlinx.serialization or Gson
@Serializable
data class Pokemon(
    val id: Int,
    val name: String,
    @SerialName("front_default")
    val imageUrl: String
)

// Usage
val json = """{"id": 1, "name": "Bulbasaur", "front_default": "..."}"""
val pokemon = Json.decodeFromString<Pokemon>(json)
```

### iOS (Codable)
```swift
// Built-in automatic JSON serialization
struct Pokemon: Codable {
    let id: Int
    let name: String
    let frontDefault: String?
    
    enum CodingKeys: String, CodingKey {
        case id
        case name
        case frontDefault = "front_default"  // Maps JSON key to property
    }
}

// Usage
let json = """{"id": 1, "name": "Bulbasaur", "front_default": "..."}"""
let decoder = JSONDecoder()
let pokemon = try decoder.decode(Pokemon.self, from: json.data(using: .utf8)!)
```

**Key Insight**: Both `Codable` and Kotlin `data class` with serialization provide automatic JSON parsing. `CodingKeys` in Swift is like `@SerialName` in Kotlin.

---

## 6. HTTP Clients: Ktor vs URLSession

### Android (Ktor)
```kotlin
val httpClient = HttpClient {
    install(JsonFeature) {
        serializer = KotlinxSerializer()
    }
}

val response: PokemonListResponse = httpClient.get("https://pokeapi.co/api/v2/pokemon") {
    parameter("limit", 20)
}
```

### iOS (URLSession)
```swift
// Custom APIClient wrapper (like a lightweight version of Ktor)
actor APIClient {
    private let session: URLSession
    
    func fetch<T: Decodable>(_ endpoint: String) async throws -> T {
        guard let url = URL(string: endpoint) else {
            throw APIError.invalidURL
        }
        
        let (data, response) = try await session.data(from: url)
        
        guard let httpResponse = response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode) else {
            throw APIError.serverError
        }
        
        return try JSONDecoder().decode(T.self, from: data)
    }
}

// Usage
let response: PokemonListResponse = try await apiClient.fetch("/pokemon?limit=20")
```

**Key Insight**: iOS `URLSession` is simpler than Ktor but less feature-rich. The `APIClient` wrapper provides similar abstraction.

---

## 7. UI: Compose vs SwiftUI

### Android (Compose)
```kotlin
@Composable
fun PokemonListScreen(viewModel: PokemonListViewModel) {
    val state by viewModel.state.collectAsState()
    
    Column {
        SearchBar(onSearch = { query ->
            viewModel.search(query)
        })
        
        when (state) {
            is PokemonListState.Loading -> CircularProgressIndicator()
            is PokemonListState.Success -> {
                LazyVerticalGrid(columns = GridCells.Fixed(2)) {
                    items((state as PokemonListState.Success).pokemon) { pokemon ->
                        PokemonCard(pokemon)
                    }
                }
            }
            is PokemonListState.Error -> {
                Text((state as PokemonListState.Error).message)
            }
        }
    }
}

@Composable
fun PokemonCard(pokemon: Pokemon) {
    Card {
        Column {
            Image(painter = rememberImagePainter(pokemon.imageUrl), contentDescription = null)
            Text(pokemon.name)
            Text("#${pokemon.id}")
        }
    }
}
```

### iOS (SwiftUI)
```swift
struct PokemonListView: View {
    @StateObject private var viewModel = PokemonListViewModel()
    
    var body: some View {
        VStack {
            SearchBar(text: $viewModel.searchQuery)
            
            ZStack {
                if viewModel.viewState.isLoading {
                    ProgressView()
                } else if let errorMessage = viewModel.viewState.errorMessage {
                    Text(errorMessage)
                } else if let pokemon = viewModel.viewState.value {
                    ScrollView {
                        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())]) {
                            ForEach(pokemon) { poke in
                                PokemonCardView(pokemon: poke)
                            }
                        }
                    }
                }
            }
        }
    }
}

struct PokemonCardView: View {
    let pokemon: Pokemon
    
    var body: some View {
        VStack {
            AsyncImage(url: URL(string: pokemon.imageUrl))
            Text(pokemon.name)
            Text("#\(String(format: "%03d", pokemon.number))")
        }
        .cornerRadius(12)
    }
}
```

**Key Insight**: SwiftUI and Compose are virtually identical! Both use:
- Declarative syntax
- State management
- Automatic re-renders when state changes
- Composable components

---

## 8. Testing: Unit Tests

### Android (JUnit + Mockito)
```kotlin
class PokemonListViewModelTest {
    @get:Rule
    val instantExecutorRule = InstantTaskExecutorRule()
    
    private val mockRepository = mockk<PokemonRepository>()
    private lateinit var viewModel: PokemonListViewModel
    
    @Before
    fun setup() {
        viewModel = PokemonListViewModel(mockRepository)
    }
    
    @Test
    fun `test loading state`() = runTest {
        // Given
        coEvery { mockRepository.fetchPokemon() } returns listOf(
            Pokemon(1, "Bulbasaur", "...")
        )
        
        // When
        viewModel.loadPokemon()
        advanceUntilIdle()
        
        // Then
        assertEquals(
            PokemonListState.Success(listOf(Pokemon(1, "Bulbasaur", "..."))),
            viewModel.state.value
        )
    }
}
```

### iOS (XCTest)
```swift
class PokemonListViewModelTests: XCTestCase {
    var viewModel: PokemonListViewModel!
    var mockRepository: MockPokemonRepository!
    
    override func setUp() {
        super.setUp()
        mockRepository = MockPokemonRepository()
        viewModel = PokemonListViewModel(repository: mockRepository)
    }
    
    func testLoadingState() async {
        // Given
        let expectedPokemon = [Pokemon(id: "bulbasaur", name: "Bulbasaur", number: 1, imageUrl: "...", types: [])]
        mockRepository.mockPokemon = expectedPokemon
        
        // When
        await viewModel.loadPokemonList()
        
        // Then
        if case .success(let pokemon) = viewModel.viewState {
            XCTAssertEqual(pokemon, expectedPokemon)
        } else {
            XCTFail("Expected success state")
        }
    }
}

class MockPokemonRepository: PokemonAPIProvider {
    var mockPokemon: [Pokemon] = []
    
    func fetchPokemonList(limit: Int, offset: Int) async throws -> [Pokemon] {
        return mockPokemon
    }
    
    func searchPokemon(query: String) async throws -> [Pokemon] {
        return mockPokemon.filter { $0.name.contains(query) }
    }
}
```

**Key Insight**: iOS testing is similar to Android. Create mocks, set expectations, then verify behavior.

---

## 9. Error Handling

### Android (try-catch + sealed classes)
```kotlin
sealed class Result<T> {
    data class Success<T>(val data: T) : Result<T>()
    data class Error<T>(val exception: Exception) : Result<T>()
}

fun getPokemon(): Result<List<Pokemon>> {
    return try {
        val pokemon = repository.fetch()
        Result.Success(pokemon)
    } catch (e: IOException) {
        Result.Error(e)
    } catch (e: SerializationException) {
        Result.Error(e)
    }
}
```

### iOS (throws + do-catch)
```swift
enum APIError: LocalizedError {
    case networkError(Error)
    case decodingError(Error)
    case serverError(Int)
}

func getPokemon() async throws -> [Pokemon] {
    do {
        let (data, response) = try await URLSession.shared.data(from: url)
        
        guard let httpResponse = response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode) else {
            throw APIError.serverError(200)
        }
        
        let pokemon = try JSONDecoder().decode([Pokemon].self, from: data)
        return pokemon
    } catch let error as DecodingError {
        throw APIError.decodingError(error)
    } catch {
        throw APIError.networkError(error)
    }
}
```

**Key Insight**: Both languages handle errors similarly—custom error types + try-catch. Swift's `throws` keyword is like Kotlin's exception throwing.

---

## 10. Threading: Dispatchers vs MainActor

### Android (Coroutine Dispatchers)
```kotlin
// Main thread
viewModelScope.launch(Dispatchers.Main) {
    // UI updates here
}

// IO thread
viewModelScope.launch(Dispatchers.IO) {
    val data = repository.fetchData()  // Network call
    // Update UI on main thread
    withContext(Dispatchers.Main) {
        _state.value = Success(data)
    }
}
```

### iOS (MainActor)
```swift
// Automatically on main thread
@MainActor
class PokemonListViewModel: ObservableObject {
    @Published var viewState: ViewState<[Pokemon]> = .idle
    
    func loadPokemonList() async {
        viewState = .loading
        
        // Network call (automatically on background)
        do {
            let pokemon = try await repository.fetchPokemonList(limit: 250, offset: 0)
            // Automatically back on main thread
            viewState = .success(pokemon)
        } catch {
            viewState = .error(error.localizedDescription)
        }
    }
}
```

**Key Insight**: iOS `@MainActor` is simpler than Android's `Dispatchers`—it automatically handles main thread updates. `async/await` automatically switches threads as needed.

---

## Quick Reference Table

| Operation | Android | iOS |
|-----------|---------|-----|
| **State Management** | `MutableStateFlow`/`MutableLiveData` | `@Published` |
| **Observable State** | `StateFlow<T>` | `@Published var: T` |
| **Async Operations** | `suspend fun` + coroutines | `async/await` |
| **State Machine** | `sealed class` | `enum` |
| **Serialization** | `@Serializable`/`@SerialName` | `Codable`/`CodingKeys` |
| **HTTP Client** | Ktor/Retrofit | URLSession |
| **UI Framework** | Compose | SwiftUI |
| **Threading** | Dispatchers | MainActor |
| **DI** | Hilt | Manual containers |
| **Testing** | JUnit/Mockito | XCTest |
| **List Layout** | `LazyVerticalGrid` | `LazyVGrid` |
| **Images** | `rememberImagePainter` | `AsyncImage` |

---

## Summary

If you understand Android development, iOS will feel very natural:
- Same architectural patterns (MVI → MVVM is a rename!)
- Similar concurrency models (coroutines → async/await)
- Same reactive principles (Flow → @Published)
- Similar testing approaches
- Nearly identical UI paradigms (Compose → SwiftUI)

The main differences are syntax and library names, not concepts!
