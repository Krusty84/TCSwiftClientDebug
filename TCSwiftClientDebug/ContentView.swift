//
//  ContentView.swift
//  TCSwiftClientDebug
//
//  Created by Sedoykin Alexey on 03/08/2025.
//

import SwiftUI
import TCSwiftBridge

struct ContentView: View {
    @ObservedObject var vm: TCViewModel
    @State private var user = "infodba"
    @State private var pass = "infodba"
    @State private var userUid = ""
    @State private var containerUid = ""
    @State private var firstUid = ""
    @State private var firstType = ""
    @State private var secondUid = ""
    @State private var secondType = ""
    @State private var relationType = ""
    @State private var selectedQueryUIDs = Set<String>()

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 12) {

                // Header / login
                HeaderSection(vm: vm, user: $user, pass: $pass)
                Divider()

                // Expand home folder
                ExpandHomeSection(vm: vm, userUid: $userUid)
                Divider()

                // Saved queries + description side-by-side
                SavedQueriesSplitView(
                    vm: vm,
                    selectedQueryUIDs: $selectedQueryUIDs
                )
                Divider()
                
                PreferencesSection(vm: vm)
                Divider()
                
                // Create relation
                RelationSection(
                    vm: vm,
                    firstUid: $firstUid,
                    firstType: $firstType,
                    secondUid: $secondUid,
                    secondType: $secondType,
                    relationType: $relationType
                )
                Divider()

                // Create folder/item
                CreateUnderContainerSection(
                    vm: vm,
                    containerUid: $containerUid
                )
                Divider()

                // Expanded rows (avoid Hashable Any by using indices)
                ExpandedRowsSection(expandedRows: vm.expandedRows)
            }
            .padding()
        }
    }
}

// MARK: - Sections

private struct HeaderSection: View {
    @ObservedObject var vm: TCViewModel
    @Binding var user: String
    @Binding var pass: String

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Teamcenter Demo").font(.title2).bold()
            Text("Status: \(vm.status)")
                .font(.footnote)
                .foregroundStyle(.secondary)

            // NOTE: this assumes vm.tcBase exists and is @Published String
            TextField("Teamcenter Base URL", text: $vm.tcBase)
                .textFieldStyle(.roundedBorder)

            TextField("User", text: $user)
                .textFieldStyle(.roundedBorder)

            SecureField("Password", text: $pass)
                .textFieldStyle(.roundedBorder)

            HStack {
                Button("Login") { Task { await vm.login(user: user, pass: pass) } }
                Button("Session Info") { Task { await vm.loadSessionInfo() } }
            }
        }
    }
}

private struct PreferencesSection: View {
    @ObservedObject var vm: TCViewModel
    @State private var namesCSV: String = "*"          // e.g. "TC_*,Fnd0*"
    @State private var includeDescriptions: Bool = true
    @State private var filterText: String = ""         // quick client-side filter

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Preferences").font(.headline)

            HStack(spacing: 8) {
                TextField("Names (comma-separated, * for all)", text: $namesCSV)
                    .textFieldStyle(.roundedBorder)
                Toggle("Include Descriptions", isOn: $includeDescriptions)
                    .toggleStyle(.switch)
                    .labelsHidden()
                Button("Load") {
                    Task { await vm.loadPreferences(namesCSV: namesCSV, includeDescriptions: includeDescriptions) }
                }
            }

            // simple local filter
            TextField("Filter by name/category/value…", text: $filterText)
                .textFieldStyle(.roundedBorder)

            PreferencesList(
                entries: filtered(entries: vm.preferences, q: filterText)
            )
            .frame(maxHeight: 320) // own scroll area
        }
    }

    private func filtered(entries: [PreferenceEntry], q: String) -> [PreferenceEntry] {
        let t = q.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !t.isEmpty else { return entries }
        let k = t.lowercased()
        return entries.filter { e in
            let d = e.definition
            let v = e.values?.values?.joined(separator: " ")
            return d.name.lowercased().contains(k)
                || d.category.lowercased().contains(k)
            || ((v?.lowercased().contains(k)) != nil)
        }
    }
}

private struct PreferencesList: View {
    let entries: [PreferenceEntry]

    var body: some View {
        ScrollView(.vertical) {
            VStack(alignment: .leading, spacing: 8) {
                if entries.isEmpty {
                    Text("No preferences").font(.caption).foregroundStyle(.secondary)
                } else {
                    ForEach(entries.indices, id: \.self) { i in
                        PreferenceRow(entry: entries[i])
                    }
                }
            }
            .padding(.trailing, 4)
        }
    }
}

