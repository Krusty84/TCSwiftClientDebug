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
