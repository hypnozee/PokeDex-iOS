import SwiftUI

struct PokemonDetailView: View {
    @StateObject var viewModel: PokemonDetailViewModel

    var body: some View {
        Group {
            switch viewModel.viewState {
            case .idle, .loading:
                ProgressView()
                    .scaleEffect(1.2)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            case .error(let message):
                VStack(spacing: 16) {
                    Image(systemName: "exclamationmark.triangle")
                        .font(.system(size: 48))
                        .foregroundColor(.red)
                    Text("Could not load Pokémon")
                        .font(.headline)
                    Text(message)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                    Button("Retry") {
                        viewModel.retry()
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            case .success(let data):
                ScrollView {
                    VStack(spacing: 16) {
                        if let urlString = data.imageUrl, let url = URL(string: urlString) {
                            AsyncImage(url: url) { phase in
                                switch phase {
                                case .success(let image):
                                    image
                                        .resizable()
                                        .scaledToFit()
                                        .frame(height: 220)
                                default:
                                    Image(systemName: "photo")
                                        .resizable()
                                        .scaledToFit()
                                        .frame(height: 220)
                                        .foregroundColor(.gray)
                                }
                            }
                        } else {
                            Image(systemName: "photo")
                                .resizable()
                                .scaledToFit()
                                .frame(height: 220)
                                .foregroundColor(.gray)
                        }

                        HStack(alignment: .top, spacing: 12) {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(data.name)
                                    .font(.largeTitle)
                                    .bold()
                                Text("#\(String(format: "%03d", data.id))")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                            }
                            Spacer()
                        }
                        .padding(.horizontal)

                        // Types
                        if !data.types.isEmpty {
                            HStack {
                                ForEach(data.types, id: \.self) { t in
                                    Text(t)
                                        .font(.caption)
                                        .padding(.vertical, 6)
                                        .padding(.horizontal, 10)
                                        .background(Color(.systemGray6))
                                        .cornerRadius(12)
                                }
                            }
                            .padding(.horizontal)
                        }

                        // Height & Weight
                        HStack(spacing: 16) {
                            VStack {
                                Text("Height")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                Text(String(format: "%.1f m", data.heightMeters))
                                    .font(.headline)
                            }
                            .frame(maxWidth: .infinity)

                            VStack {
                                Text("Weight")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                Text(String(format: "%.1f kg", data.weightKg))
                                    .font(.headline)
                            }
                            .frame(maxWidth: .infinity)
                        }
                        .padding(.horizontal)

                        // Stats
                        if !data.stats.isEmpty {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Stats")
                                    .font(.headline)
                                ForEach(data.stats.indices, id: \.self) { idx in
                                    let stat = data.stats[idx]
                                    HStack {
                                        Text(stat.0.capitalized)
                                            .frame(width: 80, alignment: .leading)
                                        ProgressView(value: Float(stat.1), total: 255)
                                            .progressViewStyle(.linear)
                                        Text("\(stat.1)")
                                            .frame(width: 32, alignment: .trailing)
                                    }
                                }
                            }
                            .padding(.horizontal)
                        }

                        // Abilities
                        if !data.abilities.isEmpty {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Abilities")
                                    .font(.headline)
                                ForEach(data.abilities, id: \.self) { a in
                                    Text(a.capitalized)
                                }
                            }
                            .padding(.horizontal)
                        }

                        Spacer()
                    }
                    .padding(.vertical)
                }
            }
        }
        .navigationTitle("Details")
        .task {
            viewModel.load()
        }
    }
}

#Preview {
    PokemonDetailView(viewModel: PokemonDetailViewModel(nameOrId: "1"))
}
