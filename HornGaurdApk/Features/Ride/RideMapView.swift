import SwiftUI
import MapKit
import CoreLocation

struct RideMapView: View {
    @ObservedObject var engine: DetectionEngine
    @State private var camera: MapCameraPosition = .userLocation(fallback: .automatic)

    var body: some View {
        NavigationStack {
            Map(position: $camera) {
                UserAnnotation()

                // Route polyline
                if engine.location.route.count > 1 {
                    MapPolyline(coordinates: engine.location.route)
                        .stroke(Color.green, lineWidth: 3)
                }

                // Horn detection pins
                ForEach(engine.history.filter { $0.latitude != nil }) { d in
                    let coord = CLLocationCoordinate2D(latitude: d.latitude!, longitude: d.longitude!)
                    Annotation(d.timestamp.formatted(date: .omitted, time: .shortened), coordinate: coord) {
                        ZStack {
                            Circle().fill(.orange).frame(width: 22, height: 22)
                            Image(systemName: "exclamationmark")
                                .font(.caption.weight(.bold))
                                .foregroundStyle(.black)
                        }
                    }
                }
            }
            .mapStyle(.standard(elevation: .realistic))
            .navigationTitle("Ride")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Clear") { engine.location.clearRoute() }
                        .disabled(engine.location.route.isEmpty)
                }
            }
            .overlay(alignment: .bottom) {
                if !engine.location.authorized {
                    Text("Location permission required for ride mapping")
                        .font(.caption)
                        .padding(8)
                        .background(.ultraThinMaterial, in: Capsule())
                        .padding(.bottom, 12)
                }
            }
        }
    }
}
