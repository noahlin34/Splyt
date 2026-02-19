import SwiftUI
import SwiftData

struct PersonPickerView: View {
    @Bindable var lineItem: LineItem
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Query(sort: \Person.name) private var people: [Person]

    @State private var newPersonName = ""
    @State private var showingAddPerson = false

    var body: some View {
        NavigationStack {
            List {
                Button {
                    lineItem.assignedPerson = nil
                    dismiss()
                } label: {
                    Label("Unassign", systemImage: "xmark.circle")
                        .foregroundStyle(.red)
                }

                ForEach(people) { person in
                    Button {
                        lineItem.assignedPerson = person
                        dismiss()
                    } label: {
                        HStack(spacing: 12) {
                            Circle()
                                .fill(person.color)
                                .frame(width: 24, height: 24)
                            Text(person.name)
                                .foregroundStyle(.primary)
                            Spacer()
                            if lineItem.assignedPerson?.persistentModelID == person.persistentModelID {
                                Image(systemName: "checkmark")
                                    .foregroundStyle(.blue)
                                    .fontWeight(.semibold)
                            }
                        }
                    }
                }

                Button {
                    showingAddPerson = true
                } label: {
                    Label("Add New Person", systemImage: "person.badge.plus")
                }
            }
            .navigationTitle("Assign to")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
            .alert("New Person", isPresented: $showingAddPerson) {
                TextField("Name", text: $newPersonName)
                Button("Add") { addPerson() }
                Button("Cancel", role: .cancel) { newPersonName = "" }
            }
        }
    }

    private func addPerson() {
        let name = newPersonName.trimmingCharacters(in: .whitespaces)
        guard !name.isEmpty else { return }
        let colorHex = Color.personPresets[people.count % Color.personPresets.count]
        let person = Person(name: name, colorHex: colorHex)
        modelContext.insert(person)
        lineItem.assignedPerson = person
        newPersonName = ""
        dismiss()
    }
}
