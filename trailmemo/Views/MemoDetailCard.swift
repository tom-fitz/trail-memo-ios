//
//  MemoDetailView.swift
//  trailmemo
//
//  Created by Thomas Fitzgerald on 12/10/2025
//

import SwiftUI
import AVFoundation
import MapKit
internal import Combine

struct MemoDetailCard: View {
    let memo: Memo
    @Environment(\.dismiss) var dismiss
    @StateObject private var audioPlayer = AudioPlayerService()
    @State private var showDeleteConfirmation = false
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Header Section
                    headerSection
                    
                    // Audio Player Section
                    // audioPlayerSection
                    
                    // Transcript Section
                    transcriptSection
                    
                    // Location Section
                    if let location = memo.location {
                        locationSection(location: location)
                    }
                    
                    // Metadata Section
                    metadataSection
                }
                .padding()
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle(memo.title ?? "Memo")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Close") {
                        audioPlayer.stop()
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Menu {
                        Button(role: .destructive) {
                            showDeleteConfirmation = true
                        } label: {
                            Label("Delete", systemImage: "trash")
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                    }
                }
            }
            .alert("Delete Memo?", isPresented: $showDeleteConfirmation) {
                Button("Cancel", role: .cancel) { }
                Button("Delete", role: .destructive) {
                    // TODO: Implement delete
                    dismiss()
                }
            } message: {
                Text("This action cannot be undone.")
            }
        }
        .onAppear {
            audioPlayer.loadAudio(url: memo.audioURL)
        }
        .onDisappear {
            audioPlayer.stop()
        }
    }
    
    // MARK: - Header Section
    private var headerSection: some View {
        HStack(spacing: 12) {
            // User avatar
            ZStack {
                Circle()
                    .fill(getUserColor(userId: memo.userId))
                    .frame(width: 50, height: 50)
                
                Text(getUserInitials(name: memo.userName))
                    .font(.headline)
                    .foregroundColor(.white)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(memo.userName)
                    .font(.headline)
                    .foregroundColor(.primary)
                
                Text(memo.createdAt.timeAgo())
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                // Park name
                if let parkName = memo.parkName {
                    HStack(spacing: 4) {
                        Image(systemName: "map.fill")
                            .font(.caption2)
                        Text(parkName)
                            .font(.caption)
                            .fontWeight(.medium)
                    }
                    .foregroundColor(.green)
                }
            }
            
            Spacer()
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
    }
    
    // MARK: - Audio Player Section
//    private var audioPlayerSection: some View {
//        VStack(spacing: 16) {
//            // Section header
//            HStack {
//                Image(systemName: "waveform")
//                    .foregroundColor(.blue)
//                Text("Audio Recording")
//                    .font(.headline)
//                    .foregroundColor(.primary)
//                Spacer()
//                Text(formatDuration(memo.durationSeconds))
//                    .font(.caption)
//                    .foregroundColor(.secondary)
//            }
//            
//            VStack(spacing: 16) {
//                // Waveform
//                HStack(spacing: 2) {
//                    ForEach(0..<40, id: \.self) { index in
//                        RoundedRectangle(cornerRadius: 2)
//                            .fill(
//                                audioPlayer.currentTime > 0 &&
//                                Double(index) / 40.0 < (audioPlayer.currentTime / max(audioPlayer.duration, 1))
//                                    ? Color.blue
//                                    : Color.gray.opacity(0.3)
//                            )
//                            .frame(width: 4, height: CGFloat.random(in: 15...45))
//                    }
//                }
//                .frame(height: 60)
//                
//                // Progress slider
//                VStack(spacing: 8) {
//                    Slider(
//                        value: Binding(
//                            get: { audioPlayer.currentTime },
//                            set: { audioPlayer.seek(to: $0) }
//                        ),
//                        in: 0...max(audioPlayer.duration, 1)
//                    )
//                    .tint(.blue)
//                    
//                    // Time labels
//                    HStack {
//                        Text(formatTime(audioPlayer.currentTime))
//                            .font(.caption)
//                            .foregroundColor(.secondary)
//                            .monospacedDigit()
//                        
//                        Spacer()
//                        
//                        Text(formatTime(audioPlayer.duration))
//                            .font(.caption)
//                            .foregroundColor(.secondary)
//                            .monospacedDigit()
//                    }
//                }
//                
//                // Playback controls
//                HStack(spacing: 40) {
//                    // Rewind
//                    Button(action: {
//                        audioPlayer.skip(seconds: -15)
//                    }) {
//                        Image(systemName: "gobackward.15")
//                            .font(.title2)
//                            .foregroundColor(.blue)
//                    }
//                    .disabled(audioPlayer.currentTime == 0)
//                    
//                    // Play/Pause
//                    Button(action: {
//                        audioPlayer.togglePlayPause()
//                    }) {
//                        Image(systemName: audioPlayer.isPlaying ? "pause.circle.fill" : "play.circle.fill")
//                            .font(.system(size: 64))
//                            .foregroundColor(.blue)
//                    }
//                    .disabled(audioPlayer.isLoading)
//                    
//                    // Forward
//                    Button(action: {
//                        audioPlayer.skip(seconds: 15)
//                    }) {
//                        Image(systemName: "goforward.15")
//                            .font(.title2)
//                            .foregroundColor(.blue)
//                    }
//                    .disabled(audioPlayer.currentTime >= audioPlayer.duration)
//                }
//                .padding(.vertical, 8)
//                
//                // Status indicators
//                if audioPlayer.isLoading {
//                    HStack(spacing: 8) {
//                        ProgressView()
//                            .scaleEffect(0.8)
//                        Text("Loading audio...")
//                            .font(.caption)
//                            .foregroundColor(.secondary)
//                    }
//                }
//                
//                if let error = audioPlayer.errorMessage {
//                    Text(error)
//                        .font(.caption)
//                        .foregroundColor(.red)
//                        .multilineTextAlignment(.center)
//                }
//            }
//        }
//        .padding()
//        .background(Color(.systemBackground))
//        .cornerRadius(12)
//        .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
//    }
    
    // MARK: - Transcript Section
    private var transcriptSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "text.quote")
                    .foregroundColor(.blue)
                Text("Transcript")
                    .font(.headline)
                    .foregroundColor(.primary)
                Spacer()
            }
            
            Text(memo.text)
                .font(.body)
                .foregroundColor(.primary)
                .lineSpacing(6)
                .padding(.top, 4)
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
    }
    
    // MARK: - Location Section
    private func locationSection(location: Memo.Location) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "location.fill")
                    .foregroundColor(.blue)
                Text("Location")
                    .font(.headline)
                    .foregroundColor(.primary)
                Spacer()
            }
            
            // Mini map
            Map(coordinateRegion: .constant(MKCoordinateRegion(
                center: location.coordinate,
                span: MKCoordinateSpan(latitudeDelta: 0.0005, longitudeDelta: 0.0005)
            )), annotationItems: [memo]) { _ in
                MapMarker(coordinate: location.coordinate, tint: .blue)
            }
            .frame(height: 180)
            .cornerRadius(8)
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(Color.gray.opacity(0.2), lineWidth: 1)
            )
            
            // Coordinates
            VStack(spacing: 6) {
                HStack {
                    Text("Latitude")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Spacer()
                    Text(String(format: "%.6f°", location.latitude))
                        .font(.caption)
                        .foregroundColor(.primary)
                        .fontWeight(.medium)
                }
                
                HStack {
                    Text("Longitude")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Spacer()
                    Text(String(format: "%.6f°", location.longitude))
                        .font(.caption)
                        .foregroundColor(.primary)
                        .fontWeight(.medium)
                }
                
                HStack {
                    Text("Accuracy")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Spacer()
                    Text(String(format: "±%.1f meters", location.accuracy))
                        .font(.caption)
                        .foregroundColor(.primary)
                        .fontWeight(.medium)
                }
            }
            .padding(.top, 8)
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
    }
    
    // MARK: - Metadata Section
    private var metadataSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "info.circle")
                    .foregroundColor(.blue)
                Text("Details")
                    .font(.headline)
                    .foregroundColor(.primary)
                Spacer()
            }
            
            VStack(spacing: 10) {
                HStack {
                    Text("Duration")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    Spacer()
                    Text(formatDuration(memo.durationSeconds))
                        .font(.subheadline)
                        .foregroundColor(.primary)
                        .fontWeight(.medium)
                }
                
                Divider()
                
                HStack {
                    Text("Created")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    Spacer()
                    Text(formatFullDate(memo.createdAt))
                        .font(.subheadline)
                        .foregroundColor(.primary)
                        .fontWeight(.medium)
                }
                
                Divider()
                
                HStack {
                    Text("Last Updated")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    Spacer()
                    Text(formatFullDate(memo.updatedAt))
                        .font(.subheadline)
                        .foregroundColor(.primary)
                        .fontWeight(.medium)
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
    }
    
    // MARK: - Helper Functions
    private func formatTime(_ seconds: Double) -> String {
        let mins = Int(seconds) / 60
        let secs = Int(seconds) % 60
        return String(format: "%d:%02d", mins, secs)
    }
    
    private func formatDuration(_ seconds: Int) -> String {
        let mins = seconds / 60
        let secs = seconds % 60
        if mins > 0 {
            return "\(mins)m \(secs)s"
        } else {
            return "\(secs)s"
        }
    }
    
    private func formatFullDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}

