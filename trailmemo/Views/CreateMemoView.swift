//
//  CreateMemoView.swift
//  trailmemo
//
//  Created by Thomas Fitzgerald on 12/10/25.
//

import SwiftUI

struct CreateMemoView: View {
    @StateObject private var viewModel = CreateMemoViewModel()
    @Environment(\.dismiss) var dismiss
    let onMemoCreated: () -> Void
    
    var body: some View {
        NavigationView {
            ZStack {
                // Background
                LinearGradient(
                    colors: [Color.blue.opacity(0.1), Color.purple.opacity(0.1)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                
                VStack(spacing: 24) {
                    // Status indicator
                    statusView
                    
                    // Main content based on state
                    switch viewModel.recordingState {
                    case .idle:
                        idleView
                    case .recording:
                        recordingView
                    case .stopped:
                        stoppedView
                    case .processing:
                        processingView
                    case .uploading:
                        uploadingView
                    case .complete:
                        completeView
                    case .error(let message):
                        errorView(message: message)
                    }
                    
                    Spacer()
                }
                .padding()
            }
            .navigationTitle("New Memo")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        viewModel.cancel()
                        dismiss()
                    }
                }
            }
            .task {
                await viewModel.requestPermissions()
            }
        }
    }
    
    // MARK: - Status View
    private var statusView: some View {
        VStack(spacing: 8) {
            if viewModel.isRecording {
                HStack(spacing: 4) {
                    Circle()
                        .fill(Color.red)
                        .frame(width: 12, height: 12)
                        .opacity(0.8)
                        .animation(.easeInOut(duration: 1).repeatForever(autoreverses: true), value: viewModel.isRecording)
                    
                    Text("Recording")
                        .font(.headline)
                        .foregroundColor(.red)
                }
            }
            
            if viewModel.isRecording {
                Text(formatDuration(viewModel.recordingDuration))
                    .font(.system(.title, design: .monospaced))
                    .fontWeight(.medium)
            }
        }
    }
    
    // MARK: - Idle View
    private var idleView: some View {
        VStack(spacing: 32) {
            // Microphone icon
            Image(systemName: "mic.circle.fill")
                .font(.system(size: 100))
                .foregroundColor(.blue)
            
            VStack(spacing: 16) {
                Text("Ready to Record")
                    .font(.title2)
                    .fontWeight(.bold)
                
                Text("Tap the button below to start recording your voice memo. We'll transcribe it in real-time!")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }
            
            // Record button
            Button(action: {
                Task {
                    await viewModel.startRecording()
                }
            }) {
                HStack {
                    Image(systemName: "mic.fill")
                    Text("Start Recording")
                        .fontWeight(.semibold)
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.red)
                .foregroundColor(.white)
                .cornerRadius(12)
            }
            .padding(.horizontal, 32)
        }
    }
    
    // MARK: - Recording View
    private var recordingView: some View {
        VStack(spacing: 32) {
            // Audio level visualization
            audioWaveform
            
            // Transcript preview
            ScrollView {
                Text(viewModel.transcribedText.isEmpty ? "Listening..." : viewModel.transcribedText)
                    .font(.body)
                    .foregroundColor(viewModel.transcribedText.isEmpty ? .secondary : .primary)
                    .multilineTextAlignment(.leading)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding()
                    .background(Color.white.opacity(0.8))
                    .cornerRadius(12)
            }
            .frame(maxHeight: 200)
            
            // Stop button
            Button(action: {
                viewModel.stopRecording()
            }) {
                HStack {
                    Image(systemName: "stop.fill")
                    Text("Stop Recording")
                        .fontWeight(.semibold)
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.red)
                .foregroundColor(.white)
                .cornerRadius(12)
            }
            .padding(.horizontal, 32)
        }
    }
    
    // MARK: - Stopped View (ready to submit)
    private var stoppedView: some View {
        VStack(spacing: 24) {
            // Success indicator
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 60))
                .foregroundColor(.green)
            
            Text("Recording Complete!")
                .font(.title2)
                .fontWeight(.bold)
            
            // Show duration
            Text("Duration: \(formatDuration(viewModel.recordingDuration))")
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            // Transcript preview
            VStack(alignment: .leading, spacing: 8) {
                Text("Transcript:")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                ScrollView {
                    Text(viewModel.transcribedText)
                        .font(.body)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding()
                        .background(Color.white.opacity(0.8))
                        .cornerRadius(12)
                }
                .frame(height: 150)
            }
            
            // Optional fields
            VStack(spacing: 16) {
                TextField("Title (optional)", text: $viewModel.title)
                    .textFieldStyle(.roundedBorder)
                
                TextField("Park Name (optional)", text: $viewModel.parkName)
                    .textFieldStyle(.roundedBorder)
            }
            
            // Action buttons
            HStack(spacing: 16) {
                // Discard button
                Button(action: {
                    viewModel.cancel()
                    dismiss()
                }) {
                    HStack {
                        Image(systemName: "trash")
                        Text("Discard")
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.red.opacity(0.1))
                    .foregroundColor(.red)
                    .cornerRadius(12)
                }
                
                // Upload button
                Button(action: {
                    Task {
                        await viewModel.submitMemo()
                    }
                }) {
                    HStack {
                        Image(systemName: "arrow.up.circle.fill")
                        Text("Upload")
                            .fontWeight(.semibold)
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(12)
                }
                .disabled(!viewModel.canSubmit)
            }
            .padding(.horizontal, 32)
        }
        .padding()
    }
    
    // MARK: - Audio Waveform
    private var audioWaveform: some View {
        HStack(spacing: 4) {
            ForEach(0..<20, id: \.self) { _ in
                RoundedRectangle(cornerRadius: 2)
                    .fill(Color.blue)
                    .frame(width: 8, height: CGFloat.random(in: 20...80))
                    .animation(.easeInOut(duration: 0.3).repeatForever(autoreverses: true), value: viewModel.audioLevel)
            }
        }
        .frame(height: 80)
    }
    
    // MARK: - Processing View
    private var processingView: some View {
        VStack(spacing: 24) {
            ProgressView()
                .scaleEffect(1.5)
            
            Text("Processing...")
                .font(.headline)
        }
    }
    
    // MARK: - Uploading View
    private var uploadingView: some View {
        VStack(spacing: 24) {
            ProgressView()
                .scaleEffect(1.5)
            
            Text("Uploading memo...")
                .font(.headline)
        }
    }
    
    // MARK: - Complete View
    private var completeView: some View {
        VStack(spacing: 24) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 80))
                .foregroundColor(.green)
            
            Text("Memo Created!")
                .font(.title2)
                .fontWeight(.bold)
            
            Button("Done") {
                dismiss()
            }
            .buttonStyle(.borderedProminent)
        }
        .onAppear {
            print("✅ Complete view appeared - triggering callback")
                
            // Trigger map refresh
            onMemoCreated()
            
            print("✅ Callback triggered")
            
            // Auto-dismiss after 2 seconds
            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                print("✅ Dismissing create memo view")
                dismiss()
            }
        }
    }
    
    // MARK: - Error View
    private func errorView(message: String) -> some View {
        VStack(spacing: 24) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 60))
                .foregroundColor(.red)
            
            Text("Error")
                .font(.title2)
                .fontWeight(.bold)
            
            Text(message)
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            
            Button("Try Again") {
                viewModel.cancel()
            }
            .buttonStyle(.borderedProminent)
        }
    }
    
    // MARK: - Helper
    private func formatDuration(_ duration: TimeInterval) -> String {
        let minutes = Int(duration) / 60
        let seconds = Int(duration) % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
}

#Preview {
    CreateMemoView {
        // Preview callback
    }
}
