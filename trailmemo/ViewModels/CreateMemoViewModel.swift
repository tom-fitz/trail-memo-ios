//
//  CreateMemoViewModel.swift
//  trailmemo
//
//  Created by Thomas Fitzgerald on 12/10/25.
//

import Foundation
import FirebaseAuth
import CoreLocation
internal import Combine

enum RecordingState {
    case idle
    case recording
    case processing
    case stopped
    case uploading
    case complete
    case error(String)
}

@MainActor
class CreateMemoViewModel: ObservableObject {
    @Published var recordingState: RecordingState = .idle
    @Published var transcribedText = ""
    @Published var recordingDuration: TimeInterval = 0
    @Published var audioLevel: Float = 0
    
    // Optional fields
    @Published var title = ""
    @Published var parkName = ""
    
    private let audioService = AudioService()
    private let speechService = SpeechRecognitionService()
    private let locationService = LocationService()
    
    private var audioFileURL: URL?
    
    var isRecording: Bool {
        if case .recording = recordingState {
            return true
        }
        return false
    }
    
    var canSubmit: Bool {
        !transcribedText.isEmpty && audioFileURL != nil
    }
    
    // MARK: - Request Permissions
    func requestPermissions() async {
        // Request microphone
        let micGranted = await audioService.requestMicrophonePermission()
        guard micGranted else {
            recordingState = .error("Microphone permission denied")
            return
        }
        
        // Request speech recognition
        let speechGranted = await speechService.requestPermission()
        guard speechGranted else {
            recordingState = .error("Speech recognition permission denied")
            return
        }
        
        // Request location
        locationService.requestPermission()
    }
    
    // MARK: - Start Recording
    func startRecording() async {
        do {
            // Start audio recording
            audioFileURL = try audioService.startRecording()
            
            // Start speech recognition
            try speechService.startRecognition()
            
            recordingState = .recording
            
            // Monitor updates
            startMonitoring()
            
        } catch {
            recordingState = .error("Failed to start recording: \(error.localizedDescription)")
        }
    }
    
    // MARK: - Stop Recording
    func stopRecording() {
        // Stop audio recording
        let (url, duration) = audioService.stopRecording()
        audioFileURL = url
        recordingDuration = duration
        
        // Stop speech recognition
        speechService.stopRecognition()
        
        // Get final transcript
        transcribedText = speechService.getFinalTranscript()
        
        // Add debug logging
        print("🛑 Recording stopped")
        print("📝 Final transcript: \(transcribedText)")
        print("🎵 Audio URL: \(audioFileURL?.absoluteString ?? "none")")
        print("⏱️ Duration: \(duration) seconds")
        
        // Change to stopped state (not idle!)
        if transcribedText.isEmpty {
            recordingState = .error("No speech detected. Please try again.")
        } else {
            recordingState = .stopped  // NEW STATE
        }
    }
    
    // MARK: - Submit Memo
    func submitMemo() async {
        guard let audioURL = audioFileURL else {
            recordingState = .error("No audio file")
            return
        }
        
        guard !transcribedText.isEmpty else {
            recordingState = .error("No transcript available")
            return
        }
        
        recordingState = .uploading
        
        do {
            // Get current location
            let location = locationService.currentLocation
            
            // Get Firebase auth token
            guard let token = try? await Auth.auth().currentUser?.getIDToken() else {
                throw NSError(domain: "CreateMemo", code: -1,
                            userInfo: [NSLocalizedDescriptionKey: "Not authenticated"])
            }
            
            // Get user info
            guard let user = Auth.auth().currentUser else {
                throw NSError(domain: "CreateMemo", code: -2,
                            userInfo: [NSLocalizedDescriptionKey: "No user found"])
            }
            
            // Upload memo to API
            try await uploadMemo(
                audioURL: audioURL,
                text: transcribedText,
                title: title.isEmpty ? nil : title,
                parkName: parkName.isEmpty ? nil : parkName,
                location: location,
                token: token,
                userName: user.displayName ?? "Unknown User"
            )
            
            recordingState = .complete
            
            // Clean up
            cleanup()
            
        } catch {
            recordingState = .error("Upload failed: \(error.localizedDescription)")
        }
    }
    
