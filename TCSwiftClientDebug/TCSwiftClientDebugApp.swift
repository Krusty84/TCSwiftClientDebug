//
//  TCSwiftClientDebugApp.swift
//  TCSwiftClientDebug
//
//  Created by Sedoykin Alexey on 03/08/2025.
//

import SwiftUI

@main
struct TCSwiftClientDebugApp: App {
    @StateObject private var vm = TCViewModel()
    var body: some Scene {
        WindowGroup {
            TabView {
                ContentView(vm: vm)
                    .tabItem { Label("Demo", systemImage: "rectangle.and.text.magnifyingglass") }
                
              RawLogInlineView(logs: vm.rawLogs).tabItem { Label("Raw", systemImage: "doc.text.magnifyingglass") }
            }
        }
    }
}

extension Data {
    var prettyJSON: String {
        guard !isEmpty else { return "" }
        do {
            let obj = try JSONSerialization.jsonObject(with: self, options: [])
            let data = try JSONSerialization.data(withJSONObject: obj, options: [.prettyPrinted])
            return String(data: data, encoding: .utf8) ?? String(decoding: self, as: UTF8.self)
        } catch {
            // If not JSON, show as text
            return String(decoding: self, as: UTF8.self)
        }
    }
}

