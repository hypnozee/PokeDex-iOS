import Foundation
import Combine

@MainActor
final class PokemonDetailViewModel: ObservableObject {
    @Published var viewState: ViewState<PokemonDetailViewData> = .idle

    private let useCase: PokemonDetailUseCase
    private let nameOrId: String
    private var loadTask: Task<Void, Never>? = nil

    init(nameOrId: String, useCase: PokemonDetailUseCase? = nil) {
        self.nameOrId = nameOrId
        self.useCase = useCase ?? DependencyContainer.shared.resolvePokemonDetailUseCase()
    }

    func load() {
        loadTask?.cancel()
        viewState = .loading
        loadTask = Task { [weak self] in
            guard let self else { return }
            do {
                let detail = try await self.useCase.fetchPokemonDetail(nameOrId: nameOrId)
                let data = PokemonDetailViewData(from: detail)
                self.viewState = .success(data)
            } catch {
                self.viewState = .error(error.localizedDescription)
            }
        }
    }

    func retry() {
        load()
    }

    deinit {
        loadTask?.cancel()
    }
}

struct PokemonDetailViewData {
    let id: Int
    let name: String
    let imageUrl: String?
    let types: [String]
    let heightMeters: Double
    let weightKg: Double
    let abilities: [String]
    let stats: [(String, Int)]

    init(from detail: PokemonDetail) {
        self.id = detail.id
        self.name = detail.name.capitalized
        self.imageUrl = detail.sprites.frontDefault ?? detail.sprites.backDefault
        self.types = detail.types.map { $0.type.name.capitalized }
        self.heightMeters = Double(detail.height) / 10.0
        self.weightKg = Double(detail.weight) / 10.0
        // Map abilities and stats
        self.abilities = detail.abilities.map { $0.ability.name }
        self.stats = detail.stats.map { ( $0.stat.name, $0.baseStat ) }
    }
}
