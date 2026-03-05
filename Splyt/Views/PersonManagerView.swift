import SwiftUI
import SwiftData

struct PersonManagerView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Query(sort: \Person.name) private var people: [Person]
    @State private var newName = ""

    var body: some View {
        NavigationStack {
            List {
                Section {
                    HStack {
                        TextField("Person's name", text: $newName)
                            .submitLabel(.done)
                            .onSubmit { addPerson() }
                        Button("Add", action: addPerson)
                            .disabled(newName.trimmingCharacters(in: .whitespaces).isEmpty)
                    }
                }

                if !people.isEmpty {
                    Section("People") {
                        ForEach(people) { person in
                            Button {
                                setCurrentUser(person)
                            } label: {
                                HStack(spacing: 12) {
                                    Circle()
                                        .fill(person.color)
                                        .frame(width: 28, height: 28)
                                    Text(person.name)
                                        .foregroundStyle(.primary)
                                    Spacer()
                                    if person.isCurrentUser {
                                        Text("ME")
                                            .font(.system(size: 11, weight: .bold))
                                            .foregroundStyle(Color.splytGreen)
                                            .padding(.horizontal, 8)
                                            .padding(.vertical, 3)
                                            .background(Color.splytGreen.opacity(0.12))
                                            .clipShape(Capsule())
                                    }
                                }
                            }
                        }
                        .onDelete { indexSet in
                            indexSet.forEach { modelContext.delete(people[$0]) }
                        }
                    }
                }
            }
            .navigationTitle("People")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                }
                if !people.isEmpty {
                    ToolbarItem(placement: .topBarLeading) {
                        EditButton()
                    }
                }
            }
        }
    }

    private func addPerson() {
        let name = newName.trimmingCharacters(in: .whitespaces)
        guard !name.isEmpty else { return }
        let colorHex = Color.personPresets[people.count % Color.personPresets.count]
        modelContext.insert(Person(name: name, colorHex: colorHex))
        newName = ""
    }

    private func setCurrentUser(_ person: Person) {
        let wasMe = person.isCurrentUser
        people.forEach { $0.isCurrentUser = false }
        person.isCurrentUser = !wasMe
    }
}
