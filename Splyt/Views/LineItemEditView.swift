import SwiftUI
import SwiftData

struct LineItemEditView: View {
    @Bindable var item: LineItem
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Query(sort: \Person.name) private var people: [Person]

    @State private var priceText: String
    @State private var showingAddPerson = false
    @State private var newPersonName = ""

    init(item: LineItem) {
        self.item = item
        _priceText = State(initialValue: String(format: "%.2f", item.price))
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Item") {
                    TextField("Name", text: $item.name)
                    HStack {
                        Text("$").foregroundStyle(.secondary)
                        TextField("0.00", text: $priceText)
                            .keyboardType(.decimalPad)
                    }
                }

                Section("Assign to") {
                    Button {
                        item.assignedPerson = nil
                    } label: {
                        HStack {
                            Label("No one", systemImage: "xmark.circle")
                                .foregroundStyle(item.assignedPerson == nil ? .primary : .secondary)
                            Spacer()
                            if item.assignedPerson == nil {
                                Image(systemName: "checkmark").foregroundStyle(.blue).fontWeight(.semibold)
                            }
                        }
                    }

                    ForEach(people) { person in
                        Button {
                            item.assignedPerson = person
                        } label: {
                            HStack(spacing: 12) {
                                Circle()
                                    .fill(person.color)
                                    .frame(width: 24, height: 24)
                                Text(person.name)
                                    .foregroundStyle(.primary)
                                Spacer()
                                if item.assignedPerson?.persistentModelID == person.persistentModelID {
                                    Image(systemName: "checkmark").foregroundStyle(.blue).fontWeight(.semibold)
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
            }
            .navigationTitle("Edit Item")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        if let price = Double(priceText), price >= 0 {
                            item.price = price
                        }
                        dismiss()
                    }
                    .fontWeight(.semibold)
                }
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { dismiss() }
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
        item.assignedPerson = person
        newPersonName = ""
    }
}
