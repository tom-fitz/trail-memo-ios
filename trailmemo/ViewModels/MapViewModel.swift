//
//  MapViewModel.swift
//  trailmemo
//
//  Created by Thomas Fitzgerald on 12/9/25.
//

import Foundation
import MapboxMaps
import CoreLocation
internal import Combine

@MainActor
class MapViewModel: ObservableObject {
    @Published var memos: [Memo] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var selectedMemo: Memo?
    
    // Map state
    @Published var mapStyle: String = "mapbox://styles/mapbox/outdoors-v12"
    @Published var cameraPosition: CameraOptions
    
    // Available map styles (matching web app)
    let mapStyles: [(name: String, url: String, description: String)] = [
        ("Outdoors", "mapbox://styles/mapbox/outdoors-v12", "Parks & trails highlighted"),
        ("Satellite", "mapbox://styles/mapbox/satellite-streets-v12", "Aerial view with labels"),
        ("Streets", "mapbox://styles/mapbox/streets-v12", "Standard street map")
    ]
    
    init() {
        // Default camera position
        self.cameraPosition = CameraOptions(
            center: CLLocationCoordinate2D(
                latitude: Config.defaultMapLatitude,
                longitude: Config.defaultMapLongitude
            ),
            zoom: Config.defaultMapZoom
        )
    }
    
    // MARK: - Fetch Memos
    func fetchMemos() async {
        isLoading = true
        errorMessage = nil
        
        do {
            let fetchedMemos = try await APIClient.shared.fetchMemos()
            self.memos = fetchedMemos
            
            // Center map on first memo if available
            if let firstMemo = fetchedMemos.first,
               let location = firstMemo.location {
                self.cameraPosition = CameraOptions(
                    center: CLLocationCoordinate2D(
                        latitude: location.latitude,
                        longitude: location.longitude
                    ),
                    zoom: 12.0
                )
            }
            
            isLoading = false
        } catch {
            isLoading = false
            errorMessage = error.localizedDescription
            print("Error fetching memos: \(error)")
        }
    }
    
    // MARK: - Refresh
    func refresh() {
        Task {
            await fetchMemos()
        }
    }
    
    // MARK: - Change Map Style
    func setMapStyle(url: String) {
        mapStyle = url
    }
    
    // MARK: - Select Memo
    func selectMemo(_ memo: Memo) {
        selectedMemo = memo
    }
    
    func deselectMemo() {
        selectedMemo = nil
    }
}
