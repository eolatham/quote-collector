//
//  AddQuoteCollectionView.swift
//  QuoteCollector
//
//  Created by Eric Latham on 12/10/21.
//

import SwiftUI
import CoreData

/**
 * For adding and editing quote collections.
 */
struct AddQuoteCollectionView: View {
    @Environment(\.managedObjectContext) private var context
    @Environment(\.presentationMode) var presentation

    @State private var name: String = ""
    @State private var isError: Bool = false
    @State private var nameErrorMsg: String? = nil

    var objectId: NSManagedObjectID?
    
    let viewModel = AddQuoteCollectionViewModel()

    var body: some View {
        NavigationView {
            VStack {
                Form {
                    Section(header: Text("NAME")) {
                        VStack {
                            TextField("Name", text: $name).lineLimit(1)
                        }
                    }
                    Section {
                        Button(
                            action: {
                                if name.isEmpty { nameErrorMsg = "Name is empty!" }
                                else { nameErrorMsg = nil }
                                
                                isError = nameErrorMsg != nil
                                
                                if isError == false {
                                    _ = viewModel.addQuoteCollection(
                                        context: context,
                                        objectId: objectId,
                                        values: QuoteCollectionValues(name: name)
                                    )
                                    presentation.wrappedValue.dismiss()
                                }
                            },
                            label: { Text("Save").font(.headline) }
                        )
                        .buttonStyle(PlainButtonStyle())
                        .foregroundColor(.accentColor)
                    }
                }
                .navigationTitle(objectId == nil ? "Add Quote Collection" : "Edit Quote Collection")
                .alert(isPresented: $isError) {
                    Alert(
                        title: Text("Error"),
                        message: Text(nameErrorMsg!),
                        dismissButton: .default(Text("OK"))
                    )
                }
            }
            .onAppear {
                if let quoteCollectionId = objectId,
                   let quoteCollection = viewModel.fetchQuoteCollection(context: context, objectId: quoteCollectionId)
                {
                    name = quoteCollection.name!
                }
            }
        }
    }
}
