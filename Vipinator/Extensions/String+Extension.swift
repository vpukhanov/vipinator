//
//  String+Extension.swift
//  Vipinator
//
//  Created by Вячеслав Пуханов on 07.07.2024.
//

import Foundation

extension String {
    func matches(regex: String) -> Bool {
        return self.range(of: regex, options: .regularExpression) != nil
    }
}
