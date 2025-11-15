import Foundation

class PokemonRepository: PokemonAPIProvider {
    private let apiClient: APIClient
    private let cache = PokemonCache.shared

    init(apiClient: APIClient = APIClient()) {
        self.apiClient = apiClient
        Task { await self.cache.loadFromDisk() }
    }

    func fetchPokemonList(limit: Int, offset: Int) async throws -> [Pokemon] {
        // Check cache first
        if let cached = await cache.cachedPage(offset: offset) {
            return cached
        }

        let endpoint = "/pokemon?limit=\(limit)&offset=\(offset)"
        let response: PokemonListResponse = try await apiClient.fetch(endpoint)
        let items = response.results.map { Pokemon(from: $0) }

        // Debug logging
        #if DEBUG
        for p in items.prefix(10) {
            print("[DEBUG][Repo] Mapped Pokemon: id=\(p.id) name=\(p.name) number=\(p.number.map(String.init) ?? "nil") imageUrl=\(p.imageUrl ?? "nil")")
        }
        #endif

        await cache.storePage(offset: offset, items: items, totalCount: response.count)
        return items
    }

    // Server-side exact search: try to fetch /pokemon/{nameOrId}
    func searchPokemonServer(query: String) async throws -> [Pokemon] {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.isEmpty { return [] }

        if let id = Int(trimmed) {
            // Lookup by id
            do {
                let endpoint = "/pokemon/\(id)"
                let detail: PokemonDetail = try await apiClient.fetch(endpoint)
                let poke = Pokemon(id: detail.name, name: detail.name.capitalized, number: detail.id, imageUrl: detail.sprites.frontDefault, types: detail.types.map { $0.type.name })
                return [poke]
            } catch let err as APIError {
                if case .serverError(let code) = err, code == 404 { return [] }
                throw err
            }
        } else {
            // Try by exact name
            do {
                let endpoint = "/pokemon/\(trimmed.lowercased())"
                let detail: PokemonDetail = try await apiClient.fetch(endpoint)
                let poke = Pokemon(id: detail.name, name: detail.name.capitalized, number: detail.id, imageUrl: detail.sprites.frontDefault, types: detail.types.map { $0.type.name })
                return [poke]
            } catch let err as APIError {
                if case .serverError(let code) = err, code == 404 { return [] }
                throw err
            }
        }
    }

    func searchPokemon(query: String) async throws -> [Pokemon] {
        // Prefer server-side exact lookup
        let serverResult = try await searchPokemonServer(query: query)
        if !serverResult.isEmpty { return serverResult }

        var all = await cache.allCachedItems()
        if all.isEmpty {
            let pageSize = 100
            let first = try await fetchPokemonList(limit: pageSize, offset: 0)
            let second = try await fetchPokemonList(limit: pageSize, offset: pageSize)
            all = first + second
        }

        return all.filter { pokemon in
            let matchesName = pokemon.name.lowercased().contains(query.lowercased())
            let matchesNumber: Bool
            if let num = pokemon.number {
                matchesNumber = String(num).contains(query)
            } else {
                matchesNumber = false
            }
            return matchesName || matchesNumber
        }
    }
}
