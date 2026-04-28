import SwiftUI

enum ContentTab {
    case charting
    case clients
    case matching
}

struct ContentView: View {
    @EnvironmentObject var clientStore: ClientStore
    @State private var selectedTab: ContentTab = .charting
    @State private var selectedClient: Client?
    @State private var showingSettings = false

    var body: some View {
        TabView(selection: $selectedTab) {
            ChartingView(selectedClient: $selectedClient)
                .tabItem {
                    Label(L(StringKey.tabCharting), systemImage: "chart.bar.doc.horizontal")
                }
                .tag(ContentTab.charting)

            ClientListView(selectedClient: $selectedClient, selectedTab: $selectedTab)
                .tabItem {
                    Label(L(StringKey.tabClients), systemImage: "person.2")
                }
                .tag(ContentTab.clients)

            CoupleMatchingView()
                .tabItem {
                    Label(L(StringKey.tabMatching), systemImage: "heart")
                }
                .tag(ContentTab.matching)
        }
        .frame(minWidth: 1200, minHeight: 860)
        .toolbar {
            ToolbarItem(placement: .navigation) {
                Button {
                    showingSettings = true
                } label: {
                    Image(systemName: "gearshape")
                }
                .help(L(StringKey.settings))
            }
        }
        .sheet(isPresented: $showingSettings) {
            SettingsView()
        }
    }
}

#Preview {
    ContentView()
        .environmentObject(ClientStore())
        .environmentObject(ChartStore())
}