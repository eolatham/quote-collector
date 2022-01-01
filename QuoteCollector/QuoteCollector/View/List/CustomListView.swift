import SwiftUI
import CoreData

/**
 * A generic list view supporting grouping, sorting, selecting, editing, moving, and deleting
 * entities from a sectioned fetch request in a navigation view context.
 */
struct CustomListView<
    Entity: NSManagedObject,
    EntityRowView: View,
    EntityPageView: View,
    ConstantListPrefixView: View,
    ConstantListSuffixView: View,
    AddEntitySheetView: View,
    SingleEditSheetView: View,
    SingleMoveSheetView: View,
    BulkEditSheetView: View,
    BulkMoveSheetView: View
>: View {
    var title: String
    @SectionedFetchRequest var entities: SectionedFetchResults<String, Entity>
    @Binding var searchQuery: String
    @Binding var selectedSort: Sort<Entity>
    var sortOptions: [Sort<Entity>]
    var entityRowViewBuilder: (Entity) -> EntityRowView
    var entityPageViewBuilder: (Entity) -> EntityPageView
    var constantListPrefixViewBuilder: (() -> ConstantListPrefixView)? = nil
    var constantListSuffixViewBuilder: (() -> ConstantListSuffixView)? = nil
    var addEntitiesSheetViewBuilder: (() -> AddEntitySheetView)? = nil
    var singleEditSheetViewBuilder: ((_ toEdit: Entity) -> SingleEditSheetView)? = nil
    var singleMoveSheetViewBuilder: ((_ toMove: Entity) -> SingleMoveSheetView)? = nil
    var singleDeleteFunction: ((_ toDelete: Entity) -> Void)? = nil
    var singleDeleteAlertMessage: (_ toDelete: Entity) -> String
        = { _ in return "This action cannot be undone!" }
    var bulkEditSheetViewBuilder: (
        // Use exitSelectionMode to exit selection mode after edit is done
        (_ toEdit: Set<Entity>, _ exitSelectionMode: @escaping () -> Void)
        -> BulkEditSheetView
    )? = nil
    var bulkMoveSheetViewBuilder: (
        // Use exitSelectionMode to exit selection mode after move is done
        (_ toMove: Set<Entity>, _ exitSelectionMode: @escaping () -> Void)
        -> BulkMoveSheetView
    )? = nil
    var bulkDeleteFunction: ((_ toDelete: Set<Entity>) -> Void)? = nil
    var bulkDeleteAlertMessage: (_ toDelete: Set<Entity>) -> String
        = { _ in return "This action cannot be undone!" }
    var bulkExportFunction: ((_ toExport: Set<Entity>) -> PlainTextDocument)? = nil
    var bulkExportDefaultDocumentName: String = "Export"

    @State private var selectedEntities: Set<Entity> = []
    @State private var inSelectionMode: Bool = false
    @State private var showAddEntitiesView: Bool = false
    @State private var showBulkEditView: Bool = false
    @State private var showBulkMoveView: Bool = false
    @State private var showBulkDeleteAlert: Bool = false
    @State private var showBulkExporter: Bool = false
    @State private var bulkExportDocument: PlainTextDocument? = nil

    private func enterSelectionMode() {
        inSelectionMode = true
    }

    private func exitSelectionMode() {
        inSelectionMode = false
        selectedEntities = []
    }

    private func invertSelection() {
        entities.forEach({ section in
            section.forEach({ entity in
                if selectedEntities.contains(entity) {
                    selectedEntities.remove(entity)
                } else {
                    selectedEntities.update(with: entity)
                }
            })
        })
    }

    var body: some View {
        List {
            if !inSelectionMode && constantListPrefixViewBuilder != nil {
                constantListPrefixViewBuilder!()
            }
            ForEach(entities, id: \.id) { section in
                withAnimation {
                    CustomListSectionView(
                        section: section,
                        selectedEntities: $selectedEntities,
                        inSelectionMode: inSelectionMode,
                        entityRowViewBuilder: entityRowViewBuilder,
                        entityPageViewBuilder: entityPageViewBuilder,
                        singleEditSheetViewBuilder: singleEditSheetViewBuilder,
                        singleMoveSheetViewBuilder: singleMoveSheetViewBuilder,
                        singleDeleteFunction: singleDeleteFunction,
                        singleDeleteAlertMessage: singleDeleteAlertMessage
                    )
                }
            }
            if !inSelectionMode && constantListSuffixViewBuilder != nil {
                constantListSuffixViewBuilder!()
            }
        }
        .id(inSelectionMode)
        .listStyle(.insetGrouped)
        .searchable(text: $searchQuery)
        .toolbar {
            ToolbarItemGroup(placement: .navigationBarTrailing) {
                if inSelectionMode {
                    Button { invertSelection() } label: { Text("Invert") }
                    Button { exitSelectionMode() } label: { Text("Done") }
                } else {
                    CustomListSortSelectView<Entity>(
                        selectedSort: $selectedSort,
                        sortOptions: sortOptions
                    )
                    if addEntitiesSheetViewBuilder != nil {
                        Button { showAddEntitiesView = true } label: { Text("Add") }
                    }
                    Button { enterSelectionMode() } label: { Text("Select") }
                    .disabled(entities.isEmpty)
                }
            }
            ToolbarItemGroup(placement: .bottomBar) {
                if inSelectionMode {
                    HStack {
                        let disabled: Bool = selectedEntities.isEmpty
                        if bulkEditSheetViewBuilder != nil {
                            Button { showBulkEditView = true }
                                label: { Text("Edit") }.disabled(disabled)
                        }
                        if bulkMoveSheetViewBuilder != nil {
                            Button { showBulkMoveView = true }
                                label: { Text("Move") }.disabled(disabled)
                        }
                        if bulkDeleteFunction != nil {
                            Button { showBulkDeleteAlert = true }
                                label: { Text("Delete") }.disabled(disabled)
                        }
                        if bulkExportFunction != nil {
                            Button {
                                bulkExportDocument = bulkExportFunction!(
                                    selectedEntities
                                )
                                showBulkExporter = true
                            } label: { Text("Export") }.disabled(disabled)
                        }
                    }
                }
            }
        }
        .navigationTitle(
            inSelectionMode ? "\(selectedEntities.count) Selected" : title
        )
        .sheet(isPresented: $showAddEntitiesView) {
            // Only renders when addEntitiesSheetViewBuilder != nil
            addEntitiesSheetViewBuilder!()
        }
        .sheet(isPresented: $showBulkEditView) {
            // Only renders when bulkEditSheetViewBuilder != nil
            bulkEditSheetViewBuilder!(selectedEntities, exitSelectionMode)
        }
        .sheet(isPresented: $showBulkMoveView) {
            // Only renders when bulkMoveSheetViewBuilder != nil
            bulkMoveSheetViewBuilder!(selectedEntities, exitSelectionMode)
        }
        .alert(isPresented: $showBulkDeleteAlert) {
            // Only renders when bulkDeleteFunction != nil
            Alert(
                title: Text("Are you sure?"),
                message: Text(bulkDeleteAlertMessage(selectedEntities)),
                primaryButton: .destructive(Text("Yes, delete")) {
                    withAnimation {
                        bulkDeleteFunction!(selectedEntities)
                        exitSelectionMode()
                    }
                },
                secondaryButton: .cancel(Text("No, cancel"))
            )
        }
        .fileExporter(
            isPresented: $showBulkExporter,
            document: bulkExportDocument,
            contentType: .plainText,
            defaultFilename: bulkExportDefaultDocumentName
        ) { result in
            switch result {
            case .success(let url):
                print("Saved export document to \(url)")
            case .failure(let error):
                print(error.localizedDescription)
            }
        }
    }
}

