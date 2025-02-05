//
//  ImportView.swift
//  Magic Hour
//
//  Created by Lauri-Matti Parppei on 4.2.2025.
//

import SwiftUI

struct ImportView: View {
    @Binding var date:Date
    @Binding var url:URL?
    
    @ObservedObject var callSheetManager = CallSheetManager.shared
    @State var type:Mode = .callsheet
    
    var onSelection:(Date, Mode) -> Void
    
    var body: some View {
        NavigationStack {
            VStack {

                Text(url?.deletingPathExtension().lastPathComponent ?? "-").bold().padding()
                Picker("Import As", selection: $type) {
                    Text("Call Sheet").tag(Mode.callsheet)
                    Text("Daily Script").tag(Mode.dailyScript)
                    Text("Full Script").tag(Mode.fullScript)
                }.pickerStyle(.segmented).padding()
                
                if type == .callsheet || type == .dailyScript {
                    CalendarView(selectedDay: $date) { date in
                        self.date = date
                        //onSelection(date, type)
                    }
                    Spacer()
                } else {
                    Spacer()
                    Text("This file will be set as the full script")
                    Spacer()
                }
            }
            .toolbar {
                if type == .callsheet || type == .dailyScript {
                    Button("Add " + (type == .callsheet ? "Callsheet" : "Daily Script")) {
                        onSelection(date, type)
                    }.buttonStyle(.borderedProminent)
                } else {
                    Button("Add Full Script") {
                        onSelection(date, type)
                    }.buttonStyle(.borderedProminent)
                }
            }.navigationTitle("Add File")
        }
    }
}
