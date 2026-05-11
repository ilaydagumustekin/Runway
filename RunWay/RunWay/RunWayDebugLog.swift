import Foundation

/// Geçici uçtan uca konum / mahalle debug çıktıları. Yalnızca DEBUG derlemesinde üretir.
enum RunWayDebugLog {
    static func location(_ message: String) {
        #if DEBUG
        print("[LOCATION_DEBUG] \(message)")
        #endif
    }

    static func neighborhood(_ message: String) {
        #if DEBUG
        print("[NEIGHBORHOOD_DEBUG] \(message)")
        #endif
    }

    static func state(_ message: String) {
        #if DEBUG
        print("[STATE_DEBUG] \(message)")
        #endif
    }

    static func home(_ message: String) {
        #if DEBUG
        print("[HOME_DEBUG] \(message)")
        #endif
    }

    static func analysis(_ message: String) {
        #if DEBUG
        print("[ANALYSIS_DEBUG] \(message)")
        #endif
    }

    static func route(_ message: String) {
        #if DEBUG
        print("[ROUTE_SEARCH_DEBUG] \(message)")
        #endif
    }

    static func activeRoute(_ message: String) {
        #if DEBUG
        print("[ACTIVE_ROUTE_DEBUG] \(message)")
        #endif
    }
}
