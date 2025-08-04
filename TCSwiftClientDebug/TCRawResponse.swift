//
//  TCRawResponse.swift
//  TCSwiftClientDebug
//
//  Created by Sedoykin Alexey on 04/08/2025.
//

import SwiftUI
import TCSwiftBridge

struct RawLogInlineView: View {
    let logs: [TeamcenterAPIService.RawLog]

    var body: some View {
        // Avoid List (cell reuse can chop large Text). Use ScrollView + LazyVStack.
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 16) {
                // Take last 2 logs, newest first
                let shown = Array(logs.suffix(2).reversed())
                ForEach(0..<shown.count, id: \.self) { i in
                    let log = shown[i]
                    VStack(alignment: .leading, spacing: 8) {
                        Text(log.endpoint)
                            .font(.footnote)
                            .lineLimit(2)
                        Text("Status: \(log.status)")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        
                        TextEditor(text: .constant(log.body.prettyJSON))
                            .font(.system(.body, design: .monospaced))
                            .disabled(false)
                            .textSelection(.enabled)
                            .frame(minHeight: 180)
                            .scrollContentBackground(.hidden)
                            .background(.quaternary.opacity(0.2))
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                    }
                    .padding(.horizontal)
                }
            }
            .padding(.vertical)
        }
        .navigationTitle("Raw Responses")
    }
}
