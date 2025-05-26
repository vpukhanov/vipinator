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
    let device: String
    var status: VPNStatus = .disconnected
}

enum VPNManager {
    private static let excludedServices = ["Wi-Fi", "Bluetooth PAN", "Thunderbolt Bridge"]

    static func getAvailableVPNs() async throws -> [VPNConnection] {
        let output = try await runScutilCommand(arguments: ["--nc", "list"])
        return parseVPNServices(output)
    }

    static func getStatus(for connection: VPNConnection) async throws -> VPNStatus {
        let output = try await runNetworkSetupCommand(arguments: ["-showpppoestatus", connection.name])
        return parseStatus(from: output)
    }

    static func connect(to connection: VPNConnection) async throws -> Bool {
        let initialStatus = try await getStatus(for: connection)
        _ = try await runNetworkSetupCommand(arguments: ["-connectpppoeservice", connection.name])
        try await Task.sleep(for: .seconds(2))
        let finalStatus = try await getStatus(for: connection)
        return (initialStatus != .connected) && (finalStatus == .connected)
    }

    static func disconnect(from connection: VPNConnection) async throws -> Bool {
        let initialStatus = try await getStatus(for: connection)
        _ = try await runNetworkSetupCommand(arguments: ["-disconnectpppoeservice", connection.name])
        try await Task.sleep(for: .seconds(2))
        let finalStatus = try await getStatus(for: connection)
        return (initialStatus == .connected) && (finalStatus != .connected)
    }

    static func extractDisplayName(from line: String) -> String {
        let pattern = "\"([^\"]+)\""
        if let range = line.range(of: pattern, options: .regularExpression) {
            let match = String(line[range])
            return match.replacingOccurrences(of: "\"", with: "")
        }
        return ""
    }

    static func extractConnectionStatus(from line: String) -> VPNStatus {
        let pattern = "\\(([^)]+)\\)"
        if let range = line.range(of: pattern, options: .regularExpression) {
            let match = String(line[range])
            let status = match.replacingOccurrences(of: "(", with: "").replacingOccurrences(
                of: ")", with: "")
            return parseStatusString(status)
        }
        return .disconnected
    }

    static func extractVPNType(from line: String) -> String {
        let pattern = "\\[VPN:([^\\]]+)\\]"
        if let range = line.range(of: pattern, options: .regularExpression) {
            let match = String(line[range])
            return match.replacingOccurrences(of: "[VPN:", with: "").replacingOccurrences(
                of: "]", with: "")
        }
        return "VPN"
    }

    static func parseStatusString(_ status: String) -> VPNStatus {
        let lowercased = status.lowercased()
        switch lowercased {
        case "connected":
            return .connected
        case "connecting":
            return .connecting
        case "disconnecting":
            return .disconnecting
        case "disconnected":
            return .disconnected
        default:
            return .disconnected
        }
    }

    static func parseVPNLine(_ line: String) -> VPNConnection? {
        guard line.contains("[VPN:") else {
            return nil
        }

        let displayName = extractDisplayName(from: line)
        let status = extractConnectionStatus(from: line)
        let vpnType = extractVPNType(from: line)

        guard !displayName.isEmpty else {
            return nil
        }

        var connection = VPNConnection(name: displayName, hardwarePort: vpnType, device: "")
        connection.status = status
        return connection
    }

    private static func runNetworkSetupCommand(arguments: [String]) async throws -> String {
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

        throw VPNError.commandOutputDecodingFailed
    }

    private static func runScutilCommand(arguments: [String]) async throws -> String {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/sbin/scutil")
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

        throw VPNError.commandOutputDecodingFailed
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

    private static func parseVPNServices(_ output: String) -> [VPNConnection] {
        let lines = output.components(separatedBy: .newlines)
        var vpnConnections: [VPNConnection] = []

        for line in lines {
            let trimmedLine = line.trimmingCharacters(in: .whitespacesAndNewlines)
            if trimmedLine.isEmpty || trimmedLine.contains("Available network connection services") {
                continue
            }

            if let connection = parseVPNLine(trimmedLine) {
                vpnConnections.append(connection)
            }
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
            .trimmingCharacters(in: .whitespaces)
    }
}

enum VPNError: Error {
    case commandOutputDecodingFailed
    case commandError(String)
}
