import Foundation

final class DataStore {
    static let shared = DataStore()

    private let fileManager = FileManager.default
    private var documentsDirectory: URL {
        fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0]
    }

    private var clientsFile: URL {
        documentsDirectory.appendingPathComponent("clients.json")
    }

    private init() {}

    // MARK: - Client Operations

    func loadClients() -> [Client] {
        guard fileManager.fileExists(atPath: clientsFile.path) else {
            return []
        }

        do {
            let data = try Data(contentsOf: clientsFile)
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            return try decoder.decode([ClientData].self, from: data).map { $0.toClient() }
        } catch {
            print("Failed to load clients: \(error)")
            return []
        }
    }

    func saveClients(_ clients: [Client]) {
        do {
            let encoder = JSONEncoder()
            encoder.dateEncodingStrategy = .iso8601
            encoder.outputFormatting = .prettyPrinted
            let clientDataList = clients.map { ClientData(from: $0) }
            let data = try encoder.encode(clientDataList)
            try data.write(to: clientsFile, options: .atomic)
        } catch {
            print("Failed to save clients: \(error)")
        }
    }
}

// Codable wrapper for Client
struct ClientData: Codable {
    var id: UUID
    var name: String
    var gender: String
    var birthDate: Date
    var birthTime: Int
    var birthPlace: String
    var phone: String
    var email: String
    var notes: String
    var createdAt: Date
    var updatedAt: Date

    init(from client: Client) {
        self.id = client.id
        self.name = client.name
        self.gender = client.gender.rawValue
        self.birthDate = client.birthDate
        self.birthTime = client.birthTime.rawValue
        self.birthPlace = client.birthPlace
        self.phone = client.phone
        self.email = client.email
        self.notes = client.notes
        self.createdAt = client.createdAt
        self.updatedAt = client.updatedAt
    }

    func toClient() -> Client {
        Client(
            id: id,
            name: name,
            gender: Gender(rawValue: gender) ?? .male,
            birthDate: birthDate,
            birthTime: BirthTime(rawValue: birthTime) ?? .zi,
            birthPlace: birthPlace,
            phone: phone,
            email: email,
            notes: notes,
            createdAt: createdAt,
            updatedAt: updatedAt
        )
    }
}