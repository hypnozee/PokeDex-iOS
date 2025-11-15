import Foundation

// MARK: - API Error Handling

enum APIError: LocalizedError {
    case invalidURL
    case networkError(Error)
    case decodingError(Error)
    case serverError(Int)
    case unknownError

    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid URL"
        case .networkError(let error):
            return "Network error: \(error.localizedDescription)"
        case .decodingError(let error):
            return "Decoding error: \(error.localizedDescription)"
        case .serverError(let code):
            return "Server error: \(code)"
        case .unknownError:
            return "Unknown error occurred"
        }
    }
}

actor APIClient {
    private let session: URLSession
    private let baseURL: URL

    init(session: URLSession = .shared, baseURL: String = "https://pokeapi.co/api/v2") {
        self.session = session
        let normalized = baseURL.hasSuffix("/") ? baseURL : baseURL + "/"
        self.baseURL = URL(string: normalized) ?? URL(fileURLWithPath: "")
    }

    func fetch<T: Decodable>(_ endpoint: String) async throws -> T {
        var url: URL?

        // Use absolute URL if provided
        if let absolute = URL(string: endpoint), absolute.scheme != nil {
            url = absolute
        } else {
            // Split path and query
            let parts = endpoint.split(separator: "?", maxSplits: 1, omittingEmptySubsequences: false)
            var path = parts.count > 0 ? String(parts[0]) : ""
            let query = parts.count > 1 ? String(parts[1]) : nil

            if path.hasPrefix("/") { path.removeFirst() }
            url = baseURL.appendingPathComponent(path)
            if let query = query, var components = URLComponents(url: url!, resolvingAgainstBaseURL: false) {
                components.query = query
                url = components.url
            }
        }

        guard let url = url else { throw APIError.invalidURL }

        do {
            let (data, response) = try await session.data(from: url)
            guard let httpResponse = response as? HTTPURLResponse else { throw APIError.unknownError }
            guard (200...299).contains(httpResponse.statusCode) else { throw APIError.serverError(httpResponse.statusCode) }
            let decoder = JSONDecoder()
            return try decoder.decode(T.self, from: data)
        } catch let error as DecodingError {
            throw APIError.decodingError(error)
        } catch let error as URLError {
            throw APIError.networkError(error)
        } catch {
            throw error
        }
    }
}
