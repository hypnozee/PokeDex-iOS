import SwiftUI

struct PokemonCardView: View {
    let pokemon: Pokemon

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Pokemon Image
            Group {
                if let urlString = pokemon.imageUrl, let url = URL(string: urlString) {
                    AsyncImage(url: url) { phase in
                        switch phase {
                        case .success(let image):
                            image
                                .resizable()
                                .scaledToFit()
                                .frame(height: 100)
                        default:
                            Image(systemName: "photo")
                                .resizable()
                                .scaledToFit()
                                .frame(height: 100)
                                .foregroundColor(.gray)
                        }
                    }
                } else {
                    Image(systemName: "photo")
                        .resizable()
                        .scaledToFit()
                        .frame(height: 100)
                        .foregroundColor(.gray)
                }
            }
            .frame(maxWidth: .infinity)
            .background(Color(.systemGray6))
            .cornerRadius(8)

            // Pokemon Name
            Text(pokemon.name)
                .font(.headline)
                .lineLimit(1)

            // Pokemon Number
            if let num = pokemon.number {
                Text("#\(String(format: "%03d", num))")
                    .font(.caption)
                    .foregroundColor(.secondary)
            } else {
                Text("#---")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(radius: 4)
        .onAppear {
            #if DEBUG
            print("[DEBUG][Card] onAppear id=\(pokemon.id) name=\(pokemon.name) number=\(pokemon.number.map(String.init) ?? "nil") imageUrl=\(pokemon.imageUrl ?? "nil")")
            #endif
        }
    }
}

#Preview {
    PokemonCardView(
        pokemon: Pokemon(
            id: "bulbasaur",
            name: "Bulbasaur",
            number: 1,
            imageUrl: "https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/pokemon/1.png",
            types: ["Grass", "Poison"]
        )
    )
    .padding()
}
