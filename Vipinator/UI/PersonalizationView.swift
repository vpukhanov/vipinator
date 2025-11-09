//
//  PersonalizationView.swift
//  Vipinator
//

import SwiftUI

extension Notification.Name {
    static let statusIconStyleDidChange = Notification.Name("StatusIconStyleDidChange")
}

enum StatusIconStyle: String, CaseIterable {
    case bolt, boltCircle, network

    static let defaultsKey = "StatusIconStyle"

    static var current: StatusIconStyle {
        StatusIconStyle(rawValue: UserDefaults.standard.string(forKey: defaultsKey) ?? "bolt") ?? .bolt
    }

    var disconnectedImage: String {
        switch self {
        case .bolt:       return "bolt.horizontal"
        case .boltCircle: return "bolt.horizontal.circle"
        case .network:    return "network"
        }
    }

    var connectedImage: String {
        switch self {
        case .bolt:       return "bolt.horizontal.fill"
        case .boltCircle: return "bolt.horizontal.circle.fill"
        case .network:    return "network.badge.shield.half.filled"
        }
    }
}

struct PersonalizationView: View {
    @AppStorage(StatusIconStyle.defaultsKey) private var storedIconStyle: String = StatusIconStyle.bolt.rawValue

    var body: some View {
        Form {
            Section {
                Text("Menu Bar Icon")
                    .font(.headline)
                
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                    ForEach(StatusIconStyle.allCases, id: \.self) { style in
                        IconOptionButton(
                            style: style,
                            isSelected: style.rawValue == storedIconStyle
                        ) {
                            storedIconStyle = style.rawValue
                            NotificationCenter.default.post(name: .statusIconStyleDidChange, object: nil)
                        }
                    }
                }
                .padding(.vertical, 8)
                
                Text("Choose the appearance of the icon in the menu bar")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .formStyle(.grouped)
    }
}

struct IconOptionButton: View {
    let style: StatusIconStyle
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack {
                Image(systemName: style.disconnectedImage)
                    .font(.system(size: 28, weight: .semibold))
                    .foregroundStyle(.primary)
                    .frame(width: 92, height: 92)
                    .background {
                        RoundedRectangle(cornerRadius: 14)
                            .fill(Color(nsColor: .controlBackgroundColor))
                            .overlay {
                                RoundedRectangle(cornerRadius: 14)
                                    .stroke(isSelected ? Color.accentColor : Color.clear, lineWidth: isSelected ? 2 : 1)
                            }
                    }
            }
        }
        .buttonStyle(.plain)
    }
}

