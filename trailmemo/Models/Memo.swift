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
    let audioURL: String
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
    
    // Custom date decoder to handle multiple formats
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        id = try container.decode(UUID.self, forKey: .id)
        userId = try container.decode(String.self, forKey: .userId)
        userName = try container.decode(String.self, forKey: .userName)
        title = try container.decodeIfPresent(String.self, forKey: .title)
        audioURL = try container.decode(String.self, forKey: .audioURL)
        text = try container.decode(String.self, forKey: .text)
        durationSeconds = try container.decode(Int.self, forKey: .durationSeconds)
        location = try container.decodeIfPresent(Location.self, forKey: .location)
        parkName = try container.decodeIfPresent(String.self, forKey: .parkName)
        
        // Try multiple date formats
        let dateFormatter = DateFormatter()
        
        // Try ISO8601 first
        let iso8601Formatter = ISO8601DateFormatter()
        iso8601Formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        
        // Decode created_at
        if let createdAtString = try? container.decode(String.self, forKey: .createdAt) {
            if let date = iso8601Formatter.date(from: createdAtString) {
                createdAt = date
            } else {
                // Try without fractional seconds
                iso8601Formatter.formatOptions = [.withInternetDateTime]
                if let date = iso8601Formatter.date(from: createdAtString) {
                    createdAt = date
                } else {
                    // Try PostgreSQL format: "2024-12-10 12:34:56"
                    dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
                    dateFormatter.locale = Locale(identifier: "en_US_POSIX")
                    dateFormatter.timeZone = TimeZone(secondsFromGMT: 0)
                    if let date = dateFormatter.date(from: createdAtString) {
                        createdAt = date
                    } else {
                        throw DecodingError.dataCorruptedError(
                            forKey: .createdAt,
                            in: container,
                            debugDescription: "Date string does not match expected format: \(createdAtString)"
                        )
                    }
                }
            }
        } else {
            throw DecodingError.keyNotFound(
                CodingKeys.createdAt,
                DecodingError.Context(codingPath: decoder.codingPath, debugDescription: "created_at is missing")
            )
        }
        
        // Decode updated_at (same logic)
        if let updatedAtString = try? container.decode(String.self, forKey: .updatedAt) {
            if let date = iso8601Formatter.date(from: updatedAtString) {
                updatedAt = date
            } else {
                iso8601Formatter.formatOptions = [.withInternetDateTime]
                if let date = iso8601Formatter.date(from: updatedAtString) {
                    updatedAt = date
                } else {
                    dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
                    if let date = dateFormatter.date(from: updatedAtString) {
                        updatedAt = date
                    } else {
                        throw DecodingError.dataCorruptedError(
                            forKey: .updatedAt,
                            in: container,
                            debugDescription: "Date string does not match expected format: \(updatedAtString)"
                        )
                    }
                }
            }
        } else {
            throw DecodingError.keyNotFound(
                CodingKeys.updatedAt,
                DecodingError.Context(codingPath: decoder.codingPath, debugDescription: "updated_at is missing")
            )
        }
    }
}