// MARK: - Audio Player Service
class AudioPlayerService: ObservableObject {
    @Published var isPlaying = false
    @Published var isLoading = false
    @Published var currentTime: Double = 0
    @Published var duration: Double = 0
    @Published var errorMessage: String?
    
    private var player: AVPlayer?
    private var timeObserver: Any?
    
    func loadAudio(url: String) {
        isLoading = true
        errorMessage = nil
        
        guard let audioURL = URL(string: url) else {
            errorMessage = "Invalid audio URL"
            isLoading = false
            return
        }
        
        player = AVPlayer(url: audioURL)
        
        // Observe player status
        player?.currentItem?.asset.loadValuesAsynchronously(forKeys: ["duration"]) { [weak self] in
            DispatchQueue.main.async {
                guard let self = self,
                      let duration = self.player?.currentItem?.asset.duration else {
                    self?.errorMessage = "Failed to load audio"
                    self?.isLoading = false
                    return
                }
                
                self.duration = CMTimeGetSeconds(duration)
                self.isLoading = false
            }
        }
        
        // Add time observer
        let interval = CMTime(seconds: 0.1, preferredTimescale: CMTimeScale(NSEC_PER_SEC))
        timeObserver = player?.addPeriodicTimeObserver(forInterval: interval, queue: .main) { [weak self] time in
            self?.currentTime = CMTimeGetSeconds(time)
        }
        
        // Observe playback end
        NotificationCenter.default.addObserver(
            forName: .AVPlayerItemDidPlayToEndTime,
            object: player?.currentItem,
            queue: .main
        ) { [weak self] _ in
            self?.isPlaying = false
            self?.player?.seek(to: .zero)
            self?.currentTime = 0
        }
    }
    
    func togglePlayPause() {
        guard let player = player else { return }
        
        if isPlaying {
            player.pause()
        } else {
            player.play()
        }
        isPlaying.toggle()
    }
    
    func seek(to time: Double) {
        let cmTime = CMTime(seconds: time, preferredTimescale: CMTimeScale(NSEC_PER_SEC))
        player?.seek(to: cmTime)
    }
    
    func skip(seconds: Double) {
        let newTime = max(0, min(duration, currentTime + seconds))
        seek(to: newTime)
    }
    
    func stop() {
        player?.pause()
        player?.seek(to: .zero)
        isPlaying = false
        currentTime = 0
    }
    
    deinit {
        if let timeObserver = timeObserver {
            player?.removeTimeObserver(timeObserver)
        }
        NotificationCenter.default.removeObserver(self)
    }
}
