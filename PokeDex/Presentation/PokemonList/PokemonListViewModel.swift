import Foundation
import Combine

@MainActor
final class PokemonListViewModel: ObservableObject {
    @Published var viewState: ViewState<[Pokemon]> = .idle
    @Published var searchQuery: String = ""

    private let useCase: PokemonListUseCase
    private var allPokemon: [Pokemon] = []

    // Pagination
    private let pageSize = 50
    private var offset = 0
    private var isLoadingMore = false
    private var reachedEnd = false

    init(useCase: PokemonListUseCase? = nil) {
        self.useCase = useCase ?? DependencyContainer.shared.resolvePokemonListUseCase()
    }

    func loadInitial() async {
        offset = 0
        reachedEnd = false
        allPokemon = []
        await loadNextPage()
    }

    func loadNextPage() async {
        guard !isLoadingMore && !reachedEnd else { return }
        isLoadingMore = true
        if offset == 0 { viewState = .loading }

        do {
            let page = try await useCase.fetchPokemonList(pageSize: pageSize, offset: offset)
            if page.isEmpty {
                reachedEnd = true
            } else {
                allPokemon.append(contentsOf: page)
                offset += pageSize
            }

            #if DEBUG
            for p in page.prefix(10) {
                print("[DEBUG] Loaded: id=\(p.id) name=\(p.name) number=\(p.number.map(String.init) ?? "nil") imageUrl=\(p.imageUrl ?? "nil")")
            }
            #endif

            viewState = .success(allPokemon)
        } catch {
            viewState = .error(error.localizedDescription)
        }

        isLoadingMore = false
    }

    func loadMoreIfNeeded(currentItem: Pokemon) {
        guard let last = allPokemon.last else { return }
        if currentItem.id == last.id {
            Task { await loadNextPage() }
        }
    }

    func search(query: String) async {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            viewState = .success(allPokemon)
            return
        }

        viewState = .loading
        do {
            let results = try await useCase.searchPokemon(query: trimmed)
            #if DEBUG
            print("[DEBUG] Search results count=\(results.count) for query='\(trimmed)'")
            for p in results.prefix(10) {
                print("[DEBUG] Search: id=\(p.id) name=\(p.name) number=\(p.number.map(String.init) ?? "nil") imageUrl=\(p.imageUrl ?? "nil")")
            }
            #endif
            viewState = .success(results)
        } catch {
            viewState = .error(error.localizedDescription)
        }
    }

    func filterPokemon(by query: String) {
        Task { await self.search(query: query) }
    }

    func retryLoad() async {
        await loadInitial()
    }
}
