//
//  String+Sanitize.swift
//  Magic Hour
//
//  Created by Lauri-Matti Parppei on 5.2.2025.
//

import Foundation

extension String {
    func sanitizedFileName() -> String {
        let invalidCharacters = CharacterSet(charactersIn: "/\\:?\"<>|*")
        let cleanedString = self.components(separatedBy: invalidCharacters).joined()
        return cleanedString.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
