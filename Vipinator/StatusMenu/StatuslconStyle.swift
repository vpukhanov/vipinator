import SwiftUI

enum StatusIconStyle: String, CaseIterable, Identifiable {
    case bolt
    case boltCircle
    case network

    static let defaultsKey = "StatusIconStyle"

    var id: String { rawValue }

    var title: String {
        switch self {
        case .bolt:
            return "Bolt"
        case .boltCircle:
            return "Bolt Circle"
        case .network:
            return "Network"
        }
    }

    var previewSymbolName: String {
        switch self {
        case .bolt:
            return "bolt.horizontal"
        case .boltCircle:
            return "bolt.horizontal.circle"
        case .network:
            return "network"
        }
    }

    func symbolName(isConnected: Bool) -> String {
        switch self {
        case .bolt:
            return isConnected ? "bolt.horizontal.fill" : "bolt.horizontal"
        case .boltCircle:
            return isConnected ? "bolt.horizontal.circle.fill" : "bolt.horizontal.circle"
        case .network:
            return isConnected ? "network.badge.shield.half.filled" : "network"
        }
    }

    var menuBarPointSize: CGFloat {
        switch self {
        case .bolt:
            return 13
        case .boltCircle, .network:
            return 15
        }
    }
}

