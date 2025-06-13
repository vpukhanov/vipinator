//
//  VPNManager.swift
//  Vipinator
//
//  Created by Вячеслав Пуханов on 07.07.2024.
//

import Foundation

enum VPNStatus: String, CaseIterable {
    case connected, connecting, disconnecting, disconnected, invalid
}

struct VPNConnection: Identifiable, Equatable {
    let id = UUID()
    let name: String
    let hardwarePort: String
    var status: VPNStatus = .disconnected
}

enum VPNManager {
    static func getAvailableVPNs() async throws -> [VPNConnection] {
        let output = try await runNetworkSetupCommand(arguments: ["-listnetworkserviceorder"])
        return parseNetworkServices(output)
    }

    static func getStatus(for connection: VPNConnection) async throws -> VPNStatus {
        let output = try await runNetworkSetupCommand(arguments: ["-showpppoestatus", connection.name])
        return parseStatus(from: output)
    }

    static func connect(to connection: VPNConnection) async throws -> Bool {
        let initialStatus = try await getStatus(for: connection)
        _ = try await runNetworkSetupCommand(arguments: ["-connectpppoeservice", connection.name], allowEmptyOutput: true)
        try await Task.sleep(for: .seconds(2))
        let finalStatus = try await getStatus(for: connection)
        return (initialStatus != .connected) && (finalStatus == .connected)
    }

    static func disconnect(from connection: VPNConnection) async throws -> Bool {
        let initialStatus = try await getStatus(for: connection)
        _ = try await runNetworkSetupCommand(arguments: ["-disconnectpppoeservice", connection.name], allowEmptyOutput: true)
        try await Task.sleep(for: .seconds(2))
        let finalStatus = try await getStatus(for: connection)
        return (initialStatus == .connected) && (finalStatus != .connected)
    }

    private static func runNetworkSetupCommand(arguments: [String], allowEmptyOutput: Bool = false) async throws -> String {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/sbin/networksetup")
        process.arguments = arguments

        let outputPipe = Pipe()
        let errorPipe = Pipe()
        process.standardOutput = outputPipe
        process.standardError = errorPipe

        try process.run()
        process.waitUntilExit()

        let outputData = outputPipe.fileHandleForReading.readDataToEndOfFile()
        let errorData = errorPipe.fileHandleForReading.readDataToEndOfFile()

        let output = String(decoding: outputData, as: UTF8.self).trimmingCharacters(in: .whitespacesAndNewlines)
        if !output.isEmpty {
            return output
        }

        let errorOutput = String(decoding: errorData, as: UTF8.self).trimmingCharacters(in: .whitespacesAndNewlines)
        if !errorOutput.isEmpty {
            throw VPNError.commandError(errorOutput)
        }

        if !allowEmptyOutput {
            throw VPNError.commandOutputDecodingFailed
        }

        return ""
    }

    private static func parseStatus(from output: String) -> VPNStatus {
        let lowercasedOutput = output.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()

        switch lowercasedOutput {
        case "connected":
            return .connected
        case "connecting":
            return .connecting
        case "disconnecting":
            return .disconnecting
        case "disconnected":
            return .disconnected
        default:
            return .invalid
        }
    }

    private static func parseNetworkServices(_ output: String) -> [VPNConnection] {
        let lines = output.components(separatedBy: .newlines)
        var vpnConnections: [VPNConnection] = []
        var currentConnection = NetworkServiceInfo()

        for line in lines {
            if line.matches(regex: "^\\(\\d+\\)") {
                if let name = currentConnection.name,
                   let hardwarePort = currentConnection.hardwarePort,
                   let device = currentConnection.device,
                   device.isEmpty {
                    vpnConnections.append(
                        VPNConnection(name: name, hardwarePort: hardwarePort)
                    )
                }
                currentConnection.name = line.extractName()
                currentConnection.hardwarePort = nil
                currentConnection.device = nil
            } else if line.contains("Hardware Port:") {
                let components = line.components(separatedBy: ",")
                if components.count >= 2 {
                    currentConnection.hardwarePort = components[0].extractHardwarePort()
                    currentConnection.device = components[1].extractDevice()
                }
            }
        }

        if let name = currentConnection.name,
           let hardwarePort = currentConnection.hardwarePort,
           let device = currentConnection.device,
           device.isEmpty {
            vpnConnections.append(
                VPNConnection(name: name, hardwarePort: hardwarePort)
            )
        }

        return vpnConnections
    }

    private struct NetworkServiceInfo {
        var name: String?
        var hardwarePort: String?
        var device: String?
    }
}

private extension String {
    func matches(regex: String) -> Bool {
        return range(of: regex, options: .regularExpression) != nil
    }

    func extractName() -> String {
        trimmingCharacters(in: .whitespaces)
            .replacingOccurrences(of: "(*)", with: "")
            .replacingOccurrences(of: "^\\(\\d+\\)\\s*", with: "", options: .regularExpression)
            .trimmingCharacters(in: .whitespaces)
    }

    func extractHardwarePort() -> String {
        trimmingCharacters(in: .whitespaces)
            .replacingOccurrences(of: "(Hardware Port:", with: "")
            .trimmingCharacters(in: .whitespaces)
    }

    func extractDevice() -> String {
        trimmingCharacters(in: .whitespaces)
            .replacingOccurrences(of: "Device:", with: "")
            .replacingOccurrences(of: "\\)$", with: "", options: .regularExpression)
            .trimmingCharacters(in: .whitespaces)
    }
}

enum VPNError: Error {
    case commandOutputDecodingFailed
    case commandError(String)
}
