import SwiftUI

@main
struct ZiweiFortuneApp: App {
    @StateObject private var clientStore = ClientStore()
    @StateObject private var chartStore = ChartStore()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(clientStore)
                .environmentObject(chartStore)
        }
        .windowStyle(.hiddenTitleBar)
        .windowToolbarStyle(.unified)
    }
}