//
//  User.swift
//  trailmemo
//
//  Created by Thomas Fitzgerald on 12/9/25.
//


import Foundation

struct User: Codable {
    let userId: String
    let email: String
    let displayName: String?
    let department: String?
    let createdAt: Date
    
    enum CodingKeys: String, CodingKey {
        case userId = "user_id"
        case email
        case displayName = "display_name"
        case department
        case createdAt = "created_at"
    }
}
