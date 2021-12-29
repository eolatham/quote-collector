import SwiftUI

/**
 * This wrapping is necessary because initializing state (selectedSort in this case)
 * with an inline function call produces unreliable results; function calls in such
 * contexts seem to be memoized to avoid recomputing them when the view is recreated.
 */
struct QuoteCollectionView: View {
    @StateObject var quoteCollection: QuoteCollection

    var body: some View {
        if quoteCollection.exists {
            _QuoteCollectionView(
                quoteCollection: quoteCollection,
                selectedSort: QuoteSort.getUserDefault(quoteCollection: quoteCollection)
            )
        } else { EmptyView() }
    }
}

struct _QuoteCollectionView: View {
    @Environment(\.managedObjectContext) private var context

    @StateObject var quoteCollection: QuoteCollection
    @State var selectedSort: Sort<Quote>

    @State private var searchTerm: String = ""

    private var searchQuery: Binding<String> {
        Binding { searchTerm } set: { newValue in
            searchTerm = newValue
        }
    }

    private var predicate: NSPredicate? {
        let collectionPredicate = NSPredicate(format: "collection = %@", quoteCollection)
        if searchTerm.isEmpty {
            return collectionPredicate
        } else {
            return NSCompoundPredicate(
                andPredicateWithSubpredicates: [
                    collectionPredicate,
                    NSCompoundPredicate(
                        orPredicateWithSubpredicates: [
                            NSPredicate(format: "text CONTAINS[cd] %@", searchTerm),
                            NSPredicate(format: "authorFirstName CONTAINS[cd] %@", searchTerm),
                            NSPredicate(format: "authorLastName CONTAINS[cd] %@", searchTerm),
                            NSPredicate(format: "tags CONTAINS[cd] %@", searchTerm)
                        ]
                    )
                ]
            )
        }
    }

    var body: some View {
        if quoteCollection.exists {
            CustomListView<
                Quote,
                QuoteRowView,
                QuoteView,
                EmptyView,
                EmptyView,
                AddQuoteView,
                EditQuoteCollectionView,
                BulkEditQuotesView,
                BulkMoveQuotesView
            >(
                title: quoteCollection.name!,
                entities: SectionedFetchRequest<String, Quote>(
                    sectionIdentifier: selectedSort.section,
                    sortDescriptors: selectedSort.descriptors,
                    predicate: predicate,
                    animation: .default
                ),
                searchQuery: searchQuery,
                selectedSort: $selectedSort,
                sortOptions: QuoteSort.sorts,
                entityRowViewBuilder: { quote in
                    QuoteRowView(quote: quote)
                },
                entityPageViewBuilder: { quote in
                    QuoteView(quote: quote)
                },
                addEntitySheetContentViewBuilder: {
                    AddQuoteView(quoteCollection: quoteCollection)
                },
//                This is currently commented out because changing the name of a quote collection
//                can change the sections of the fetch request data in the root quote collections
//                list view, which kills the changed quote collection view because quote
//                collection views are rendered dynamically based on the fetch request
//                data. For some reason, this problem does not occur with quotes...
//                editParentSheetContentViewBuilder: {
//                    EditQuoteCollectionView(quoteCollection: quoteCollection)
//                },
                bulkEditSheetContentViewBuilder: { selection, exitSelectionMode in
                    BulkEditQuotesView(quotes: selection)
                },
                bulkMoveSheetContentViewBuilder: { selection, exitSelectionMode in
                    BulkMoveQuotesView(quotes: selection, afterMove: exitSelectionMode)
                },
                bulkDeleteFunction: { selection in
                    DatabaseFunctions.deleteQuotes(
                        context: context,
                        quotes: selection
                    )
                },
                bulkDeleteAlertMessage: { selection in
                    return (
                        "Are you sure you want to delete the \(selection.count) " +
                        "selected quotes? This action cannot be undone!"
                    )
                }
            )
            .onChange(
                of: selectedSort,
                perform: { _ in
                    QuoteSort.setUserDefault(
                        sort: selectedSort,
                        quoteCollection: quoteCollection
                    )
                }
            )
        } else { EmptyView() }
    }
}
