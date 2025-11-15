# JSON Serialization: From kotlinx.serialization to Codable

A guide for transitioning from Android's `kotlinx.serialization` to iOS's `Codable` system.

## Quick Comparison

| Feature | kotlinx.serialization | Codable | Notes |
|---------|---|---|---|
| **Default behavior** | Automatic (with @Serializable) | Automatic (with Codable) | Both work out of the box |
| **Custom field names** | `@SerialName("key")` | `CodingKeys` enum | Different syntax, same concept |
| **Nullable fields** | Optional<T> | T? | Same |
| **Default values** | `@SerialName(...) val field: String = ""` | Init default in property | Different approach |
| **Custom serialization** | `@Serializer` classes | Custom encode/decode | More complex |
| **Date handling** | `@Serializable(with = DateSerializer::class)` | Custom strategies | Requires setup |
| **Lists/Arrays** | Automatic | Automatic | Same |
| **Nested objects** | Automatic | Automatic | Same |
| **Performance** | Excellent | Excellent | Both very fast |
| **Library size** | Small dependency | Built-in | Codable is built-in to Swift |

## Side-by-Side Examples

### Example 1: Simple Model

#### Android (kotlinx.serialization)
```kotlin
import kotlinx.serialization.Serializable
import kotlinx.serialization.SerialName

@Serializable
data class Pokemon(
    val id: Int,
    val name: String,
    @SerialName("front_default")
    val imageUrl: String?
)

// JSON
// {"id": 1, "name": "Bulbasaur", "front_default": "..."}

// Usage
val json = Json { ignoreUnknownKeys = true }
val pokemon = json.decodeFromString<Pokemon>(jsonString)
val pokemonJson = json.encodeToString(pokemon)
```

#### iOS (Codable)
```swift
import Foundation

struct Pokemon: Codable {
    let id: Int
    let name: String
    let imageUrl: String?
    
    enum CodingKeys: String, CodingKey {
        case id
        case name
        case imageUrl = "front_default"
    }
}

// JSON
// {"id": 1, "name": "Bulbasaur", "front_default": "..."}

// Usage
let decoder = JSONDecoder()
let pokemon = try decoder.decode(Pokemon.self, from: jsonData)

let encoder = JSONEncoder()
encoder.outputFormatting = .prettyPrinted
let pokemonJson = try encoder.encode(pokemon)
```

### Example 2: Nested Objects

#### Android (kotlinx.serialization)
```kotlin
@Serializable
data class PokemonDetail(
    val id: Int,
    val name: String,
    val sprites: Sprites,
    val types: List<TypeSlot>
)

@Serializable
data class Sprites(
    @SerialName("front_default")
    val frontDefault: String?,
    @SerialName("back_default")
    val backDefault: String?
)

@Serializable
data class TypeSlot(
    val type: TypeInfo
)

@Serializable
data class TypeInfo(
    val name: String
)
```

#### iOS (Codable)
```swift
struct PokemonDetail: Codable {
    let id: Int
    let name: String
    let sprites: Sprites
    let types: [TypeSlot]
}

struct Sprites: Codable {
    let frontDefault: String?
    let backDefault: String?
    
    enum CodingKeys: String, CodingKey {
        case frontDefault = "front_default"
        case backDefault = "back_default"
    }
}

struct TypeSlot: Codable {
    let type: TypeInfo
}

struct TypeInfo: Codable {
    let name: String
}
```

### Example 3: With Default Values

#### Android (kotlinx.serialization)
```kotlin
@Serializable
data class Settings(
    val theme: String = "light",
    val fontSize: Int = 12,
    val notificationsEnabled: Boolean = true
)

// If JSON doesn't have these fields, defaults are used
val json = Json { ignoreUnknownKeys = true }
val settings = json.decodeFromString<Settings>("{}")
// Result: Settings(theme="light", fontSize=12, notificationsEnabled=true)
```

