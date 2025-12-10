//
//  AudioService.swift
//  trailmemo
//
//  Created by Thomas Fitzgerald on 12/10/25.
//

import Foundation
import AVFoundation
internal import Combine

class AudioService: NSObject, ObservableObject {
    @Published var isRecording = false
    @Published var recordingDuration: TimeInterval = 0
    @Published var audioLevel: Float = 0 // For visual feedback
    
    private var audioRecorder: AVAudioRecorder?
    private var audioFileURL: URL?
    private var levelTimer: Timer?
    
    // MARK: - Request Microphone Permission
    func requestMicrophonePermission() async -> Bool {
        await withCheckedContinuation { continuation in
            AVAudioSession.sharedInstance().requestRecordPermission { granted in
                continuation.resume(returning: granted)
            }
        }
    }
    
    // MARK: - Start Recording
    func startRecording() throws -> URL {
        // Configure audio session
        let audioSession = AVAudioSession.sharedInstance()
        try audioSession.setCategory(.record, mode: .default)
        try audioSession.setActive(true)
        
        // Create unique file URL
        let fileName = "memo_\(UUID().uuidString).m4a"
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        audioFileURL = documentsPath.appendingPathComponent(fileName)
        
        guard let url = audioFileURL else {
            throw NSError(domain: "AudioService", code: -1, userInfo: [NSLocalizedDescriptionKey: "Failed to create audio file URL"])
        }
        
        // Configure recording settings (AAC, 44.1kHz, mono)
        let settings: [String: Any] = [
            AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
            AVSampleRateKey: 44100.0,
            AVNumberOfChannelsKey: 1,
            AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue,
            AVEncoderBitRateKey: 64000 // 64kbps for good quality, small file
        ]
        
        // Create and start recorder
        audioRecorder = try AVAudioRecorder(url: url, settings: settings)
        audioRecorder?.delegate = self
        audioRecorder?.isMeteringEnabled = true
        audioRecorder?.prepareToRecord()
        
        guard audioRecorder?.record() == true else {
            throw NSError(domain: "AudioService", code: -2, userInfo: [NSLocalizedDescriptionKey: "Failed to start recording"])
        }
        
        isRecording = true
        startLevelMonitoring()
        
        return url
    }
    
    // MARK: - Stop Recording
    func stopRecording() -> (url: URL?, duration: TimeInterval) {
        let duration = audioRecorder?.currentTime ?? 0
        
        audioRecorder?.stop()
        stopLevelMonitoring()
        
        isRecording = false
        recordingDuration = 0
        
        // Deactivate audio session
        try? AVAudioSession.sharedInstance().setActive(false)
        
        return (audioFileURL, duration)
    }
    
    // MARK: - Level Monitoring (for visual feedback)
    private func startLevelMonitoring() {
        levelTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
            guard let self = self, let recorder = self.audioRecorder else { return }
            
            recorder.updateMeters()
            let level = recorder.averagePower(forChannel: 0)
            
            // Convert dB to 0-1 range
            let normalizedLevel = max(0.0, min(1.0, (level + 50) / 50))
            self.audioLevel = normalizedLevel
            self.recordingDuration = recorder.currentTime
        }
    }
    
    private func stopLevelMonitoring() {
        levelTimer?.invalidate()
        levelTimer = nil
        audioLevel = 0
    }
    
    // MARK: - Get Audio Duration
    func getAudioDuration(url: URL) async -> TimeInterval {
        let asset = AVURLAsset(url: url)
        guard let duration = try? await asset.load(.duration) else {
            return 0
        }
        return duration.seconds
    }
    
    // MARK: - Delete Audio File
    func deleteAudioFile(url: URL) {
        try? FileManager.default.removeItem(at: url)
    }
}

// MARK: - AVAudioRecorderDelegate
extension AudioService: AVAudioRecorderDelegate {
    func audioRecorderDidFinishRecording(_ recorder: AVAudioRecorder, successfully flag: Bool) {
        if !flag {
            print("Recording failed")
        }
    }
}
