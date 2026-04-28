import SwiftUI

struct ClientListView: View {
    @EnvironmentObject var clientStore: ClientStore
    @Binding var selectedClient: Client?
    @Binding var selectedTab: ContentTab
    @State private var searchText = ""
    @State private var showingAddClient = false
    @State private var hoveredClientID: UUID? = nil

    var filteredClients: [Client] {
        if searchText.isEmpty {
            return clientStore.clients
        }
        return clientStore.clients.filter { $0.name.localizedCaseInsensitiveContains(searchText) }
    }

    var body: some View {
        VStack(spacing: 0) {
            // 搜尋列
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.secondary)
                TextField(L("search_clients"), text: $searchText)
                    .textFieldStyle(.plain)

                if !searchText.isEmpty {
                    Button {
                        searchText = ""
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.secondary)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(12)
            .background(Color(.textBackgroundColor))

            Divider()

            if filteredClients.isEmpty {
                VStack(spacing: 16) {
                    Image(systemName: "person.crop.circle.badge.plus")
                        .font(.system(size: 60))
                        .foregroundColor(.secondary)
                    Text(L("no_clients"))
                        .font(.title2)
                        .foregroundColor(.secondary)
                    Text(L("add_client_hint"))
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                // 客戶列表
                List {
                    ForEach(filteredClients) { client in
                        Button {
                            selectedClient = client
                            selectedTab = .charting
                        } label: {
                            ClientRowView(client: client)
                        }
                        .buttonStyle(PressableRowStyle())
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(
                            selectedClient?.id == client.id
                                ? Color.accentColor.opacity(0.12)
                                : (hoveredClientID == client.id ? Color.accentColor.opacity(0.06) : Color.clear)
                        )
                        .onHover { hovering in
                            withAnimation(.easeInOut(duration: 0.08)) {
                                hoveredClientID = hovering ? client.id : nil
                            }
                        }
                        .contextMenu {
                            Button {
                                selectedClient = client
                                selectedTab = .charting
                            } label: {
                                Label(L("chart"), systemImage: "chart.bar.doc.horizontal")
                            }

                            Button(role: .destructive) {
                                clientStore.deleteClient(client)
                            } label: {
                                Label(L("delete"), systemImage: "trash")
                            }
                        }
                    }
                    .onDelete { indexSet in
                        clientStore.deleteClients(at: indexSet)
                    }
                }
                .listStyle(.sidebar)
            }
        }
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    showingAddClient = true
                } label: {
                    Image(systemName: "plus")
                }
            }
        }
        .sheet(isPresented: $showingAddClient) {
            ClientFormView(client: nil) { newClient in
                clientStore.addClient(newClient)
                selectedClient = newClient
            }
        }
    }
}

struct PressableRowStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .opacity(configuration.isPressed ? 0.55 : 1.0)
            .animation(.easeInOut(duration: 0.05), value: configuration.isPressed)
    }
}

struct ClientRowView: View {
    let client: Client

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(client.name)
                    .font(.headline)
                Text(client.gender.displayName)
                    .font(.caption)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(client.gender == .male ? Color.blue.opacity(0.2) : Color.pink.opacity(0.2))
                    .cornerRadius(4)
            }

            HStack(spacing: 8) {
                Text(client.birthDate.formatted(date: .abbreviated, time: .omitted))
                    .font(.caption)
                    .foregroundColor(.secondary)

                Text(BirthTime(rawValue: client.birthTime.rawValue)?.displayName ?? "")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.vertical, 4)
        .frame(maxWidth: .infinity, alignment: .leading)
        .contentShape(Rectangle())
    }
}

#Preview {
    ClientListView(selectedClient: .constant(nil), selectedTab: .constant(.clients))
        .environmentObject(ClientStore())
        .frame(width: 300, height: 500)
}