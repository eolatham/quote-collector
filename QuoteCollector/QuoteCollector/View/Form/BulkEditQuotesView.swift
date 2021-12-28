import SwiftUI

struct BulkEditQuotesView: View {
    @Environment(\.managedObjectContext) private var context
    @Environment(\.presentationMode) private var presentation

    var quotes: Set<Quote>

    @State private var replaceAuthorFirstName: Bool = false
    @State private var authorFirstName: String = ""
    @State private var replaceAuthorLastName: Bool = false
    @State private var authorLastName: String = ""
    @State private var editTags: Bool = false
    @State private var tagsEditMode: EditMode = EditMode.replace
    @State private var tags: String = ""
    @State private var isError: Bool = false
    @State private var errorMessage: String? = nil

    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("AUTHOR")) {
                    VStack {
                        Toggle(isOn: $replaceAuthorFirstName) { Text("Replace author first name") }
                            .tint(.accentColor)
                        if replaceAuthorFirstName {
                            TextField("First Name (optional)", text: $authorFirstName)
                                .lineLimit(1)
                        }
                        Toggle(isOn: $replaceAuthorLastName) { Text("Replace author last name") }
                            .tint(.accentColor)
                        if replaceAuthorLastName {
                            TextField("Last Name (optional)", text: $authorLastName)
                                .lineLimit(1)
                        }
                    }
                }
                Section(header: Text("TAGS")) {
                    VStack {
                        Toggle(isOn: $editTags) { Text("Edit tags") }
                            .tint(.accentColor)
                        if editTags {
                            Picker("Mode", selection: $tagsEditMode) {
                                Text("Replace").tag(EditMode.replace)
                                Text("Add").tag(EditMode.add)
                                Text("Remove").tag(EditMode.remove)
                            }.pickerStyle(InlinePickerStyle())
                            TextField("Tags (comma-separated)", text: $tags)
                                .lineLimit(1)
                        }
                    }
                }
                Section {
                    Button(
                        action: {
                            DatabaseFunctions.editQuotes(
                                    context: context,
                                    quotes: quotes,
                                    newAuthorFirstName: replaceAuthorFirstName ? authorFirstName : nil,
                                    newAuthorLastName: replaceAuthorLastName ? authorLastName : nil,
                                    tags: editTags ? tags : nil,
                                    tagsMode: tagsEditMode
                                )
                            presentation.wrappedValue.dismiss()
                        },
                        label: { Text("Save").font(.headline) }
                    )
                    .foregroundColor(.accentColor)
                }
            }
            .navigationTitle("Edit Quotes")
            .toolbar(
                content: {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Cancel") { presentation.wrappedValue.dismiss() }
                    }
                }
            )
            .alert(isPresented: $isError) {
                Alert(
                    title: Text("Error"),
                    message: Text(errorMessage!),
                    dismissButton: .default(
                        Text("Dismiss"),
                        action: {
                            isError = false
                            errorMessage = nil
                        }
                    )
                )
            }
        }
    }
}
