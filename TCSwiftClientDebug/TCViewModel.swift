//
//  TCViewModel.swift
//  TCSwiftClientDebug
//
//  Created by Sedoykin Alexey on 03/08/2025.
//

import SwiftUI
import Combine
import TCSwiftBridge

@MainActor
final class TCViewModel: ObservableObject {
    @Published var status: String = ""
    @Published var tcBase: String = "http://51.250.17.165:7001/tc"
    @Published var sessionInfo: SessionInfoResponse?
    @Published var expandedRows: [[String: Any]] = []
    @Published var savedQueries: [SavedQueryInfo] = []
    @Published var queryFields: [QueryFieldDescription] = []
    @Published var createdRelation: FolderBasic?
    // Raw log list
    @Published var rawLogs: [TeamcenterAPIService.RawLog] = []
    private let api = TeamcenterAPIService.shared
    
    init() {
        // Listen to every raw response
        api.onRaw = { [weak self] log in
            self?.rawLogs.append(log)
        }
    }
    
    // MARK: Login
    func login(user: String, pass: String) async {
        let url = APIConfig.tcLoginUrl(tcUrl: tcBase)
        if let _ = await api.tcLogin(tcEndpointUrl: url, userName: user, userPassword: pass) {
            status = "Logged in"
        } else {
            status = "Login failed"
        }
    }
    
    // MARK: Session info
    func loadSessionInfo() async {
        let url = APIConfig.tcSessionInfoUrl(tcUrl: tcBase)
        sessionInfo = await api.getTcSessionInfo(tcEndpointUrl: url)
        status = sessionInfo == nil ? "Session info failed" : "Session info loaded"
    }
    
    // MARK: Get user home folder, then expand it
    func expandUserHomeFolder(userUid: String) async {
        // Step 1: get the user's home_folder UID
        let propsUrl = APIConfig.tcGetPropertiesUrl(tcUrl: tcBase)
        guard let homeFolderUid = await api.getUserHomeFolder(tcEndpointUrl: propsUrl, userUid: userUid)
        else { status = "home_folder not found"; return }
        
        // Step 2: expand that folder
        let propertyAttributes = ["object_name", "last_mod_date", "owning_user"]
        let info: [[String: Any]] = []               // keep empty unless you need special server prefs
        let contentTypes: [String] = []              // empty = no filter
        
        if let rows = await api.expandFolder(
            tcUrl: tcBase,
            folderUid: homeFolderUid,
            className: "Folder",
            type: "Fnd0HomeFolder",
            expItemRev: true,
            latestNRevs: 1,
            info: info,
            contentTypesFilter: contentTypes,
            propertyAttributes: propertyAttributes
        ) {
            expandedRows = rows
            print("folder: ", expandedRows)
            status = "Expanded home folder (\(rows.count) items)"
        } else {
            status = "Expand failed"
        }
    }
    
    // MARK: Create a folder under a container
    func createFolder(name: String, desc: String, containerUid: String, containerClass: String, containerType: String) async {
        let url = APIConfig.tcCreateFolder(tcUrl: tcBase)
        let result = await api.createFolder(
            tcEndpointUrl: url,
            name: name,
            desc: desc,
            containerUid: containerUid,
            containerClassName: containerClass,
            containerType: containerType
        )
        status = result.uid == nil ? "Create folder failed" : "Created folder \(result.uid!)"
    }
    
    // MARK: Create an item under a container
    func createItem(itemName: String, itemType: String, description: String,
                    containerUid: String, containerClass: String, containerType: String) async {
        let url = APIConfig.tcCreateItem(tcUrl: tcBase)
        let (itemUid, itemRevUid) = await api.createItem(
            tcEndpointUrl: url,
            name: itemName,
            type: itemType,
            description: description,
            containerUid: containerUid,
            containerClassName: containerClass,
            containerType: containerType
        )
        status = (itemUid != nil) ? "Created item \(itemUid!), rev \(itemRevUid ?? "-")" : "Create item failed"
    }
    
    // MARK: Find item + rev by ID
    func getItem(itemId: String, revIds: [String]) async {
        let url = APIConfig.tcGetItemFromId(tcUrl: tcBase)
        let (itemUid, itemRevUid) = await api.getItemFromId(tcEndpointUrl: url, itemId: itemId, revIds: revIds)
        status = (itemUid != nil) ? "Found \(itemUid!), rev \(itemRevUid ?? "-")" : "Not found"
    }
    
    // MARK: Get Saved Teamcenter Query
    func loadSavedQueries() async {
        let url = APIConfig.tcGetSavedQueriesUrl(tcUrl: tcBase)
        if let list = await api.getSavedQueries(tcEndpointUrl: url) {
            savedQueries = list
            status = "Loaded \(list.count) saved queries"
        } else {
            status = "Failed to load saved queries"
        }
    }
    
    //Describe selected saved queries
    func describeSavedQueries(uids: [String]) async {
        guard !uids.isEmpty else { status = "Pick queries first"; return }
        let url = APIConfig.tcDescribeSavedQueriesUrl(tcUrl: tcBase)
        if let fields = await api.getQueryDescription(tcEndpointUrl: url, queryUids: uids) {
            queryFields = fields
            status = "Got \(fields.count) fields"
        } else {
            status = "Failed to get query description"
        }
    }
    
    //MARK: Create relation
    func makeRelation(
        firstUid: String, firstType: String,
        secondUid: String, secondType: String,
        relationType: String
    ) async {
        let url = APIConfig.tcCreateRelation(tcUrl: tcBase)
        if let rel = await api.createRelation(
            tcEndpointUrl: url,
            firstUid: firstUid,
            firstType: firstType,
            secondUid: secondUid,
            secondType: secondType,
            relationType: relationType
        ) {
            createdRelation = rel
            status = "Relation created: \(rel.uid)"
        } else {
            status = "Failed to create relation"
        }
    }
    
    // MARK: BOM example (skeleton)
    func makeBomWindow(itemUid: String) async {
        let createUrl = APIConfig.tcCreateBOMWindows(tcUrl: tcBase)
        let (winUid, lineUid) = await api.createBOMWindows(
            tcEndpointUrl: createUrl,
            itemUid: itemUid,
            revRule: "Latest Working",
            unitNo: 0,
            date: "",
            today: true,
            endItem: "",
            endItemRevision: ""
        )
        guard let window = winUid, let line = lineUid else { status = "BOM create failed"; return }
        
        // Optionally add children (example: using a created item revision UID)
        let addUrl = APIConfig.tcAddOrUpdateBOMLine(tcUrl: tcBase) // used inside the service method
        _ = addUrl // just to show the flow; method builds its own request
        // await api.addOrUpdateChildrenToParentLine(tcEndpointUrl: addUrl, parentLine: line, createdItemRevUid: "<revUid>")
        
        // Save window (payload structure depends on your TC setup)
        let saveUrl = APIConfig.tcSaveBOMWindows(tcUrl: tcBase)
        let bomWindowsPayload: [[String: Any]] = [
            ["bomWindow": window] // add more fields according to your server’s policy
        ]
        _ = await api.saveBOMWindows(tcEndpointUrl: saveUrl, bomWindows: bomWindowsPayload)
        
        // Close window
        let closeUrl = APIConfig.tcCloseBOMWindows(tcUrl: tcBase)
        _ = await api.closeBOMWindows(tcEndpointUrl: closeUrl)
        
        status = "BOM window flow done"
    }
}
