//
//  APIClient.swift
//  trailmemo
//
//  Created by Thomas Fitzgerald on 12/9/25.
//

import Foundation
import FirebaseAuth

enum APIError: Error {
    case invalidURL
    case noData
    case decodingError
    case unauthorized
    case serverError(String)
    case networkError(Error)
}

class APIClient {
    static let shared = APIClient()
    
    private init() {}
    
    // MARK: - Fetch All Memos
    func fetchMemos() async throws -> [Memo] {
        guard let url = URL(string: "\(Config.apiBaseURL)/api/v1/memos") else {
            throw APIError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        
        // Add Firebase auth token
        if let token = try? await Auth.auth().currentUser?.getIDToken() {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                throw APIError.serverError("Invalid response")
            }
            
            guard (200...299).contains(httpResponse.statusCode) else {
                throw APIError.serverError("Status code: \(httpResponse.statusCode)")
            }
            
            // Parse response
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            
            struct MemosResponse: Codable {
                let memos: [Memo]
            }
            
            let memosResponse = try decoder.decode(MemosResponse.self, from: data)
            return memosResponse.memos
        } catch let error as APIError {
            throw error
        } catch {
            throw APIError.networkError(error)
        }
    }
    
    // MARK: - Fetch Single Memo
    func fetchMemo(id: UUID) async throws -> Memo {
        guard let url = URL(string: "\(Config.apiBaseURL)/api/v1/memos/\(id.uuidString)") else {
            throw APIError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        
        if let token = try? await Auth.auth().currentUser?.getIDToken() {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode) else {
            throw APIError.serverError("Failed to fetch memo")
        }
        
        let decoder = JSONDecoder()
//        letting custom decoded do it.
//        decoder.dateDecodingStrategy = .iso8601
        return try decoder.decode(Memo.self, from: data)
    }
    
    // MARK: - Delete Memo
    func deleteMemo(id: UUID) async throws {
        guard let url = URL(string: "\(Config.apiBaseURL)/api/v1/memos/\(id.uuidString)") else {
            throw APIError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "DELETE"
        
        if let token = try? await Auth.auth().currentUser?.getIDToken() {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        
        let (_, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode) else {
            throw APIError.serverError("Failed to delete memo")
        }
    }
}
