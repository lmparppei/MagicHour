//
//  Settings.swift
//  CallsheetApp
//
//  Created by Lauri-Matti Parppei on 2.10.2024.
//

import SwiftUI

struct SettingsView: View {
    @State var showDeletionConfirmation = false
    
    var body: some View {
        
        NavigationStack {
            VStack {
                Spacer()
                Button("Remove All Callsheets And Scripts") {
                    showDeletionConfirmation.toggle()
                }
                .buttonStyle(.bordered)
                .tint(.red)
                .padding()
                
                Spacer()
                
                Text("Magic Hour").bold().padding()
                Text("© Lauri-Matti Parppei 2025").font(.system(size: 12))
            }
            .padding()
            
            .alert(isPresented: $showDeletionConfirmation) {
                Alert(
                    title: Text("Delete All Call Sheets"),
                    message: Text("Are you sure you want to delete all call sheets? This action cannot be undone."),
                    primaryButton: .destructive(Text("Delete")) {
                        deleteCallSheets()
                        //loadSavedCallSheets()
                    },
                    secondaryButton: .cancel()
                )
            }
            
            .navigationTitle("Settings")
        }
    }
    
    func deleteCallSheets() {
        // Delete the associated file from storage
        let fileManager = FileManager.default
        
        guard let documentDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else { return }
        
        do {
            let urls = try FileManager.default.contentsOfDirectory(at: documentDirectory, includingPropertiesForKeys: nil)
            
            for url in urls where url.pathExtension == "pdf" {
                try fileManager.removeItem(at: url)
            }
        } catch {
            print("Error deleting call sheets: \(error.localizedDescription)")
        }
    
    }
    
}
