import SwiftUI

/**
 * For adding and editing quotes.
 */
struct AddQuoteView: View {
    @Environment(\.managedObjectContext) private var context
    @Environment(\.presentationMode) private var presentation

    var quoteCollection: QuoteCollection
    var quote: Quote?

    @State private var text: String
    @State private var authorFirstName: String
    @State private var authorLastName: String
    @State private var tags: String
    @State private var isError: Bool
    @State private var errorMessage: String?

    init(quoteCollection: QuoteCollection, quote: Quote? = nil) {
        self.quoteCollection = quoteCollection
        self.quote = quote
        if quote != nil {
            _text = State<String>(initialValue: quote!.text!)
            _authorFirstName = State<String>(initialValue: quote!.authorFirstName!)
            _authorLastName = State<String>(initialValue: quote!.authorLastName!)
            _tags = State<String>(initialValue: quote!.tags!)
        } else {
            _text = State<String>(initialValue: "")
            _authorFirstName = State<String>(initialValue: "")
            _authorLastName = State<String>(initialValue: "")
            _tags = State<String>(initialValue: "")
        }
        _isError = State<Bool>(initialValue: false)
        _errorMessage = State<String?>(initialValue: nil)
    }

    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("TEXT")) {
                    TextEditor(text: $text)
                }
                Section(header: Text("AUTHOR (optional)")) {
                    TextField("First Name", text: $authorFirstName)
                        .lineLimit(1)
                    TextField("Last Name", text: $authorLastName)
                        .lineLimit(1)
                }
                Section(header: Text("TAGS (optional)")) {
                    TextField("Tags (comma-separated)", text: $tags)
                        .lineLimit(1)
                }
                Section {
                    Button(
                        action: {
                            let values: QuoteValues = QuoteValues(
                                collection: quoteCollection,
                                text: text,
                                authorFirstName: authorFirstName,
                                authorLastName: authorLastName,
                                tags: tags
                            )
                            if quote != nil {
                                values.displayQuotationMarks = quote!.displayQuotationMarks
                                values.displayAuthor = quote!.displayAuthor
                                values.displayAuthorOnNewLine = quote!.displayAuthorOnNewLine
                            }
                            do {
                                try _ = DatabaseFunctions.addQuote(
                                    context: context,
                                    quote: quote,
                                    values: values
                                )
                                presentation.wrappedValue.dismiss()
                            } catch ValidationError.withMessage(let message) {
                                isError = true
                                errorMessage = message
                            } catch {
                                isError = true
                                errorMessage = ErrorMessage.default
                            }
                        },
                        label: { Text("Save").font(.headline) }
                    )
                    .foregroundColor(.accentColor)
                }
            }
            .navigationTitle(quote == nil ? "Add Quote" : "Edit Quote")
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
