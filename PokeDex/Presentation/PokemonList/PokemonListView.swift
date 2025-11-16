import SwiftUI

struct PokemonListView: View {
    @StateObject private var viewModel = PokemonListViewModel()
    @State private var debouncedQuery: String = ""

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                SearchBar(text: $debouncedQuery)
                    .padding()
                    .onChange(of: debouncedQuery) { oldValue, newValue in
                        Task {
                            try? await Task.sleep(nanoseconds: 300_000_000)
                            // Ensure value hasn't changed during debounce
                            if newValue == debouncedQuery {
                                await viewModel.search(query: newValue)
                            }
                        }
                    }

                ZStack {
                    if viewModel.viewState.isLoading {
                        ProgressView()
                            .scaleEffect(1.2)
                    } else if let errorMessage = viewModel.viewState.errorMessage {
                        VStack(spacing: 16) {
                            Image(systemName: "exclamationmark.triangle")
                                .font(.system(size: 48))
                                .foregroundColor(.red)
                            Text("Oops! Something went wrong")
                                .font(.headline)
                            Text(errorMessage)
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal)
                            Button("Try Again") {
                                Task { await viewModel.retryLoad() }
                            }
                        }
                    } else if let pokemon = viewModel.viewState.value, !pokemon.isEmpty {
                        ScrollView {
                            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
                                ForEach(pokemon) { poke in
                                    let nameOrId = poke.number.map { String($0) } ?? poke.id
                                    NavigationLink(value: nameOrId) {
                                        PokemonCardView(pokemon: poke)
                                    }
                                    .onAppear { viewModel.loadMoreIfNeeded(currentItem: poke) }
                                }
                            }
                            .padding()
                        }
                        .navigationDestination(for: String.self) { nameOrId in
                            PokemonDetailView(viewModel: DependencyContainer.shared.makePokemonDetailViewModel(nameOrId: nameOrId))
                        }
                    } else {
                        VStack(spacing: 12) {
                            Image(systemName: "magnifyingglass")
                                .font(.system(size: 48))
                                .foregroundColor(.gray)
                            Text("No Pokémon found")
                                .font(.headline)
                            Text("Try adjusting your search")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
            .navigationTitle("Pokédex")
            .task {
                await viewModel.loadInitial()
            }
        }
    }
}

struct SearchBar: View {
    @Binding var text: String

    var body: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.gray)

            TextField("Search Pokémon...", text: $text)
                .textFieldStyle(.roundedBorder)

            if !text.isEmpty {
                Button(action: { text = "" }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.gray)
                }
            }
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 16)
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

#Preview {
    PokemonListView()
}