struct CustomListSectionView<
    Entity: NSManagedObject,
    EntityRowView: View,
    EntityPageView: View,
    SingleEditSheetView: View,
    SingleMoveSheetView: View
>: View {
    var section: SectionedFetchResults<String, Entity>.Section
    @Binding var selectedEntities: Set<Entity>
    var inSelectionMode: Bool
    var entityRowViewBuilder: (Entity) -> EntityRowView
    var entityPageViewBuilder: (Entity) -> EntityPageView
    var singleEditSheetViewBuilder: ((Entity) -> SingleEditSheetView)?
    var singleMoveSheetViewBuilder: ((Entity) -> SingleMoveSheetView)?
    var singleDeleteFunction: ((Entity) -> Void)?
    var singleDeleteAlertMessage: (Entity) -> String

    private var isSelected: Bool {
        for entity in section {
            if !selectedEntities.contains(entity) {
                return false
            }
        }
        return true
    }

    private func selectSection() {
        section.forEach({ entity in selectedEntities.update(with: entity) })
    }

    private func unselectSection() {
        section.forEach({ entity in selectedEntities.remove(entity) })
    }

    var body: some View {
        Section(
            header: CustomListSectionHeaderView(
                headerText: section.id,
                inSelectionMode: inSelectionMode,
                isSelected: isSelected,
                buttonAction: {
                    if isSelected { unselectSection() }
                    else { selectSection() }
                }
            )
        ) {
            ForEach(section, id: \.self) { entity in
                CustomListItemView(
                    entity: entity,
                    selectedEntities: $selectedEntities,
                    inSelectionMode: inSelectionMode,
                    rowViewBuilder: entityRowViewBuilder,
                    pageViewBuilder: entityPageViewBuilder,
                    editSheetViewBuilder: singleEditSheetViewBuilder,
                    moveSheetViewBuilder: singleMoveSheetViewBuilder,
                    deleteFunction: singleDeleteFunction,
                    deleteAlertMessage: singleDeleteAlertMessage
                )
            }
        }
    }
}

