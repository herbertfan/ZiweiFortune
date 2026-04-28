import Foundation
import Combine
import UniformTypeIdentifiers

final class ClientStore: ObservableObject {
    @Published var clients: [Client] = []

    private let dataStore = DataStore.shared

    init() {
        loadClients()
    }

    func loadClients() {
        clients = dataStore.loadClients()
    }

    func saveClients() {
        dataStore.saveClients(clients)
    }

    func addClient(_ client: Client) {
        clients.append(client)
        saveClients()
    }

    func updateClient(_ client: Client) {
        if let index = clients.firstIndex(where: { $0.id == client.id }) {
            clients[index] = client
            saveClients()
        }
    }

    func deleteClient(_ client: Client) {
        clients.removeAll { $0.id == client.id }
        saveClients()
    }

    func deleteClients(at offsets: IndexSet) {
        clients.remove(atOffsets: offsets)
        saveClients()
    }

    // MARK: - Export

    func exportToJSON() -> Data? {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        encoder.dateEncodingStrategy = .iso8601
        return try? encoder.encode(clients)
    }

    func exportToCSV() -> Data? {
        let dateFormatter = ISO8601DateFormatter()
        var csv = "name,gender,birthDate,birthTime,birthPlace,phone,email,notes\n"
        for c in clients {
            let escaped = { (s: String) in s.contains(",") || s.contains("\"") ? "\"\(s.replacingOccurrences(of: "\"", with: "\"\""))\"" : s }
            let row = [
                escaped(c.name),
                c.gender.rawValue,
                dateFormatter.string(from: c.birthDate),
                String(c.birthTime.rawValue),
                escaped(c.birthPlace),
                escaped(c.phone),
                escaped(c.email),
                escaped(c.notes)
            ].joined(separator: ",")
            csv.append(row + "\n")
        }
        return csv.data(using: .utf8)
    }

    // MARK: - Import with Dedup

    enum ImportResult {
        case result(added: Int, skipped: Int, renamed: Int)
    }

    func importFromJSON(_ data: Data) -> ImportResult {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        guard let imported = try? decoder.decode([Client].self, from: data) else {
            return .result(added: 0, skipped: 0, renamed: 0)
        }
        return mergeClients(imported)
    }

    func importFromCSV(_ data: Data) -> ImportResult {
        guard let csv = String(data: data, encoding: .utf8) else { return .result(added: 0, skipped: 0, renamed: 0) }
        let lines = csv.components(separatedBy: "\n").filter { !$0.isEmpty }
        guard lines.count > 1 else { return .result(added: 0, skipped: 0, renamed: 0) } // header only

        let dateFormatter = ISO8601DateFormatter()
        var imported: [Client] = []

        for line in lines.dropFirst() {
            var fields: [String] = []
            var current = ""
            var inQuotes = false
            for ch in line {
                if ch == "\"" {
                    inQuotes.toggle()
                } else if ch == "," && !inQuotes {
                    fields.append(current)
                    current = ""
                } else {
                    current.append(ch)
                }
            }
            fields.append(current)
            guard fields.count >= 8 else { continue }

            let name = fields[0]
            let gender = fields[1] == "女" ? Gender.female : Gender.male
            let birthDate = dateFormatter.date(from: fields[2]) ?? Date()
            let birthTime = BirthTime(rawValue: Int(fields[3]) ?? 0) ?? .zi
            let birthPlace = fields[4]
            let phone = fields[5]
            let email = fields[6]
            let notes = fields[7]

            imported.append(Client(
                name: name, gender: gender, birthDate: birthDate, birthTime: birthTime,
                birthPlace: birthPlace, phone: phone, email: email, notes: notes
            ))
        }
        return mergeClients(imported)
    }

    private func mergeClients(_ imported: [Client]) -> ImportResult {
        var added = 0, skipped = 0, renamed = 0
        for var c in imported {
            // Check by ID
            if clients.contains(where: { $0.id == c.id }) {
                skipped += 1
                continue
            }
            // Check by name + birthDate: same content
            if clients.contains(where: { $0.name == c.name && $0.birthDate == c.birthDate }) {
                skipped += 1
                continue
            }
            // Same name but different content → append (2)
            if clients.contains(where: { $0.name == c.name }) {
                var suffix = 2
                while clients.contains(where: { $0.name == "\(c.name)(\(suffix))" }) {
                    suffix += 1
                }
                c.name = "\(c.name)(\(suffix))"
                renamed += 1
            }
            clients.append(c)
            added += 1
        }
        if added > 0 || renamed > 0 { saveClients() }
        return .result(added: added, skipped: skipped, renamed: renamed)
    }
}