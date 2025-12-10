//
//  MapboxMapView.swift
//  trailmemo
//
//  Created by Thomas Fitzgerald on 12/10/25.
//

import SwiftUI
import MapboxMaps

struct MapboxMapView: UIViewRepresentable {
    let memos: [Memo]
    let mapStyle: String
    let cameraPosition: CameraOptions
    let onMemoTap: (Memo) -> Void
    
    func makeUIView(context: Context) -> MapboxMaps.MapView {
        // Set the access token
        MapboxOptions.accessToken = Config.mapboxAccessToken
        
        let mapInitOptions = MapInitOptions(
            styleURI: StyleURI(rawValue: mapStyle)
        )
        
        let mapView = MapboxMaps.MapView(frame: .zero, mapInitOptions: mapInitOptions)
        
        // Set camera position
        mapView.mapboxMap.setCamera(to: cameraPosition)
        
        // Store coordinator reference
        context.coordinator.mapView = mapView
        context.coordinator.onMemoTap = onMemoTap
        
        return mapView
    }
    
    func updateUIView(_ mapView: MapboxMaps.MapView, context: Context) {
        // Update style if changed
        if mapView.mapboxMap.styleURI?.rawValue != mapStyle {
            mapView.mapboxMap.loadStyle(StyleURI(rawValue: mapStyle)!)
        }
        
        // Update annotations
        context.coordinator.updateAnnotations(memos: memos, mapView: mapView)
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator()
    }
    
    class Coordinator: NSObject {
        var mapView: MapboxMaps.MapView?
        var onMemoTap: ((Memo) -> Void)?
        var currentAnnotations: [Memo] = []
        var pointAnnotationManager: PointAnnotationManager?
        
        func updateAnnotations(memos: [Memo], mapView: MapboxMaps.MapView) {
            // Only update if memos changed
            guard memos != currentAnnotations else { return }
            currentAnnotations = memos
            
            // Create or reuse point annotation manager
            if pointAnnotationManager == nil {
                pointAnnotationManager = mapView.annotations.makePointAnnotationManager()
            }
            
            guard let pointAnnotationManager = pointAnnotationManager else { return }
            
            // Build new annotations
            var annotations: [PointAnnotation] = []
            
            for memo in memos {
                guard let location = memo.location else { continue }
                
                var annotation = PointAnnotation(coordinate: CLLocationCoordinate2D(
                    latitude: location.latitude,
                    longitude: location.longitude
                ))
                
                // Create custom icon with user color and initials
                let color = UIColor(getUserColor(userId: memo.userId))
                let initials = getUserInitials(name: memo.userName)
                
                if let image = createMarkerImage(initials: initials, color: color) {
                    annotation.image = .init(image: image, name: memo.id.uuidString)
                }
                
                // Store memo ID for tap handling
                annotation.customData = ["memoId": .string(memo.id.uuidString)]
                
                // Add tap handler
                annotation.tapHandler = { [weak self] _ in
                    guard let self = self,
                          case .string(let memoIdString) = annotation.customData["memoId"],
                          let memoId = UUID(uuidString: memoIdString),
                          let memo = self.currentAnnotations.first(where: { $0.id == memoId }) else {
                        return true
                    }
                    
                    self.onMemoTap?(memo)
                    return true
                }
                
                annotations.append(annotation)
            }
            
            // Replace all annotations at once
            pointAnnotationManager.annotations = annotations
        }
        
        // Create custom marker image
        private func createMarkerImage(initials: String, color: UIColor) -> UIImage? {
            let size = CGSize(width: 44, height: 52)
            let renderer = UIGraphicsImageRenderer(size: size)
            
            return renderer.image { context in
                let ctx = context.cgContext
                
                // Draw shield shape
                let path = UIBezierPath()
                path.move(to: CGPoint(x: 22, y: 5))
                path.addLine(to: CGPoint(x: 37, y: 10.5))
                path.addLine(to: CGPoint(x: 37, y: 24))
                path.addCurve(
                    to: CGPoint(x: 22, y: 45.5),
                    controlPoint1: CGPoint(x: 37, y: 31.5),
                    controlPoint2: CGPoint(x: 33, y: 37.5)
                )
                path.addCurve(
                    to: CGPoint(x: 7, y: 24),
                    controlPoint1: CGPoint(x: 11, y: 37.5),
                    controlPoint2: CGPoint(x: 7, y: 31.5)
                )
                path.addLine(to: CGPoint(x: 7, y: 10.5))
                path.close()
                
                // Fill with gradient
                ctx.saveGState()
                path.addClip()
                
                let colors = [color.cgColor, color.withAlphaComponent(0.7).cgColor]
                let gradient = CGGradient(
                    colorsSpace: CGColorSpaceCreateDeviceRGB(),
                    colors: colors as CFArray,
                    locations: [0.0, 1.0]
                )!
                
                ctx.drawLinearGradient(
                    gradient,
                    start: CGPoint(x: 22, y: 5),
                    end: CGPoint(x: 22, y: 45.5),
                    options: []
                )
                ctx.restoreGState()
                
                // Draw border
                UIColor.white.setStroke()
                path.lineWidth = 2
                path.stroke()
                
                // Draw initials
                let attrs: [NSAttributedString.Key: Any] = [
                    .font: UIFont.systemFont(ofSize: 14, weight: .bold),
                    .foregroundColor: UIColor.white
                ]
                let string = initials as NSString
                let stringSize = string.size(withAttributes: attrs)
                let rect = CGRect(
                    x: (size.width - stringSize.width) / 2,
                    y: 15,
                    width: stringSize.width,
                    height: stringSize.height
                )
                string.draw(in: rect, withAttributes: attrs)
            }
        }
    }
}


// Make Memo equatable for comparison
extension Memo: Equatable {
    static func == (lhs: Memo, rhs: Memo) -> Bool {
        lhs.id == rhs.id
    }
}
