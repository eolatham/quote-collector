//
//  Persistence.swift
//  QuoteCollector
//
//  Created by Eric Latham on 12/7/21.
//

import CoreData

struct PersistenceController {
    static let shared = PersistenceController()

    static var preview: PersistenceController = {
        let result = PersistenceController(inMemory: true)
        let viewContext = result.container.viewContext
        for i in 1..<6 {
            var quoteCollection = QuoteCollection.create(context: viewContext, name: "Quote Collection #\(i)")
            for j in 1..<11 {
                var quote = Quote.create(
                    context: viewContext,
                    collection: quoteCollection,
                    text: "Quote Collection #\(i) - Quote #\(j)"
                )
            }
        }
        do {
            try viewContext.save()
        } catch {
            let nsError = error as NSError
            fatalError("Unresolved error \(nsError), \(nsError.userInfo)")
        }
        return result
    }()

    let container: NSPersistentContainer

    init(inMemory: Bool = false) {
        container = NSPersistentContainer(name: "QuoteCollector")
        if inMemory {
            container.persistentStoreDescriptions.first!.url = URL(fileURLWithPath: "/dev/null")
        }
        container.loadPersistentStores(completionHandler: { (storeDescription, error) in
            if let error = error as NSError? {
                fatalError("Unresolved error \(error), \(error.userInfo)")
            }
        })
    }
}
