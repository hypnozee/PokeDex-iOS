import Foundation

actor PokemonCache {
    static let shared = PokemonCache()

    // Store pages by offset (pageSize-based)
    private var pages: [Int: [Pokemon]] = [:]
    private var totalCount: Int? = nil

    // Simple disk cache location
    private let cacheURL: URL = {
        let fm = FileManager.default
        let dir = fm.urls(for: .cachesDirectory, in: .userDomainMask).first!
        return dir.appendingPathComponent("pokecache.json")
    }()

    // MARK: - Page cache
    func cachedPage(offset: Int) -> [Pokemon]? {
        pages[offset]
    }

    func storePage(offset: Int, items: [Pokemon], totalCount: Int?) {
        pages[offset] = items
        if let tc = totalCount {
            self.totalCount = tc
        }
        Task { await persistToDiskIfNeeded() }
    }

    func allCachedItems() -> [Pokemon] {
        // Return pages in offset order
        let sortedOffsets = pages.keys.sorted()
        var all: [Pokemon] = []
        for offset in sortedOffsets {
            if let p = pages[offset] {
                all.append(contentsOf: p)
            }
        }
        return all
    }

    func clear() {
        pages.removeAll()
        totalCount = nil
        try? FileManager.default.removeItem(at: cacheURL)
    }

    // MARK: - Persistence (simple)
    private func persistToDiskIfNeeded() {
        let wrapper = CacheWrapper(totalCount: totalCount, pages: pages)
        do {
            let data = try JSONEncoder().encode(wrapper)
            try data.write(to: cacheURL, options: [.atomic])
        } catch {
            // ignore errors for now
            // print("Failed to write cache: \(error)")
        }
    }

    func loadFromDisk() {
        do {
            let data = try Data(contentsOf: cacheURL)
            let wrapper = try JSONDecoder().decode(CacheWrapper.self, from: data)
            self.totalCount = wrapper.totalCount
            self.pages = wrapper.pages
        } catch {
            // nothing to do
        }
    }
}

fileprivate struct CacheWrapper: Codable {
    let totalCount: Int?
    let pages: [Int: [Pokemon]]
}
