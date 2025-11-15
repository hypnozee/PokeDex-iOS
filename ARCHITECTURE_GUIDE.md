# PokéDex iOS App - Architecture Guide

## Overview
This iOS app follows a modern **MVVM + Repository Pattern** architecture, specifically designed for developers transitioning from Android with MVI experience. It uses SwiftUI, async/await, and unidirectional data flow.

---

## Architecture Layers

### 1. **Domain Layer** (`Domain/`)
**Purpose**: Contains business logic and data models independent of frameworks.

- **Models** (`Domain/Models/Pokemon.swift`)
  - `Pokemon`: Clean domain model representing a Pokémon
  - `PokemonListResponse`, `PokemonRef`: API response models (Codable)
  - Only used for UI presentation and type safety

**Key Concept**: Domain models are separate from API models for flexibility (API changes don't break the domain).

---

### 2. **Data Layer** (`Data/`)
**Purpose**: Handles all data operations (networking, caching, persistence).

#### 2a. Network (`Data/Network/APIClient.swift`)
- **APIClient**: Generic HTTP wrapper around URLSession (like Retrofit on Android)
- Uses Swift's `async/await` for non-blocking operations
- Handles errors with `APIError` enum
- Acts as an actor for thread-safe operations

**Key Concept**: The `fetch<T: Decodable>` generic method is similar to Ktor's type-safe requests.

```swift
// Usage example:
let response: PokemonListResponse = try await apiClient.fetch("/pokemon?limit=20")
```

#### 2b. Repository (`Data/Repository/PokemonRepository.swift`)
- **PokemonRepository**: Implements `PokemonAPIProvider` protocol
- Abstracts network calls from the presentation layer
- Handles data transformations (API models → Domain models)
- Implements filtering logic for search

**Key Concept**: Like Android's Repository pattern, it's a single source of truth for data.

---

### 3. **Presentation Layer** (`Presentation/`)
**Purpose**: UI logic, state management, and SwiftUI views.

#### 3a. State Management (`Presentation/Common/ViewState.swift`)
- **ViewState<T>** enum (similar to Android's sealed class):
  - `.idle`: Initial state
  - `.loading`: Loading state
  - `.success(T)`: Data successfully loaded
  - `.error(String)`: Error occurred
  
**Key Concept**: This is similar to Android's state classes with MVI pattern—unidirectional data flow!

#### 3b. ViewModels (`Presentation/PokemonList/PokemonListViewModel.swift`)
- **PokemonListViewModel**: `@MainActor` class with `@Published` properties
- Manages UI state and user interactions
- Calls repository for data
- Updates `@Published` properties → SwiftUI automatically re-renders

**Key Concepts**:
- `@MainActor`: Ensures all UI updates happen on the main thread
- `@Published`: Like Android's `StateFlow` or `LiveData`
- `async/await`: Like Kotlin coroutines for non-blocking operations

#### 3c. Views (`Presentation/PokemonList/PokemonListView.swift`)
- **PokemonListView**: Main list screen with search, loading, error, and empty states
- **PokemonCardView**: Reusable card component displaying individual Pokémon
- **SearchBar**: Custom search component

**Key Concepts**:
- Declarative UI (like Jetpack Compose)
- `@StateObject`: Creates and retains ViewModel for lifecycle
- `onChange`: Reactive to state changes (like observers in MVI)
- `LazyVGrid`: Grid layout for 2-column Pokémon cards

---

## Data Flow (Unidirectional, like MVI)

```
User Action (e.g., search input)
    ↓
PokemonListView emits onChange event
    ↓
PokemonListViewModel.filterPokemon(query)
    ↓
ViewModel updates @Published viewState property
    ↓
SwiftUI observes change via @StateObject
    ↓
View re-renders with new state
```

**Comparison to Android MVI**:
| Android MVI | iOS MVVM |
|---|---|
| Intent | User action in View |
| ViewModel processes | ViewModel processes |
| State emission | @Published property |
| StateFlow observation | SwiftUI observes @Published |
| View renders | View automatically re-renders |

---

## How to Extend This Architecture

### Adding a Detail Screen
1. Create `DetailViewModel` with navigation ID
2. Add `DetailView` with `@StateObject` 
3. Add route to `AppCoordinator` (when implemented)
4. Use `NavigationStack` for type-safe navigation

### Adding Local Caching
1. Create `PokemonCache` in `Data/Local/`
2. Update `PokemonRepository` to check cache before network
3. Use Swift's `UserDefaults` or `SwiftData` for persistence

### Implementing Pagination
1. Add `offset` parameter to `PokemonListViewModel`
2. Add pagination logic to detect when user scrolls to end
3. Load next batch of Pokémon

---

## Key iOS Concepts for Android Developers

| Android | iOS | Explanation |
|---|---|---|
| **Coroutines** | **async/await** | Non-blocking async operations |
| **Flow<State>** | **@Published** | Reactive state that triggers recomposition |
| **LiveData** | **@StateObject** | State holder for Views |
| **Compose @Composable** | **View** | Declarative UI component |
| **remember** | **@State** | Local state within view |
| **ViewModel** | **ObservableObject** | Lifecycle-aware state management |
| **Hilt DI** | **@EnvironmentObject** | Dependency injection in SwiftUI |
| **Retrofit** | **URLSession/APIClient** | HTTP client |
| **Kotlin data class** | **Codable struct** | Automatic JSON serialization |

---

## Testing Strategy

### Unit Tests
- Test `ViewModel` logic independently with mock repository
- Test `Repository` error handling

### Integration Tests
- Mock `APIClient` responses
- Test full flow: Repository → ViewModel → View state

### UI Tests
- Test loading, error, success, and empty states
- Test search filtering

---

## Performance Considerations

1. **Image Loading**: Uses `AsyncImage` for lazy loading
2. **Grid Rendering**: `LazyVGrid` with `ForEach` renders efficiently
3. **Search**: Filters locally (consider pagination for large datasets)
4. **Memory**: `@StateObject` creates single instance per view lifetime

---

## Next Steps for Feature Development

1. **Implement AppCoordinator** for navigation
2. **Add Detail Screen** showing full Pokémon stats
3. **Add Favorites** with local storage
4. **Implement Pagination** for smoother scrolling
5. **Add Error Recovery** with retry logic
6. **Add Unit Tests** with mock repository

---

## File Structure Summary

```
PokeDex/
├── Domain/
│   └── Models/
│       └── Pokemon.swift          # Data models & ViewState
├── Data/
│   ├── Network/
│   │   └── APIClient.swift       # HTTP client wrapper
│   └── Repository/
│       └── PokemonRepository.swift # Data abstraction layer
├── Presentation/
│   ├── Common/
│   │   └── ViewState.swift       # State enum
│   └── PokemonList/
│       ├── PokemonListView.swift       # Main UI
│       ├── PokemonCardView.swift       # Card component
│       └── PokemonListViewModel.swift  # State management
└── PokeDexApp.swift             # App entry point
```

This architecture is scalable, testable, and follows iOS best practices while leveraging your Android expertise!
