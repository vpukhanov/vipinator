//
//  VPNManager.swift
//  Vipinator
//
//  Created by Вячеслав Пуханов on 07.07.2024.
//

import Foundation

struct VPNConnection {
    let name: String
    let hardwarePort: String
    let device: String
}

class VPNManager {
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
            return parseNetworkServices(output)
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
