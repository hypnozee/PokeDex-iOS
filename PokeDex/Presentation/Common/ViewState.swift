import Foundation

enum ViewState<T> {
    case idle
    case loading
    case success(T)
    case error(String)
    
    var isLoading: Bool {
        if case .loading = self {
            return true
        }
        return false
    }
    
    var value: T? {
        if case .success(let value) = self {
            return value
        }
        return nil
    }
    
    var errorMessage: String? {
        if case .error(let message) = self {
            return message
        }
        return nil
    }
}
