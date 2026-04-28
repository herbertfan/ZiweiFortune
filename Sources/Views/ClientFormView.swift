import SwiftUI

struct ClientFormView: View {
    @Environment(\.dismiss) private var dismiss
    let client: Client?
    let onSave: (Client) -> Void

    @State private var name: String = ""
    @State private var gender: Gender = .male
    @State private var birthDate: Date = Date()
    @State private var birthTime: BirthTime = .zi
    @State private var birthPlace: String = ""
    @State private var phone: String = ""
    @State private var email: String = ""
    @State private var notes: String = ""

    var isEditing: Bool { client != nil }

    var body: some View {
        VStack(spacing: 0) {
            // 標題列
            HStack {
                Text(isEditing ? L("edit_client") : L("new_client"))
                    .font(.title2)
                    .fontWeight(.semibold)
                Spacer()
                Button(L("cancel")) {
                    dismiss()
                }
                .keyboardShortcut(.escape)
            }
            .padding()

            Divider()

            Form {
                Section {
                    TextField(L("name"), text: $name)
                    Picker(L("gender"), selection: $gender) {
                        ForEach(Gender.allCases, id: \.self) { g in
                            Text(g.displayName).tag(g)
                        }
                    }
                }

                Section(L("birth_info")) {
                    DatePicker(L("birth_date"), selection: $birthDate, displayedComponents: .date)
                    Picker(L("birth_time"), selection: $birthTime) {
                        ForEach(BirthTime.allCases, id: \.self) { t in
                            Text(t.displayName).tag(t)
                        }
                    }
                    TextField(L("birth_place"), text: $birthPlace)
                }

                Section(L("contact_info")) {
                    TextField(L("phone"), text: $phone)
                        .textContentType(.telephoneNumber)
                    TextField(L("email"), text: $email)
                        .textContentType(.emailAddress)
                }

                Section(L("notes")) {
                    TextEditor(text: $notes)
                        .frame(minHeight: 100)
                }
            }
            .formStyle(.grouped)

            Divider()

            HStack {
                Spacer()
                Button(isEditing ? L("save") : L("add")) {
                    saveClient()
                }
                .keyboardShortcut(.return)
                .disabled(name.isEmpty)
            }
            .padding()
        }
        .frame(width: 500, height: 600)
        .onAppear {
            if let client = client {
                name = client.name
                gender = client.gender
                birthDate = client.birthDate
                birthTime = client.birthTime
                birthPlace = client.birthPlace
                phone = client.phone
                email = client.email
                notes = client.notes
            }
        }
    }

    private func saveClient() {
        let updatedClient = Client(
            id: client?.id ?? UUID(),
            name: name,
            gender: gender,
            birthDate: birthDate,
            birthTime: birthTime,
            birthPlace: birthPlace,
            phone: phone,
            email: email,
            notes: notes,
            createdAt: client?.createdAt ?? Date(),
            updatedAt: Date()
        )
        onSave(updatedClient)
        dismiss()
    }
}

#Preview {
    ClientFormView(client: nil) { _ in }
}