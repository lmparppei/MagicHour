//
//  Utils.swift
//  Magic Hour
//
//  Created by Lauri-Matti Parppei on 5.2.2025.
//

import Foundation

/// Helper for date formatter
let dayFormatter: DateFormatter = {
    let formatter = DateFormatter()
    formatter.dateFormat = "yyyy-MM-dd"
    return formatter
}()

/// Helper for display date formatter
let displayDayFormatter: DateFormatter = {
    let formatter = DateFormatter()
    formatter.dateStyle = .medium
    return formatter
}()

/// Returns only the date part of an ISO date
func mediumDateFromISODate(_ str:String) -> String {
    if let date = dayFormatter.date(from: str) {
        let dFormatter = DateFormatter()
        dFormatter.dateStyle = .medium
        let formatted = dFormatter.string(from: date)
        return formatted
    }
    return ""
}

extension URL {
    var typeIdentifier: String? { (try? resourceValues(forKeys: [.typeIdentifierKey]))?.typeIdentifier }
    var localizedName: String? { (try? resourceValues(forKeys: [.localizedNameKey]))?.localizedName }
}
