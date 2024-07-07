//
//  VPNManager.swift
//  Vipinator
//
//  Created by Вячеслав Пуханов on 07.07.2024.
//

import Foundation

enum VPNStatus: String {
    case connected
    case connecting
    case disconnecting
    case disconnected
    case invalid
}

struct VPNConnection {
    let name: String
    let hardwarePort: String
    let device: String
    var status: VPNStatus = .disconnected
}

class VPNManager {
    static func getStatus(for connection: VPNConnection) -> VPNStatus {
        let task = Process()
        task.launchPath = "/usr/sbin/networksetup"
        task.arguments = ["-showpppoestatus", connection.name]
        
        let pipe = Pipe()
        task.standardOutput = pipe
        
        do {
            try task.run()
        } catch {
            print("Failed to run networksetup command for status: \(error)")
            return .invalid
        }
        
        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        task.waitUntilExit()
        
        guard let output = String(data: data, encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() else {
            return .invalid
        }
        
        switch output {
        case "connected": return .connected
        case "connecting": return .connecting
        case "disconnecting": return .disconnecting
        case "disconnected": return .disconnected
        default: return .invalid
        }
    }
    
    static func getAvailableVPNs() -> [VPNConnection] {
        let task = Process()
        task.launchPath = "/usr/sbin/networksetup"
        task.arguments = ["-listnetworkserviceorder"]
        
        let pipe = Pipe()
        task.standardOutput = pipe
        
        let errorPipe = Pipe()
        task.standardError = errorPipe
        
        do {
            try task.run()
        } catch {
            print("Failed to run networksetup command: \(error)")
            return []
        }
        
        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        let errorData = errorPipe.fileHandleForReading.readDataToEndOfFile()
        
        if let errorOutput = String(data: errorData, encoding: .utf8), !errorOutput.isEmpty {
            print("Command error output: \(errorOutput)")
        }
        
        task.waitUntilExit()
        
        if let output = String(data: data, encoding: .utf8) {
            var connections = parseNetworkServices(output)
            for i in 0..<connections.count {
                connections[i].status = getStatus(for: connections[i])
            }
            return connections
        } else {
            print("Failed to decode networksetup command output")
            return []
        }
    }
    
    private static func parseNetworkServices(_ output: String) -> [VPNConnection] {
        var vpnConnections: [VPNConnection] = []
        let lines = output.components(separatedBy: .newlines)
        
        var currentName: String?
        var currentHardwarePort: String?
        var currentDevice: String?
        
        for line in lines {
            if line.matches(regex: "^\\(\\d+\\)") {
                if let name = currentName, let hardwarePort = currentHardwarePort {
                    let connection = VPNConnection(name: name, hardwarePort: hardwarePort, device: currentDevice ?? "")
                    vpnConnections.append(connection)
                }
                currentName = line.trimmingCharacters(in: .whitespaces)
                    .replacingOccurrences(of: "(*)", with: "")
                    .replacingOccurrences(of: "^\\(\\d+\\)\\s*", with: "", options: .regularExpression)
                    .trimmingCharacters(in: .whitespaces)
                currentHardwarePort = nil
                currentDevice = nil
            } else if line.contains("Hardware Port:") {
                let components = line.components(separatedBy: ",")
                if components.count >= 2 {
                    currentHardwarePort = components[0].trimmingCharacters(in: .whitespaces).replacingOccurrences(of: "(Hardware Port:", with: "").trimmingCharacters(in: .whitespaces)
                    currentDevice = components[1].trimmingCharacters(in: .whitespaces).replacingOccurrences(of: "Device:", with: "").trimmingCharacters(in: .whitespaces)
                }
            }
        }
        
        // Add the last VPN connection if exists
        if let name = currentName, let hardwarePort = currentHardwarePort {
            let connection = VPNConnection(name: name, hardwarePort: hardwarePort, device: currentDevice ?? "")
            vpnConnections.append(connection)
        }
        
        return vpnConnections
    }
}
