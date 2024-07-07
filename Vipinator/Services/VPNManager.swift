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

final class VPNManager {
    private static let excludedServices = ["Wi-Fi", "Bluetooth PAN", "Thunderbolt Bridge"]
    
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
        
        if let output = String(data: outputData, encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines) {
            return output
        } else if let errorOutput = String(data: errorData, encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines) {
            throw VPNError.commandError(errorOutput)
        } else {
            throw VPNError.commandOutputDecodingFailed
        }
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
        var currentConnection: (name: String?, hardwarePort: String?, device: String?) = (nil, nil, nil)
        
        for line in lines {
            if line.matches(regex: "^\\(\\d+\\)") {
                if let name = currentConnection.name,
                   let hardwarePort = currentConnection.hardwarePort,
                   !excludedServices.contains(name) {
                    vpnConnections.append(VPNConnection(name: name, hardwarePort: hardwarePort, device: currentConnection.device ?? ""))
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
           !excludedServices.contains(name) {
            vpnConnections.append(VPNConnection(name: name, hardwarePort: hardwarePort, device: currentConnection.device ?? ""))
        }
        
        return vpnConnections
    }
}

private extension String {
    func matches(regex: String) -> Bool {
        return self.range(of: regex, options: .regularExpression) != nil
    }

    func extractName() -> String {
        self.trimmingCharacters(in: .whitespaces)
            .replacingOccurrences(of: "(*)", with: "")
            .replacingOccurrences(of: "^\\(\\d+\\)\\s*", with: "", options: .regularExpression)
            .trimmingCharacters(in: .whitespaces)
    }
    
    func extractHardwarePort() -> String {
        self.trimmingCharacters(in: .whitespaces)
            .replacingOccurrences(of: "(Hardware Port:", with: "")
            .trimmingCharacters(in: .whitespaces)
    }
    
    func extractDevice() -> String {
        self.trimmingCharacters(in: .whitespaces)
            .replacingOccurrences(of: "Device:", with: "")
            .trimmingCharacters(in: .whitespaces)
    }
}

enum VPNError: Error {
    case commandOutputDecodingFailed
    case commandError(String)
}
