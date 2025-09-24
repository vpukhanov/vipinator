import SwiftUI

@MainActor
final class VPNMenuViewModel: ObservableObject {
    @Published private(set) var connections: [VPNConnection] = []
    @Published private(set) var isAnyConnectionActive = false
    @Published private(set) var isLoading = false

    private let lastUsedStore = LastUsedVPNStore.shared
    private var networkObserver: NetworkConfigurationObserver?

    init() {
        HotkeyManager.shared.registerCurrentOrDefault()
        networkObserver = NetworkConfigurationObserver { [weak self] in
            Task { await self?.refreshConnections() }
        }
        Task { await refreshConnections() }
    }

    deinit {
        networkObserver?.stopObserving()
    }

    func refreshConnections() async {
        isLoading = true
        defer { isLoading = false }

        do {
            var fetched = try await VPNManager.getAvailableVPNs()
            for index in fetched.indices {
                let status = try await VPNManager.getStatus(for: fetched[index])
                fetched[index].status = status
            }
            applyConnections(fetched)
        } catch {
            print("Error loading VPN connections: \(error)")
        }
    }

    func refreshStatuses() async {
        guard !connections.isEmpty else { return }

        var updated = connections
        var isActive = false

        for index in updated.indices {
            do {
                let status = try await VPNManager.getStatus(for: updated[index])
                updated[index].status = status
                if status == .connected || status == .connecting || status == .disconnecting {
                    isActive = true
                }
            } catch {
                print("Error updating status for VPN \(updated[index].name): \(error)")
            }
        }

        connections = updated
        isAnyConnectionActive = isActive
    }

    func toggle(_ connection: VPNConnection) async {
        do {
            let currentStatus = try await VPNManager.getStatus(for: connection)
            switch currentStatus {
            case .connected, .connecting:
                await disconnect(connection)
            case .disconnected, .invalid, .disconnecting:
                await connect(connection)
            }
        } catch {
            print("Error toggling VPN \(connection.name): \(error)")
        }
    }

    func toggleLastUsed() async {
        if connections.isEmpty {
            await refreshConnections()
        }

        guard let targetName = lastUsedStore.load() ?? connections.first?.name,
              let connection = connections.first(where: { $0.name == targetName }) else { return }

        await toggle(connection)
    }

    private func connect(_ connection: VPNConnection) async {
        updateConnection(connection, with: .connecting)
        do {
            let success = try await VPNManager.connect(to: connection)
            if success {
                lastUsedStore.save(connection.name)
            }
        } catch {
            print("Error connecting to VPN \(connection.name): \(error)")
        }

        await refreshStatuses()
    }

    private func disconnect(_ connection: VPNConnection) async {
        updateConnection(connection, with: .disconnecting)
        do {
            _ = try await VPNManager.disconnect(from: connection)
        } catch {
            print("Error disconnecting from VPN \(connection.name): \(error)")
        }

        await refreshStatuses()
    }

    private func applyConnections(_ newConnections: [VPNConnection]) {
        connections = newConnections
        isAnyConnectionActive = newConnections.contains { $0.status == .connected || $0.status == .connecting || $0.status == .disconnecting }
    }

    private func updateConnection(_ connection: VPNConnection, with status: VPNStatus) {
        guard let index = connections.firstIndex(of: connection) else { return }

        var updated = connections
        updated[index].status = status
        connections = updated
        isAnyConnectionActive = updated.contains { $0.status == .connected || $0.status == .connecting || $0.status == .disconnecting }
    }
}