#### iOS (Codable)
```swift
struct Settings: Codable {
    let theme: String
    let fontSize: Int
    let notificationsEnabled: Bool
    
    init(
        theme: String = "light",
        fontSize: Int = 12,
        notificationsEnabled: Bool = true
    ) {
        self.theme = theme
        self.fontSize = fontSize
        self.notificationsEnabled = notificationsEnabled
    }
}

// Usage
let decoder = JSONDecoder()
let settings = try decoder.decode(Settings.self, from: "{}".data(using: .utf8)!)
// Result: Settings(theme="light", fontSize=12, notificationsEnabled=true)
```

### Example 4: Custom Date Formatting

#### Android (kotlinx.serialization)
```kotlin
@Serializable
data class Post(
    val id: Int,
    val title: String,
    @Serializable(with = DateSerializer::class)
    val createdAt: Long // Unix timestamp
)

object DateSerializer : KSerializer<Long> {
    override val descriptor = PrimitiveSerialDescriptor("Date", PrimitiveKind.LONG)
    
    override fun serialize(encoder: Encoder, value: Long) {
        encoder.encodeLong(value)
    }
    
    override fun deserialize(decoder: Decoder): Long {
        return decoder.decodeLong()
    }
}

// JSON
// {"id": 1, "title": "Hello", "createdAt": 1234567890}
```

#### iOS (Codable)
```swift
struct Post: Codable {
    let id: Int
    let title: String
    let createdAt: Date
    
    enum CodingKeys: String, CodingKey {
        case id
        case title
        case createdAt
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(Int.self, forKey: .id)
        title = try container.decode(String.self, forKey: .title)
        
        let timestamp = try container.decode(Int.self, forKey: .createdAt)
        createdAt = Date(timeIntervalSince1970: TimeInterval(timestamp))
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(title, forKey: .title)
        try container.encode(Int(createdAt.timeIntervalSince1970), forKey: .createdAt)
    }
}
```

### Example 5: Ignoring Unknown Keys (API Resilience)

#### Android (kotlinx.serialization)
```kotlin
val json = Json { 
    ignoreUnknownKeys = true  // Ignore extra fields from API
    coerceInputValues = true  // Use defaults for null values
}

val pokemon = json.decodeFromString<Pokemon>(jsonString)
```

#### iOS (Codable)
```swift
let decoder = JSONDecoder()
// Codable automatically ignores unknown keys by default!
// No configuration needed

let pokemon = try decoder.decode(Pokemon.self, from: jsonData)
```

**Key Difference**: iOS's Codable ignores unknown keys by default, while kotlinx.serialization requires explicit configuration!

## Your PokéDex Project - Current JSON Handling

### What You Have Now

Your `Pokemon` models are already using `Codable`:

```swift
struct PokemonListResponse: Codable {
    let count: Int
    let next: String?
    let previous: String?
    let results: [PokemonRef]
}

struct PokemonRef: Codable, Identifiable {
    let name: String
    let url: String
    
    enum CodingKeys: String, CodingKey {
        case name
        case url
    }
}
```

This is the iOS equivalent of:

```kotlin
@Serializable
data class PokemonListResponse(
    val count: Int,
    val next: String?,
    val previous: String?,
    val results: List<PokemonRef>
)

@Serializable
data class PokemonRef(
    val name: String,
    val url: String
)
```

### How It's Used in Your APIClient

```swift
actor APIClient {
    func fetch<T: Decodable>(_ endpoint: String) async throws -> T {
        let (data, response) = try await session.data(from: url)
        
        let decoder = JSONDecoder()
        return try decoder.decode(T.self, from: data)  // ← Automatic deserialization
    }
}

// Usage - generic type inference!
let response: PokemonListResponse = try await apiClient.fetch("/pokemon?limit=20")
```

This is equivalent to Android's:

```kotlin
val json = Json { ignoreUnknownKeys = true }
val response: PokemonListResponse = json.decodeFromString(responseString)
```

## If You Need Advanced Serialization

### Scenario 1: Snake Case to Camel Case

#### Android (kotlinx.serialization)
```kotlin
val json = Json {
    namingStrategy = JsonNamingStrategy.SnakeCase
}

@Serializable
data class UserProfile(
    val firstName: String,
    val lastName: String
)
// Automatically maps: "first_name" ↔ firstName
```

