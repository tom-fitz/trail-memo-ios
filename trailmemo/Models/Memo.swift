//
//  Memo.swift
//  trailmemo
//
//  Created by Thomas Fitzgerald on 12/9/25.
//

import Foundation
import CoreLocation

struct Memo: Identifiable, Codable {
    let id: UUID
    let userId: String
    let userName: String
    var title: String?
    let audioURL: String  // Changed from URL to String for JSON
    let text: String
    let durationSeconds: Int
    let location: Location?
    let parkName: String?
    let createdAt: Date
    let updatedAt: Date
    
    // For JSON decoding
    enum CodingKeys: String, CodingKey {
        case id = "memo_id"
        case userId = "user_id"
        case userName = "user_name"
        case title
        case audioURL = "audio_url"
        case text
        case durationSeconds = "duration_seconds"
        case location
        case parkName = "park_name"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
    
    struct Location: Codable {
        let latitude: Double
        let longitude: Double
        let accuracy: Double
        var address: String?
        
        var coordinate: CLLocationCoordinate2D {
            CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
        }
    }
}
