import SwiftUI

struct RootTabView: View {
    @StateObject private var engine = DetectionEngine()

    var body: some View {
        TabView {
            DashboardView(engine: engine)
                .tabItem { Label("Dashboard", systemImage: "shield.lefthalf.filled") }
            DemoModeView(engine: engine)
                .tabItem { Label("Demo", systemImage: "play.circle.fill") }
            RideMapView(engine: engine)
                .tabItem { Label("Ride", systemImage: "map.fill") }
            DetectionHistoryView(engine: engine)
                .tabItem { Label("History", systemImage: "list.bullet.rectangle") }
            SettingsView()
                .tabItem { Label("Settings", systemImage: "gearshape.fill") }
        }
        .preferredColorScheme(.dark)
    }
}
