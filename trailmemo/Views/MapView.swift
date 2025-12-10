//
//  MapView.swift
//  trailmemo
//
//  Created by Thomas Fitzgerald on 12/10/25.
//

import SwiftUI
import MapboxMaps

struct MapView: View {
    @StateObject private var viewModel = MapViewModel()
    @ObservedObject var authViewModel: AuthViewModel
    @State private var showStylePicker = false
    
    var body: some View {
        ZStack {
            // Mapbox Map
            MapboxMapView(
                memos: viewModel.memos,
                mapStyle: viewModel.mapStyle,
                cameraPosition: viewModel.cameraPosition,
                onMemoTap: { memo in
                    viewModel.selectMemo(memo)
                }
            )
            .ignoresSafeArea()
            
            // Loading overlay
            if viewModel.isLoading && viewModel.memos.isEmpty {
                Color.black.opacity(0.3)
                    .ignoresSafeArea()
                
                VStack(spacing: 16) {
                    ProgressView()
                        .scaleEffect(1.5)
                        .tint(.white)
                    Text("Loading memos...")
                        .foregroundColor(.white)
                        .font(.headline)
                }
                .padding(32)
                .background(Color.white)
                .cornerRadius(12)
                .shadow(radius: 10)
            }
            
            // Error message
            if let errorMessage = viewModel.errorMessage {
                VStack {
                    HStack {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundColor(.red)
                        Text(errorMessage)
                            .font(.caption)
                        Spacer()
                        Button("Retry") {
                            viewModel.refresh()
                        }
                        .font(.caption.bold())
                    }
                    .padding()
                    .background(Color.white)
                    .cornerRadius(8)
                    .shadow(radius: 5)
                    .padding()
                    Spacer()
                }
            }
            
            // Map controls overlay
            VStack {
                HStack {
                    // Style picker button
                    VStack(spacing: 12) {
                        Button(action: {
                            showStylePicker.toggle()
                        }) {
                            Image(systemName: "map")
                                .font(.system(size: 20))
                                .foregroundColor(.gray)
                                .frame(width: 44, height: 44)
                                .background(Color.white)
                                .cornerRadius(8)
                                .shadow(radius: 3)
                        }
                        
                        // Style picker dropdown
                        if showStylePicker {
                            VStack(spacing: 0) {
                                ForEach(viewModel.mapStyles, id: \.url) { style in
                                    Button(action: {
                                        viewModel.setMapStyle(url: style.url)
                                        showStylePicker = false
                                    }) {
                                        VStack(alignment: .leading, spacing: 4) {
                                            Text(style.name)
                                                .font(.system(size: 14, weight: .semibold))
                                                .foregroundColor(.primary)
                                            Text(style.description)
                                                .font(.system(size: 11))
                                                .foregroundColor(.secondary)
                                        }
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                        .padding(12)
                                        .background(
                                            viewModel.mapStyle == style.url
                                                ? Color.blue.opacity(0.1)
                                                : Color.clear
                                        )
                                    }
                                    
                                    if style.url != viewModel.mapStyles.last?.url {
                                        Divider()
                                    }
                                }
                            }
                            .background(Color.white)
                            .cornerRadius(8)
                            .shadow(radius: 5)
                            .frame(width: 200)
                        }
                    }
                    
                    Spacer()
                }
                .padding()
                
                Spacer()
                
                // Legend (bottom left)
                HStack {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Map Legend")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(.primary)
                        
                        HStack(spacing: 6) {
                            Rectangle()
                                .fill(Color.green.opacity(0.3))
                                .frame(width: 16, height: 16)
                                .cornerRadius(2)
                            Text("Parks & Recreation")
                                .font(.system(size: 11))
                                .foregroundColor(.secondary)
                        }
                        
                        HStack(spacing: 6) {
                            Rectangle()
                                .fill(Color.orange)
                                .frame(width: 16, height: 2)
                            Text("Trails & Paths")
                                .font(.system(size: 11))
                                .foregroundColor(.secondary)
                        }
                        
                        HStack(spacing: 6) {
                            Circle()
                                .fill(
                                    LinearGradient(
                                        colors: [.red, .blue, .green],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .frame(width: 16, height: 16)
                            Text("Memo Locations")
                                .font(.system(size: 11))
                                .foregroundColor(.secondary)
                        }
                    }
                    .padding(12)
                    .background(Color.white)
                    .cornerRadius(8)
                    .shadow(radius: 3)
                    .padding()
                    
                    Spacer()
                }
            }
            
            // Memo detail sheet
            if let memo = viewModel.selectedMemo {
                Color.black.opacity(0.3)
                    .ignoresSafeArea()
                    .onTapGesture {
                        viewModel.deselectMemo()
                    }
                
                VStack {
                    Spacer()
                    
                    MemoDetailCard(
                        memo: memo,
                        onClose: {
                            viewModel.deselectMemo()
                        }
                    )
                    .padding()
                }
            }
        }
        .task {
            await viewModel.fetchMemos()
        }
    }
}

#Preview {
    MapView(authViewModel: AuthViewModel())
}
