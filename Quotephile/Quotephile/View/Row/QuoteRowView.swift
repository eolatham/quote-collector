import SwiftUI

struct QuoteRowView: View {
    @ObservedObject var quote: Quote
    
    var body: some View {
        if quote.exists {
            VStack(alignment: .leading) {
                Text(quote.rawText)
                    .font(.body)
                    .lineLimit(1)
                    .truncationMode(.tail)
                if quote.author.count > 0 {
                    Text(quote.author)
                        .font(.caption)
                        .lineLimit(1)
                        .truncationMode(.tail)
                }
            }
        }
        else { EmptyView() }
    }
}