private struct PreferenceRow: View {
    let entry: PreferenceEntry

    var body: some View {
        let def = entry.definition
        let vals = entry.values?.values ?? []             // safe fallback
        let origin = entry.values?.valueOrigination ?? "" // optional

        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(def.name).bold()
                Spacer()
                Text(scopeLabel(def.protectionScope))
                    .font(.caption2).padding(.horizontal, 6).padding(.vertical, 2)
                    .background(Color(.tertiarySystemFill))
                    .clipShape(RoundedRectangle(cornerRadius: 4))
                if def.isArray {
                    Text("Array")
                        .font(.caption2).padding(.horizontal, 6).padding(.vertical, 2)
                        .background(Color(.tertiarySystemFill))
                        .clipShape(RoundedRectangle(cornerRadius: 4))
                }
            }

            Text("Category: \(def.category)")
                .font(.caption)
                .foregroundStyle(.secondary)

            if !def.description.isEmpty {
                Text(def.description)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .lineLimit(3)
            }

            if !origin.isEmpty {
                Text("Origin: \(origin)").font(.caption2)
            }

            if vals.isEmpty {
                Text("Values: —").font(.caption2)
            } else {
                let head = vals.prefix(3)
                Text("Values: \(head.joined(separator: " | "))\(vals.count > 3 ? " … (+\(vals.count - 3))" : "")")
                    .font(.caption2)
            }
        }
        .padding(8)
        //.background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }

    private func scopeLabel(_ s: String) -> String {
        switch s.lowercased() {
        case "site": return "Site"
        case "group": return "Group"
        case "role": return "Role"
        case "user": return "User"
        default: return s
        }
    }
}

private struct ExpandHomeSection: View {
    @ObservedObject var vm: TCViewModel
    @Binding var userUid: String

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            TextField("User UID (for home folder)", text: $userUid)
                .textFieldStyle(.roundedBorder)
            Button("Expand Home Folder") {
                Task { await vm.expandUserHomeFolder(userUid: userUid) }
            }
        }
    }
}

private struct SavedQueriesSplitView: View {
    @ObservedObject var vm: TCViewModel
    @Binding var selectedQueryUIDs: Set<String>

    // actions
    private func loadSaved() { Task { await vm.loadSavedQueries() } }
    private func describeSelected() {
        let uids = Array(selectedQueryUIDs)
        Task { await vm.describeSavedQueries(uids: uids) }
    }

    var body: some View {
        // Pull data into locals so the body is simpler
        let saved = vm.savedQueries
        let fields = vm.queryFields
        let hasSaved = !saved.isEmpty
        let canDescribe = !selectedQueryUIDs.isEmpty

        return VStack(alignment: .leading, spacing: 8) {
            SavedQueriesHeader(
                hasSaved: hasSaved,
                canDescribe: canDescribe,
                loadSaved: loadSaved,
                describeSelected: describeSelected
            )

            if saved.isEmpty {
                Text("No saved queries loaded yet")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            } else {
                HStack(spacing: 16) {
                    SavedQueriesList(
                        saved: saved,
                        selectedQueryUIDs: $selectedQueryUIDs
                    )
                    Divider()
                    QueryFieldsList(fields: fields)
                }
            }
        }
    }
}

private struct RelationSection: View {
    @ObservedObject var vm: TCViewModel
    @Binding var firstUid: String
    @Binding var firstType: String
    @Binding var secondUid: String
    @Binding var secondType: String
    @Binding var relationType: String

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Create Relation").font(.headline)
            TextField("First UID", text: $firstUid).textFieldStyle(.roundedBorder)
            TextField("First Type", text: $firstType).textFieldStyle(.roundedBorder)
            TextField("Second UID", text: $secondUid).textFieldStyle(.roundedBorder)
            TextField("Second Type", text: $secondType).textFieldStyle(.roundedBorder)
            TextField("Relation Type", text: $relationType).textFieldStyle(.roundedBorder)
            Button("Make Relation") {
                Task {
                    await vm.makeRelation(
                        firstUid: firstUid,
                        firstType: firstType,
                        secondUid: secondUid,
                        secondType: secondType,
                        relationType: relationType
                    )
                }
            }
            if let rel = vm.createdRelation {
                VStack(alignment: .leading) {
                    Text("Created relation UID: \(rel.uid)")
                    Text("Class: \(rel.className), Type: \(rel.type)")
                }
                .font(.caption)
                .foregroundStyle(.blue)
            }
        }
    }
}

