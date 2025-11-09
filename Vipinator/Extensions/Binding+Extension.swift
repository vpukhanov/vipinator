//
//  Binding+Extension.swift
//  Vipinator
//
//  Created by Вячеслав Пуханов on 09.11.2025.
//

import SwiftUI

extension Binding {
    func onChange(_ handler: @escaping () -> Void) -> Binding<Value> {
        Binding(
            get: { self.wrappedValue },
            set: { newValue in
                self.wrappedValue = newValue
                handler()
            }
        )
    }
}