struct CustomListItemView<
    Entity: NSManagedObject,
    RowView: View,
    PageView: View,
    EditSheetView: View,
    MoveSheetView: View
>: View {
    @ObservedObject var entity: Entity
    @Binding var selectedEntities: Set<Entity>
    var inSelectionMode: Bool
    var rowViewBuilder: (Entity) -> RowView
    var pageViewBuilder: (Entity) -> PageView
    var editSheetViewBuilder: ((Entity) -> EditSheetView)?
    var moveSheetViewBuilder: ((Entity) -> MoveSheetView)?
    var deleteFunction: ((Entity) -> Void)?
    var deleteAlertMessage: (Entity) -> String

    @State private var showEditView: Bool = false
    @State private var showMoveView: Bool = false
    @State private var showDeleteAlert: Bool = false

    var body: some View {
        if inSelectionMode {
            let isSelected = selectedEntities.contains(entity)
            Button {
                if isSelected { selectedEntities.remove(entity) }
                else { selectedEntities.update(with: entity) }
            } label: {
                HStack {
                    CustomListSelectionIconView(isSelected: isSelected)
                    rowViewBuilder(entity)
                }.foregroundColor(isSelected ? .accentColor : .primary)
            }
        } else {
            NavigationLink { pageViewBuilder(entity) }
            label: { rowViewBuilder(entity) }
            .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                if deleteFunction != nil {
                    Button { showDeleteAlert = true } label: { Text("Delete") }
                    .tint(.red)
                }
                if moveSheetViewBuilder != nil {
                    Button { showMoveView = true } label: { Text("Move") }
                    .tint(.orange)
                }
                if editSheetViewBuilder != nil {
                    Button { showEditView = true } label: { Text("Edit") }
                    .tint(.blue)
                }
            }
            .sheet(isPresented: $showEditView) {
                // Only renders when editSheetViewBuilder != nil
                editSheetViewBuilder!(entity)
            }
            .sheet(isPresented: $showMoveView) {
                // Only renders when moveSheetViewBuilder != nil
                moveSheetViewBuilder!(entity)
            }
            .alert(isPresented: $showDeleteAlert) {
                // Only renders when deleteFunction != nil
                Alert(
                    title: Text("Are you sure?"),
                    message: Text(deleteAlertMessage(entity)),
                    primaryButton: .destructive(Text("Yes, delete")) {
                        withAnimation { deleteFunction!(entity) }
                    },
                    secondaryButton: .cancel(Text("No, cancel"))
                )
            }
        }
    }
}

struct CustomListSortSelectView<E>: View {
    @Binding var selectedSort: Sort<E>
    let sortOptions: [Sort<E>]

    var body: some View {
        Menu {
            Picker("Sort By", selection: $selectedSort) {
                ForEach(sortOptions, id: \.self) { sort in
                    Text(sort.name)
                }
            }
        } label: { Text("Sort") }
        .pickerStyle(.inline)
    }
}

struct CustomListSectionHeaderView: View {
    var headerText: String
    var inSelectionMode: Bool
    var isSelected: Bool
    var buttonAction: () -> Void

    var body: some View {
        if inSelectionMode {
            HStack {
                Button(
                    action: buttonAction,
                    label: {
                        CustomListSelectionIconView(isSelected: isSelected)
                        Text(headerText)
                    }
                )
            }.foregroundColor(isSelected ? .accentColor : .secondary)
        } else { Text(headerText).foregroundColor(.secondary) }
    }
}

struct CustomListSelectionIconView: View {
    var isSelected: Bool

    var body: some View {
        Image(
            systemName: isSelected
                ? "checkmark.circle.fill"
                : "checkmark.circle"
        )
    }
}
