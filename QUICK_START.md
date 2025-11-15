# PokéDex iOS App - Quick Start Guide

## What's Been Implemented ✅

Your new PokéDex app now has:

### ✨ Features
- **Pokémon List Screen** with a beautiful 2-column grid layout
- **Search Bar** at the top to filter Pokémon by name or number
- **Pokémon Cards** displaying:
  - Official Pokémon image
  - Pokémon name (capitalized)
  - Pokémon number (#001, #002, etc.)
- **Loading State** with spinner while fetching data
- **Error State** with retry button if something goes wrong
- **Empty State** when search returns no results

### 🏗️ Architecture (Similar to your Android MVI)

```
┌─────────────────────────────────────────────────┐
│            PokemonListView (UI)                 │
│    - Displays cards in 2-column grid            │
│    - Shows search bar & loading/error states    │
└──────────────────┬──────────────────────────────┘
                   │ Observes @StateObject
                   ↓
┌─────────────────────────────────────────────────┐
│      PokemonListViewModel (State)               │
│ @Published viewState: ViewState<[Pokemon]>     │
│ - Calls repository for data                     │
│ - Manages filtering/search logic                │
│ - Updates @Published properties                 │
└──────────────────┬──────────────────────────────┘
                   │ Uses
                   ↓
┌─────────────────────────────────────────────────┐
│    PokemonRepository (Data Abstraction)         │
│ - Fetches from network                          │
│ - Transforms API responses to domain models     │
└──────────────────┬──────────────────────────────┘
                   │ Uses
                   ↓
┌─────────────────────────────────────────────────┐
│       APIClient (HTTP Wrapper)                  │
│ - Generic fetch<T: Decodable>() method          │
│ - Uses URLSession under the hood                │
│ - Error handling with custom APIError enum      │
└─────────────────────────────────────────────────┘
```

## Project Structure 📁

```
PokeDex/
├── Domain/
│   └── Models/
│       └── Pokemon.swift              # Domain models, API models, ViewState
│
├── Data/
│   ├── Network/
│   │   └── APIClient.swift           # HTTP wrapper (like Retrofit)
│   └── Repository/
│       └── PokemonRepository.swift    # Data abstraction layer
│
├── Presentation/
│   ├── Common/
│   │   └── ViewState.swift           # Loading/Success/Error/Idle states
│   └── PokemonList/
│       ├── PokemonListView.swift       # Main UI (SwiftUI)
│       ├── PokemonCardView.swift       # Individual card component
│       └── PokemonListViewModel.swift  # State management (like ViewModel)
│
└── PokeDexApp.swift                   # App entry point
```

## Key iOS Concepts (Android Mapping)

| Android | iOS | What It Does |
|---------|-----|---|
| `ViewModel` + `LiveData` | `@StateObject` + `@Published` | Manages state and notifies UI of changes |
| `Flow<State>` | `@Published` | Observable state property |
| `Coroutines` | `async/await` + `Task` | Non-blocking async operations |
| `Retrofit` | `URLSession` | HTTP client |
| `data class` + JSON serialization | `Codable` struct | Type-safe JSON parsing |
| `Repository pattern` | `Repository pattern` | Single source of truth for data |
| `Compose @Composable` | `SwiftUI View` | Declarative UI components |
| `LazyColumn` with `items()` | `ScrollView` + `LazyVGrid` | Efficient list rendering |

## How to Build & Run 🚀

### In Xcode:
1. Open `PokeDex.xcodeproj`
2. Select the `PokeDex` scheme
3. Choose an iPhone simulator
4. Press **▶️ Run** or `Cmd+R`

### From Terminal:
```bash
cd /Users/razvanbarbu/XcodeProjects/hypnozee/PokeDex
xcodebuild build -scheme PokeDex
```

## The Data Flow (How Your App Works) 🔄

### When the App Launches:

1. **Initialization**
   - `PokemonListView` appears
   - `PokemonListViewModel` is created (via `@StateObject`)
   - `.task` modifier triggers `loadPokemonList()`

2. **Loading State**
   - ViewModel changes `viewState` to `.loading`
   - UI shows spinner
   - Calls `repository.fetchPokemonList(limit: 250, offset: 0)`

3. **API Call**
   - `PokemonRepository` calls `apiClient.fetch<PokemonListResponse>("/pokemon?limit=250&offset=0")`
   - APIClient makes HTTPS request to `https://pokeapi.co/api/v2/pokemon?limit=250&offset=0`
   - Response is decoded from JSON using `Codable`

4. **Transform & Display**
   - Results are mapped from `PokemonRef` (API model) to `Pokemon` (domain model)
   - ViewModel updates `@Published viewState` to `.success([Pokemon])`
   - SwiftUI automatically re-renders with the new data
   - 2-column grid shows all 250 Pokémon

### When User Searches:

1. User types in search bar
2. `SearchBar` binding updates `viewModel.searchQuery`
3. `.onChange` modifier detects change
4. ViewModel calls `filterPokemon(by: query)`
5. Filters the cached `allPokemon` array locally
6. Updates `@Published viewState` 
7. UI automatically re-renders with filtered results

### If Something Goes Wrong:

1. Network error occurs
2. ViewModel catches exception
3. Updates `viewState` to `.error("error message")`
4. UI shows error screen with retry button
5. User can tap retry, which calls `retryLoad()`

## Android Developer Notes 🔍

**Coming from Android MVI/Compose, you'll recognize:**

- **Unidirectional data flow**: Just like MVI! Actions → State → UI
- **Observable state**: `@Published` is like `Flow<State>` or `LiveData`
- **Reactive UI**: SwiftUI automatically re-renders when state changes
- **Type-safe networking**: `Codable` is like Kotlin data classes with automatic JSON serialization
- **Async operations**: `async/await` is very similar to Kotlin coroutines
- **Repository pattern**: Same concept for data abstraction

**Key differences:**

- iOS uses `@MainActor` for thread-safety (instead of Dispatchers.Main)
- SwiftUI views are value types (unlike Compose's lambdas)
- No XML layouts—everything is declarative in Swift
- `URLSession` is built-in (no need for Ktor client library)

## Next Steps: Extending the App 🛠️

### 1. Add Detail Screen
Create a detail view that shows full Pokémon stats:
```swift
// New files to create:
// Presentation/PokemonDetail/PokemonDetailViewModel.swift
// Presentation/PokemonDetail/PokemonDetailView.swift

// Then navigate from PokemonCardView:
NavigationLink(destination: PokemonDetailView(pokemon: pokemon)) {
    PokemonCardView(pokemon: pokemon)
}
```

### 2. Add Local Caching
Cache Pokémon data so it loads instantly on app restart:
```swift
// New files to create:
// Data/Local/PokemonCache.swift (using UserDefaults or SwiftData)

// Update PokemonRepository to check cache before network
```

### 3. Implement Pagination
Load Pokémon in batches for better performance:
```swift
// Add to ViewModel:
@Published var offset: Int = 0

// Modify loadPokemonList to accept offset parameter
// Add onAppear to PokemonCardView to load more when at end of list
```

### 4. Add Unit Tests
Test your ViewModels and Repository:
```swift
// New files:
// PokeDexTests/PokemonListViewModelTests.swift
// PokeDexTests/PokemonRepositoryTests.swift

// Mock the repository in tests
```

### 5. Improve Image Loading
Use `Kingfisher` library for better image caching:
```swift
// Terminal: Add to Package Dependencies in Xcode
// Or manually: https://github.com/onevcat/Kingfisher
```

## Troubleshooting 🐛

**App crashes on launch?**
- Make sure you have internet connection (needs to fetch from PokéAPI)
- Check Xcode console for error messages

**Search isn't working?**
- Make sure you've typed in the search box
- Try searching for a number (like "1" for Bulbasaur)

**Images not showing?**
- Network connection issue
- Or PokéAPI is temporarily down
- Check the error message and retry

**Build fails?**
- Make sure Xcode version is 15.0 or later
- Run `xcodebuild clean` and rebuild

## Resources 📚

- **PokéAPI Docs**: https://pokeapi.co/docs/v2
- **SwiftUI Documentation**: https://developer.apple.com/tutorials/swiftui/
- **Swift Concurrency (async/await)**: https://developer.apple.com/videos/play/wwdc2021/10132/
- **MVVM in Swift**: https://www.hackingwithswift.com/articles/196/what-is-mvvm
- **URLSession**: https://developer.apple.com/documentation/foundation/urlsession

## File Details 📝

### `Domain/Models/Pokemon.swift`
- `PokemonListResponse`: Matches PokéAPI response structure (Codable)
- `PokemonRef`: Individual Pokémon reference from API
- `Pokemon`: Clean domain model for the UI
- `ViewState<T>`: Enum for managing UI state (Loading/Success/Error/Idle)

### `Data/Network/APIClient.swift`
- Generic `fetch<T: Decodable>()` method
- Handles HTTP requests and JSON decoding
- Custom error handling with `APIError` enum
- Thread-safe with `actor` keyword

### `Data/Repository/PokemonRepository.swift`
- Implements `PokemonAPIProvider` protocol
- Abstracts network calls from UI layer
- Transforms API models to domain models
- Handles search/filtering logic

### `Presentation/PokemonList/PokemonListViewModel.swift`
- `@MainActor` for thread-safety
- `@Published` properties for observable state
- `loadPokemonList()`: Fetches all Pokémon
- `filterPokemon(by:)`: Filters based on search query
- `retryLoad()`: Retry failed requests

### `Presentation/PokemonList/PokemonListView.swift`
- Main UI using SwiftUI
- SearchBar component with real-time filtering
- Handles loading, error, success, and empty states
- LazyVGrid with 2 columns for Pokémon display
- Automatically loads data on view appearance

### `Presentation/PokemonList/PokemonCardView.swift`
- Reusable card component
- Displays Pokémon image (AsyncImage for lazy loading)
- Shows name and number
- Beautiful shadow and rounded corners

## Have Questions? 💡

This architecture is designed to feel familiar to Android developers:
- If you've used MVI in Android, you'll understand the data flow
- If you've used Compose, SwiftUI will feel natural
- If you've used Coroutines, async/await is very similar

The key principle: **Data flows one direction: Repository → ViewModel → UI**

Just like your Android app! Good luck! 🚀
