//
//  LastUsedVPNStore.swift
//  Vipinator
//
//  Created by Artem Chebotok on 17.09.2025.
//


import Foundation

final class LastUsedVPNStore {
    static let shared = LastUsedVPNStore()
    private let key = "LastUsedVPNName"
    private init() {}

    func save(_ name: String) {
        UserDefaults.standard.set(name, forKey: key)
    }

    func load() -> String? {
        UserDefaults.standard.string(forKey: key)
    }

    func clear() {
        UserDefaults.standard.removeObject(forKey: key)
    }
}
