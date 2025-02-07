//
//  Settings.swift
//  CallsheetApp
//
//  Created by Lauri-Matti Parppei on 2.10.2024.
//

import SwiftUI
import UniformTypeIdentifiers

struct SettingsView: View {
    @State var showDeletionConfirmation = false
    @State private var editName = false
    @State private var newName = ""
    @State private var isSaving = false
    @State private var isSharing = false
    @State private var isImporting = false
    
    @State private var sharedPackageURL:URL? = nil
    
    @State var projectName = UserDefaults.standard.string(forKey: "projectName")
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Current Project")) {
                    HStack {
                        Text("Name")
                        Spacer()
                        Button(projectName ?? "Untitled") {
                            newName = projectName ?? "Untitled"
                            editName = true
                        }
                    }
                }
                Section(header: Text("Transfer Projects")) {
                    HStack {
                        Button("Share Package", systemImage: "square.and.arrow.up") {
                            sharedPackageURL = CallSheetManager.shared.package()
                        }
                    }.buttonStyle(.borderless)
                    HStack {
                        Button("Import Package", systemImage: "square.and.arrow.down") {
                            isImporting = true
                        }
                    }.buttonStyle(.borderless)
                }
                Section(header: Text("Remove Data")) {
                    HStack {
                        Button("Remove All Callsheets And Scripts", systemImage: "trash") {
                            showDeletionConfirmation.toggle()
                        }
                        .buttonStyle(.borderless)
                        .tint(.red)
                    }
                }
            }
            .navigationTitle("Settings")
            
            .alert(isPresented: $showDeletionConfirmation) {
                Alert(
                    title: Text("Delete All Call Sheets"),
                    message: Text("Are you sure you want to delete all call sheets? This action cannot be undone."),
                    primaryButton: .destructive(Text("Delete")) {
                        CallSheetManager.shared.deleteCallSheets()
                        projectName = nil
                    },
                    secondaryButton: .cancel()
                )
            }
            .alert("Enter a name", isPresented: $editName) {
                TextField("Name", text: $newName)
                Button("Cancel", role: .cancel) {}
                Button("Save") {
                    projectName = newName
                    UserDefaults.standard.set(newName, forKey: "projectName")
                }
            }
            
            .onChange(of: sharedPackageURL) {
                if sharedPackageURL != nil {
                    self.isSharing = true
                }
            }
            
            .sheet(isPresented: $isSharing) {
                if let url = sharedPackageURL {
                    ActivityViewController(activityItems: [url]).onDisappear {
                        sharedPackageURL = nil
                        isSharing = false
                    }
                }
            }
            .sheet(isPresented: $isImporting) {
                if let type = UTType("com.kapitanFI.magicHourPkg") {
                    DocumentPicker(types: [type]) { url in
                        CallSheetManager.shared.importPackage(url: url, replace: false)
                    }
                }
            }
            .toolbar {
                
            }
        }
        
        VStack(alignment: .center) {
            Image("Magic Hour 256").resizable().frame(width: 40.0, height: 40.0).presentationCornerRadius(5.0)
            Text("Magic Hour").bold().padding(2.0)
            Text("© Lauri-Matti Parppei 2025").font(.system(size: 12))
        }.padding()
    }
        
}

struct ActivityViewController: UIViewControllerRepresentable {
    let activityItems: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        let vc = UIActivityViewController(activityItems: activityItems, applicationActivities: nil)
        return vc
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}