private struct CreateUnderContainerSection: View {
    @ObservedObject var vm: TCViewModel
    @Binding var containerUid: String

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            TextField("Container UID", text: $containerUid)
                .textFieldStyle(.roundedBorder)
            HStack {
                Button("Create Folder") {
                    Task {
                        await vm.createFolder(
                            name: "New Folder",
                            desc: "From App",
                            containerUid: containerUid,
                            containerClass: "Folder",
                            containerType: "Folder"
                        )
                    }
                }
                Button("Create Item") {
                    Task {
                        await vm.createItem(
                            itemName: "My Item",
                            itemType: "Item",
                            description: "From App",
                            containerUid: containerUid,
                            containerClass: "Folder",
                            containerType: "Folder"
                        )
                    }
                }
            }
        }
    }
}

private struct ExpandedRowsSection: View {
    let expandedRows: [[String: Any]]

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Expanded Rows").font(.headline)
            // Use a single pair param to avoid tuple-decomposition overhead
            ForEach(Array(expandedRows.enumerated()), id: \.offset) { pair in
                let row = pair.element
                Text(row["object_name"] as? String ?? (row["uid"] as? String ?? "-"))
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(6)
                    .clipShape(RoundedRectangle(cornerRadius: 6))
            }
        }
    }
}

private struct SavedQueriesList: View {
    let saved: [SavedQueryInfo]
    @Binding var selectedQueryUIDs: Set<String>

    var body: some View {
        ScrollView(.vertical) {
            VStack(alignment: .leading, spacing: 8) {
                ForEach(saved, id: \.uid) { q in
                    Toggle(isOn: bindingFor(uid: q.uid)) {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(q.name).bold()
                            Text(q.description)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            Text("UID: \(q.uid)")
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }
                        .padding(6)
                    }
                }
            }
            .padding(.trailing, 4)
        }
        .frame(maxWidth: 300, maxHeight: 320)
    }

    private func bindingFor(uid: String) -> Binding<Bool> {
        Binding(
            get: { selectedQueryUIDs.contains(uid) },
            set: { isOn in
                if isOn { selectedQueryUIDs.insert(uid) }
                else { selectedQueryUIDs.remove(uid) }
            }
        )
    }
}

private struct QueryFieldsList: View {
    let fields: [QueryFieldDescription]

    var body: some View {
        ScrollView(.vertical) {
            VStack(alignment: .leading, spacing: 8) {
                if fields.isEmpty {
                    Text("No description loaded")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                } else {
                    // Use indices to keep type-checking simple
                    ForEach(fields.indices, id: \.self) { i in
                        QueryFieldRow(f: fields[i])
                    }
                }
            }
            .padding(.trailing, 4)
        }
        .frame(maxWidth: .infinity, maxHeight: 320)
    }
}

private struct QueryFieldRow: View {
    let f: QueryFieldDescription

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(f.entryName).bold()

            Text("Attr: \(f.attributeName)")
                .font(.caption)
                .foregroundStyle(.secondary)

            Text("Type: \(f.attributeType)")
                .font(.caption2)
                .foregroundStyle(.secondary)

            if !f.logicalOperation.isEmpty {
                Text("Logic: \(f.logicalOperation)").font(.caption2)
            }
            if !f.mathOperation.isEmpty {
                Text("Math: \(f.mathOperation)").font(.caption2)
            }
            if !f.value.isEmpty {
                Text("Default/Value: \(f.value)").font(.caption2)
            }
            if !f.lovUid.isEmpty {
                Text("LOV UID: \(f.lovUid)").font(.caption2)
            }
            if !f.lovClassName.isEmpty || !f.lovType.isEmpty {
                Text("LOV Class/Type: \(f.lovClassName) \(f.lovType)")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(8)
        // .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
}

private struct SavedQueriesHeader: View {
    let hasSaved: Bool
    let canDescribe: Bool
    let loadSaved: () -> Void
    let describeSelected: () -> Void

    var body: some View {
        HStack {
            Button("Load Saved Queries", action: loadSaved)
            Spacer()
            if hasSaved {
                Button("Describe Selected", action: describeSelected)
                    .disabled(!canDescribe)
            }
        }
    }
}

//#Preview {
//    ContentView()
//}
