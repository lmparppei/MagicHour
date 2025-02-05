//
//  ContentView.swift
//  CallsheetApp
//
//  Created by Lauri-Matti Parppei on 30.9.2024.
//

import SwiftUI

#Preview {
    ContentView()
}

import SwiftUI
import PDFKit
import QuickLook

enum Mode:Int {
    case callsheet = 0
    case dailyScript = 1
    case fullScript = 2
}

let Prefixes:[Mode:String] = [
    .callsheet: "CallSheet_",
    .dailyScript: "DailyScript_",
    .fullScript: "FullScript"
]

struct ContentView: View {
    @ObservedObject var callSheetManager:CallSheetManager = CallSheetManager.shared
    
    @State private var selectedDay: Date = Date()
    @State private var isDocumentPickerPresented = false
    @State private var showCalendar = false
    @State private var showSettings = false
    
    //@State private var showQuickLook = false
    @State private var showDeleteConfirmation = false
    @State private var currentPDFURL: URL?
    
    @State var viewMode:Mode = .callsheet
    
    @State private var showImport = false
    @State private var importedURL:URL?
        
    var hasPDF:Bool {
        guard let callSheet = CallSheetManager.shared.callSheets[dayFormatter.string(from: selectedDay)] else { return false }
        
        if viewMode == .callsheet { return callSheet.pdf == nil }
        else if viewMode == .dailyScript { return callSheet.dailyScript == nil }
        else if viewMode == .fullScript { return CallSheetManager.shared.fullScript == nil }
        return false
    }
    
    var body: some View {
        NavigationStack {
            // PDF Display
            VStack {
                if viewMode == .callsheet {
                    if let callSheet = CallSheetManager.shared.callSheets[dayFormatter.string(from: selectedDay)], let pdf = callSheet.pdf {
                        PDFKitView(document: pdf)
                    } else {
                        Text("No Call Sheet for Today").foregroundColor(.gray).padding()
                    }
                }
                
                else if viewMode == .dailyScript {
                    if let callSheet = CallSheetManager.shared.callSheets[dayFormatter.string(from: selectedDay)], let pdf = callSheet.dailyScript {
                        PDFKitView(document: pdf)
                    } else {
                        Text("No Daily Script for Today").foregroundColor(.gray).padding()
                    }
                }
                
                else if viewMode == .fullScript {
                    if let fullScript = CallSheetManager.shared.fullScript {
                        PDFKitView(document: fullScript)
                    } else {
                        Text("No Full Script").foregroundColor(.gray).padding()
                    }
                }
            }
            Spacer()
            VStack(spacing: 0) {
                // Segmented control pinned to the bottom above the toolbar
                Picker("Document", selection: $viewMode) {
                    Text("Call Sheet").tag(Mode.callsheet)
                    Text("Daily Script").tag(Mode.dailyScript)
                    Text("Full Script").tag(Mode.fullScript)
                }
                .pickerStyle(.segmented)
            }
            .onAppear {
                CallSheetManager.shared.reload()
            }
            
            .sheet(isPresented: $isDocumentPickerPresented) {
                DocumentPicker { url in
                    CallSheetManager.shared.addOrReplaceFile(for: selectedDay, type: viewMode, url: url)
                }
            }
            .sheet(isPresented: $showCalendar) {
                CalendarView(selectedDay: $selectedDay) { date in
                    selectedDay = date
                    showCalendar = false
                }
            }
            .sheet(isPresented: $showSettings) {
                SettingsView().onDisappear {
                    CallSheetManager.shared.reload()
                }
            }

            .alert(isPresented: $showDeleteConfirmation) {
                Alert(
                    title: Text("Delete File"),
                    message: Text("Are you sure you want to delete this file? This action cannot be undone."),
                    primaryButton: .destructive(Text("Delete")) {
                        if viewMode != .fullScript, let prefix = Prefixes[viewMode] {
                            deleteFile(for: selectedDay, prefix: prefix)
                        } else {
                            deleteFullScript()
                        }
                    },
                    secondaryButton: .cancel()
                )
            }
            .toolbar {
                ToolbarItemGroup(placement: .principal) {
                    Text(displayDayFormatter.string(from: selectedDay))
                        .padding()
                }
                
                ToolbarItemGroup(placement: .navigationBarLeading) {
                    Button(action: previousDay) {
                        Image(systemName: "chevron.left")
                            .padding()
                    }
                }

                ToolbarItemGroup(placement: .navigationBarTrailing) {
                    Button(action: nextDay) {
                        Image(systemName: "chevron.right")
                            .padding()
                    }
                }
                
                ToolbarItemGroup(placement: .bottomBar) {
                    Button(action: { isDocumentPickerPresented = true }) {
                        Image(systemName: "plus")
                    }
                    .tint(.accentColor)
                    .padding()
                    
                    Button(action: { showDeleteConfirmation = true }) {
                        Image(systemName: "trash")
                    }.tint(.red).padding().disabled(hasPDF)
                    
                    Spacer()
                    /*
                    Picker("Document", selection: $viewMode) {
                        Text("Call Sheet").tag(Mode.callsheet)
                        Text("Daily Script").tag(Mode.dailyScript)
                        Text("Full Script").tag(Mode.fullScript)
                    }.pickerStyle(.segmented)
                    
                    Spacer()
                    */
                    Button(action: { showCalendar = true }) {
                        Image(systemName: "calendar")
                    }.padding()
                    
                    Button(action: { showSettings = true }) {
                        Image(systemName: "gearshape.fill")
                    }.padding()
                }
            }
            .navigationBarTitleDisplayMode(.inline)
        }
        .onOpenURL { url in
            importedURL = url
            showImport = true
        }
        .sheet(isPresented: $showImport) {
            ImportView(date: $selectedDay, url: $importedURL, onSelection: { date, type in
                showImport = false
                if let url = importedURL {
                    CallSheetManager.shared.addOrReplaceFile(for: date, type: type, url: url)
                }
                importedURL = nil
            })
        }
        
    }
    
    // Day navigation functions
    func previousDay() {
        selectedDay = Calendar.current.date(byAdding: .day, value: -1, to: selectedDay) ?? Date()
    }
    
    func nextDay() {
        selectedDay = Calendar.current.date(byAdding: .day, value: 1, to: selectedDay) ?? Date()
    }
    
    func deleteFile(for date:Date, prefix:String) {
        let dateString = dayFormatter.string(from: date)
        let fileName = prefix + dateString + ".pdf"
        
        CallSheetManager.shared.deleteFile(fileName)
    }
        
    func deleteFullScript() {
        guard let name = Prefixes[.fullScript] else { print("No document folder found"); return }
        
        let fileName = name + ".pdf"
        CallSheetManager.shared.deleteFile(fileName)
    }
}