#### iOS (Codable with Custom Strategy)
```swift
struct UserProfile: Codable {
    let firstName: String
    let lastName: String
    
    enum CodingKeys: String, CodingKey {
        case firstName = "first_name"
        case lastName = "last_name"
    }
}
// Manually map: "first_name" ↔ firstName
```

Or use a helper extension:

```swift
extension JSONDecoder {
    static let snakeCase: JSONDecoder = {
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        return decoder
    }()
}

// Usage
let profile = try JSONDecoder.snakeCase.decode(UserProfile.self, from: data)
```

### Scenario 2: Polymorphic Types

#### Android (kotlinx.serialization)
```kotlin
@Serializable
sealed class Event {
    @SerialName("login")
    @Serializable
    data class LoginEvent(val userId: Int) : Event()
    
    @SerialName("logout")
    @Serializable
    data class LogoutEvent(val userId: Int) : Event()
}

val event: Event = json.decodeFromString(eventJson)
```

#### iOS (Codable with Manual Dispatch)
```swift
enum Event: Codable {
    case login(userId: Int)
    case logout(userId: Int)
    
    enum CodingKeys: String, CodingKey {
        case type
        case userId
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let type = try container.decode(String.self, forKey: .type)
        let userId = try container.decode(Int.self, forKey: .userId)
        
        switch type {
        case "login":
            self = .login(userId: userId)
        case "logout":
            self = .logout(userId: userId)
        default:
            throw DecodingError.dataCorrupted(
                DecodingError.Context(codingPath: [], debugDescription: "Unknown type")
            )
        }
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        switch self {
        case .login(let userId):
            try container.encode("login", forKey: .type)
            try container.encode(userId, forKey: .userId)
        case .logout(let userId):
            try container.encode("logout", forKey: .type)
            try container.encode(userId, forKey: .userId)
        }
    }
}
```

## Best Practices

### ✅ Do This

```swift
// Use Codable for all API models
struct ApiResponse: Codable { }

// Use CodingKeys for field mapping
enum CodingKeys: String, CodingKey {
    case userId = "user_id"
}

// Use custom init only when necessary
init(from decoder: Decoder) throws { }

// Make models Identifiable if needed
struct User: Codable, Identifiable { }

// Use Decodable only for requests, Codable for responses
struct GetUserRequest: Encodable { }
struct GetUserResponse: Decodable { }
```

### ❌ Don't Do This

```swift
// Don't manually parse JSON
let userId = (json["user"] as? [String: Any])?["id"] as? Int

// Don't mix Codable with manual parsing
init(from decoder: Decoder) throws {
    // Don't do JSON manipulation here
}

// Don't forget CodingKeys for snake_case fields
struct User: Codable {
    let userId: Int  // Won't map to "user_id" without CodingKeys!
}
```

## Migration Checklist

If you're bringing models from Android:

- [ ] Identify all `@Serializable` classes
- [ ] Convert to Swift `struct` with `Codable`
- [ ] Add `enum CodingKeys` for any `@SerialName` fields
- [ ] Test with real API responses
- [ ] Add error handling around `decode()`

Your PokéDex project is already following iOS best practices! ✅

## Resources

- **Codable Documentation**: https://developer.apple.com/documentation/foundation/codable
- **JSONDecoder/JSONEncoder**: https://developer.apple.com/documentation/foundation/jsondecoder
- **Codable Handbook**: https://www.kodeco.com/3846438-encoding-and-decoding-in-swift
- **Advanced Codable**: https://www.swiftbysundell.com/posts/encoding-and-decoding-custom-types-in-swift

## Summary

| Aspect | Android | iOS | Complexity |
|--------|---------|-----|-----------|
| **Basic serialization** | @Serializable | Codable | ✅ Same |
| **Field mapping** | @SerialName | CodingKeys | ✅ Same |
| **Default values** | Default params | Init defaults | ⚠️ iOS is different |
| **Custom logic** | @Serializer | Custom encode/decode | ❌ iOS is more verbose |
| **Out of the box** | Excellent | Excellent | ✅ Both great |
| **Performance** | Excellent | Excellent | ✅ Both excellent |

Your iOS app is already handling JSON serialization perfectly with Codable! No need for external libraries. 🎉
