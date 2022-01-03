import CoreData

@objc(Quote)
class Quote: NSManagedObject {
    @objc var exists: Bool { text != nil }
    @objc var length: Int { text!.count }
    @objc var rawText: String { text! }
    @objc var exportText: String { "\(rawText) ——\(author)" }
    @objc var displayText: String {
        var s: String = rawText
        if displayQuotationMarks { s = "“" + s + "”" }
        if displayAuthor {
            s = s + (displayAuthorOnNewLine ? "\n" : " ") + "—" + author
        }
        return s
    }
    @objc var author: String {
        let name = [authorFirstName!, authorLastName!]
            .joined(separator: " ")
            .trimmingCharacters(in: .whitespaces)
        if name.isEmpty { return "Anonymous" }
        return name
    }
    @objc var authorFirstNameAscending: String {
        if !authorFirstName!.isEmpty { return authorFirstName!.uppercased() }
        else if !authorLastName!.isEmpty { return "NONE" }
        else { return "ANONYMOUS" }
    }
    @objc var authorFirstNameDescending: String {
        // Add space to avoid crash upon switching sort mode
        authorFirstNameAscending + " "
    }
    @objc var authorLastNameAscending: String {
        if !authorLastName!.isEmpty { return authorLastName!.uppercased() }
        else if !authorFirstName!.isEmpty { return "NONE"  }
        else { return "ANONYMOUS" }
    }
    @objc var authorLastNameDescending: String {
        // Add space to avoid crash upon switching sort mode
        authorLastNameAscending + " "
    }
    @objc var tagsAscending: String {
        tags!.isEmpty ? "NONE" : tags!.uppercased()
    }
    @objc var tagsDescending: String {
        // Add space to avoid crash upon switching sort mode
        (tags!.isEmpty ? "NONE" : tags!.uppercased()) + " "
    }
    @objc var monthCreatedAscending: String {
        Utility.dateToMonthString(date:dateCreated!)
    }
    @objc var monthCreatedDescending: String {
        // Add space to avoid crash upon switching sort mode
        Utility.dateToMonthString(date:dateCreated!) + " "
    }
    @objc var monthChangedAscending: String {
        Utility.dateToMonthString(date:dateChanged!)
    }
    @objc var monthChangedDescending: String {
        // Add space to avoid crash upon switching sort mode
        Utility.dateToMonthString(date:dateChanged!) + " "
    }
}
