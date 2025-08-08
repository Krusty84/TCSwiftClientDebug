//
//  ContentView.swift
//  TCSwiftClientDebug
//
//  Created by Sedoykin Alexey on 03/08/2025.
//

import SwiftUI

struct ContentView: View {
    //@StateObject private var vm = TCViewModel()
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
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Teamcenter Demo").font(.title2).bold()
            Text("Status: \(vm.status)").font(.footnote).foregroundStyle(.secondary)
            
            Group {
                TextField("Teamcenter Base URL", text: $vm.tcBase)
                TextField("User", text: $user)
                SecureField("Password", text: $pass)
                HStack {
                    Button("Login") { Task { await vm.login(user: user, pass: pass) } }
                    Button("Session Info") { Task { await vm.loadSessionInfo() } }
                }
            }
            
            Divider()
            
            Group {
                TextField("User UID (for home folder)", text: $userUid)
                Button("Expand Home Folder") { Task { await vm.expandUserHomeFolder(userUid: userUid) } }
            }
            
            Divider()
            
                    Button("Load Saved Queries") {
                        Task { await vm.loadSavedQueries() }
                    }

                    if !vm.savedQueries.isEmpty {
                           ForEach(vm.savedQueries, id: \.uid) { q in
                               VStack(alignment: .leading) {
                                   Text(q.name).bold()
                                   Text(q.description).font(.caption).foregroundStyle(.secondary)
                                   Text("UID: \(q.uid)").font(.caption2)
                               }
                               Divider()
                           }
                       }
            Divider()
            
            Group {
                      Text("Create Relation").font(.headline)
                      TextField("First UID",      text: $firstUid)
                      TextField("First Type",     text: $firstType)
                      TextField("Second UID",     text: $secondUid)
                      TextField("Second Type",    text: $secondType)
                      TextField("Relation Type",  text: $relationType)
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
              
        
            
            Group {
                TextField("Container UID", text: $containerUid)
                HStack {
                    Button("Create Folder") {
                        Task { await vm.createFolder(name: "New Folder", desc: "From App", containerUid: containerUid, containerClass: "Folder", containerType: "Folder") }
                    }
                    Button("Create Item") {
                        Task { await vm.createItem(itemName: "My Item", itemType: "Item", description: "From App", containerUid: containerUid, containerClass: "Folder", containerType: "Folder") }
                    }
                }
            }
            
            List(vm.expandedRows, id: \.self.description) { row in
                Text(row["object_name"] as? String ?? (row["uid"] as? String ?? "-"))
            }
        }
        .padding()
    }
}

//#Preview {
//    ContentView()
//}
