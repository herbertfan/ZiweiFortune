import SwiftUI

struct ChartingView: View {
    @EnvironmentObject var clientStore: ClientStore
    @EnvironmentObject var chartStore: ChartStore
    @Binding var selectedClient: Client?
    @State private var showingClientSelector = false
    @State private var showingClientForm = false

    var body: some View {
        HSplitView {
            // 左側客戶選擇面板
            VStack(spacing: 0) {
                if let client = selectedClient {
                    ClientInfoPanel(client: client) {
                        showingClientSelector = true
                    }
                } else {
                    VStack(spacing: 16) {
                        Image(systemName: "person.crop.circle.badge.plus")
                            .font(.system(size: 50))
                            .foregroundColor(.secondary)
                        Text(L("select_client"))
                            .foregroundColor(.secondary)
                        Button(L("select_client")) {
                            showingClientSelector = true
                        }
                        .buttonStyle(.borderedProminent)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(Color(.textBackgroundColor))
                }
            }
            .frame(minWidth: 280, maxWidth: 320)

            // 右側命盤顯示區
            VStack(spacing: 0) {
                if let chart = chartStore.currentChart, let client = selectedClient {
                    ChartDisplayView(chart: chart, client: client)
                } else {
                    VStack(spacing: 16) {
                        Image(systemName: "chart.bar.doc.horizontal")
                            .font(.system(size: 60))
                            .foregroundColor(.secondary)
                        Text(L("select_client_to_chart"))
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
            }
            .frame(minWidth: 700)
        }
        .sheet(isPresented: $showingClientSelector) {
            ClientSelectorSheet(selectedClient: $selectedClient, showingForm: $showingClientForm)
        }
        .sheet(isPresented: $showingClientForm) {
            ClientFormView(client: nil) { newClient in
                clientStore.addClient(newClient)
                selectedClient = newClient
            }
        }
        .onChange(of: selectedClient) { _, newClient in
            if let client = newClient {
                _ = chartStore.calculateChart(for: client)
            }
        }
    }
}

struct ClientInfoPanel: View {
    let client: Client
    let onChangeClient: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text(L("clients"))
                    .font(.headline)
                Spacer()
                Button {
                    onChangeClient()
                } label: {
                    Image(systemName: "arrow.triangle.2.circlepath")
                }
                .buttonStyle(.plain)
            }

            VStack(alignment: .leading, spacing: 8) {
                InfoRow(label: L("name"), value: client.name)
                InfoRow(label: L("gender"), value: client.gender.displayName)
                InfoRow(label: L("birth_date"), value: client.birthDate.formatted(date: .long, time: .omitted))
                InfoRow(label: L("birth_time"), value: client.birthTime.displayName)
                if !client.birthPlace.isEmpty {
                    InfoRow(label: L("birth_place"), value: client.birthPlace)
                }
            }

            Spacer()
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(.textBackgroundColor))
    }
}

struct InfoRow: View {
    let label: String
    let value: String

    var body: some View {
        HStack {
            Text(label)
                .foregroundColor(.secondary)
                .frame(width: 50, alignment: .leading)
            Text(value)
        }
        .font(.subheadline)
    }
}

struct ClientSelectorSheet: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var clientStore: ClientStore
    @Binding var selectedClient: Client?
    @Binding var showingForm: Bool

    @State private var searchText = ""
    @State private var hoveredID: UUID? = nil

    var filteredClients: [Client] {
        if searchText.isEmpty {
            return clientStore.clients
        }
        return clientStore.clients.filter { $0.name.localizedCaseInsensitiveContains(searchText) }
    }

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text(L("select_client"))
                    .font(.title2)
                    .fontWeight(.semibold)
                Spacer()
                Button(L("close")) {
                    dismiss()
                }
                .keyboardShortcut(.escape)
            }
            .padding()

            Divider()

            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.secondary)
                TextField(L("search"), text: $searchText)
                    .textFieldStyle(.plain)
            }
            .padding(12)
            .background(Color(.textBackgroundColor))

            Divider()

            if filteredClients.isEmpty {
                VStack(spacing: 16) {
                    Text(L("no_clients"))
                        .foregroundColor(.secondary)
                    Button(L("new_client")) {
                        dismiss()
                        showingForm = true
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                List {
                    ForEach(filteredClients) { client in
                        Button {
                            selectedClient = client
                            dismiss()
                        } label: {
                            HStack {
                                VStack(alignment: .leading) {
                                    Text(client.name)
                                        .font(.headline)
                                    Text("\(client.gender.displayName) • \(client.birthDate.formatted(date: .abbreviated, time: .omitted))")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                                Spacer()
                                if selectedClient?.id == client.id {
                                    Image(systemName: "checkmark")
                                        .foregroundColor(.accentColor)
                                }
                            }
                        }
                        .buttonStyle(PressableRowStyle())
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(
                            selectedClient?.id == client.id
                                ? Color.accentColor.opacity(0.12)
                                : (hoveredID == client.id ? Color.accentColor.opacity(0.06) : Color.clear)
                        )
                        .onHover { hovering in
                            withAnimation(.easeInOut(duration: 0.08)) {
                                hoveredID = hovering ? client.id : nil
                            }
                        }
                    }
                }
                .listStyle(.plain)
            }
        }
        .frame(width: 400, height: 500)
    }
}

#Preview {
    ChartingView(selectedClient: .constant(nil))
        .environmentObject(ClientStore())
        .environmentObject(ChartStore())
}