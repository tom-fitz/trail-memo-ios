//
//  MapHelpers.swift
//  trailmemo
//
//  Created by Thomas Fitzgerald on 12/9/25.
//

import Foundation
import SwiftUI

// Generate consistent color for each user based on their ID
func getUserColor(userId: String) -> Color {
    let hash = userId.hashValue
    let hue = Double(abs(hash) % 360) / 360.0
    return Color(hue: hue, saturation: 0.6, brightness: 0.8)
}

// Get user initials from name
func getUserInitials(name: String) -> String {
    let parts = name.trimmingCharacters(in: .whitespacesAndNewlines).components(separatedBy: .whitespaces)
    if parts.count >= 2 {
        let first = parts.first?.prefix(1).uppercased() ?? ""
        let last = parts.last?.prefix(1).uppercased() ?? ""
        return first + last
    }
    return String(name.prefix(2)).uppercased()
}

// Format date for display
extension Date {
    func timeAgo() -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .full
        return formatter.localizedString(for: self, relativeTo: Date())
    }
}