    // MARK: - Upload to API
    private func uploadMemo(
        audioURL: URL,
        text: String,
        title: String?,
        parkName: String?,
        location: CLLocation?,
        token: String,
        userName: String
    ) async throws {
        print("🚀 Starting upload to: \(Config.apiBaseURL)/api/v1/memos")
        print("📝 Text length: \(text.count)")
        print("📍 Location: \(location?.coordinate.latitude ?? 0), \(location?.coordinate.longitude ?? 0)")
        
        guard let url = URL(string: "\(Config.apiBaseURL)/api/v1/memos") else {
            throw NSError(domain: "CreateMemo", code: -3,
                        userInfo: [NSLocalizedDescriptionKey: "Invalid API URL"])
        }
        
        // Create multipart request
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        
        let boundary = UUID().uuidString
        request.setValue("multipart/form-data; boundary=\(boundary)",
                        forHTTPHeaderField: "Content-Type")
        
        // Build multipart body
        var body = Data()
        
        // Add audio file
        let audioData = try Data(contentsOf: audioURL)
        print("🎵 Audio file size: \(audioData.count) bytes")
        body.append("--\(boundary)\r\n")
        body.append("Content-Disposition: form-data; name=\"audio\"; filename=\"memo.m4a\"\r\n")
        body.append("Content-Type: audio/m4a\r\n\r\n")
        body.append(audioData)
        body.append("\r\n")
        
        // Add text (REQUIRED)
        body.append("--\(boundary)\r\n")
        body.append("Content-Disposition: form-data; name=\"text\"\r\n\r\n")
        body.append("\(text)\r\n")
        
        // Add duration_seconds (REQUIRED)
        let duration = Int(recordingDuration)
        body.append("--\(boundary)\r\n")
        body.append("Content-Disposition: form-data; name=\"duration_seconds\"\r\n\r\n")
        body.append("\(duration)\r\n")
        
        // Add latitude (REQUIRED)
        if let location = location {
            body.append("--\(boundary)\r\n")
            body.append("Content-Disposition: form-data; name=\"latitude\"\r\n\r\n")
            body.append("\(location.coordinate.latitude)\r\n")
            
            // Add longitude (REQUIRED)
            body.append("--\(boundary)\r\n")
            body.append("Content-Disposition: form-data; name=\"longitude\"\r\n\r\n")
            body.append("\(location.coordinate.longitude)\r\n")
            
            // Add location_accuracy (OPTIONAL)
            body.append("--\(boundary)\r\n")
            body.append("Content-Disposition: form-data; name=\"location_accuracy\"\r\n\r\n")
            body.append("\(location.horizontalAccuracy)\r\n")
        } else {
            // Location is REQUIRED by your API, so throw error if missing
            throw NSError(domain: "CreateMemo", code: -5,
                        userInfo: [NSLocalizedDescriptionKey: "Location is required"])
        }
        
        // Add title (OPTIONAL)
        if let title = title, !title.isEmpty {
            body.append("--\(boundary)\r\n")
            body.append("Content-Disposition: form-data; name=\"title\"\r\n\r\n")
            body.append("\(title)\r\n")
        }
        
        // Add park_name (OPTIONAL)
        if let parkName = parkName, !parkName.isEmpty {
            body.append("--\(boundary)\r\n")
            body.append("Content-Disposition: form-data; name=\"park_name\"\r\n\r\n")
            body.append("\(parkName)\r\n")
        }
        
        body.append("--\(boundary)--\r\n")
        request.httpBody = body
        
        print("📦 Total body size: \(body.count) bytes")
        
        // Send request
        let (data, response) = try await URLSession.shared.data(for: request)
        
        print("📥 Response status: \((response as? HTTPURLResponse)?.statusCode ?? -1)")
        if let responseString = String(data: data, encoding: .utf8) {
            print("📥 Response body: \(responseString)")
        }
        
        guard let httpResponse = response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode) else {
            throw NSError(domain: "CreateMemo", code: -4,
                        userInfo: [NSLocalizedDescriptionKey: "Server error"])
        }
        
        print("✅ Upload successful!")
    }
    
    // MARK: - Monitoring
    private func startMonitoring() {
        Task {
            while isRecording {
                transcribedText = speechService.transcribedText
                recordingDuration = audioService.recordingDuration
                audioLevel = audioService.audioLevel
                
                try? await Task.sleep(nanoseconds: 100_000_000) // 0.1 seconds
            }
        }
    }
    
    // MARK: - Cancel
    func cancel() {
        if isRecording {
            stopRecording()
        }
        cleanup()
        recordingState = .idle
    }
    
    // MARK: - Cleanup
    private func cleanup() {
        if let audioURL = audioFileURL {
            audioService.deleteAudioFile(url: audioURL)
        }
        audioFileURL = nil
        transcribedText = ""
        title = ""
        parkName = ""
        recordingDuration = 0
        audioLevel = 0
    }
}

// Helper extension for Data
extension Data {
    mutating func append(_ string: String) {
        if let data = string.data(using: .utf8) {
            append(data)
        }
    }
}
