//
//  CallsheetManager.swift
//  Magic Hour
//
//  Created by Lauri-Matti Parppei on 5.2.2025.
//

import Foundation
import PDFKit
import SwiftUI
import UniformTypeIdentifiers

public class CallSheetManager:ObservableObject {
    static let shared = CallSheetManager()
    
    @Published public var callSheets:[String: CallSheet] = [:]
    @Published public var fullScript:PDFDocument?
    
    static let projectNameKey = "projectName"
    static let projectFolder = "MagicHourProject"
    var documentsURL = CallSheetManager.getDocumentsURL()
    
    var projectName:String {
        get {
            return UserDefaults.standard.string(forKey: CallSheetManager.projectNameKey) ?? "Untitled"
        }
        set {
            UserDefaults.standard.set(newValue, forKey: CallSheetManager.projectNameKey)
        }
    }
    
    private init() {
        reload()
    }
    
    /// Returns and creates the document URL in sandbox, basically `sandbox/Documents/MagicHourProject`
    class func getDocumentsURL() -> URL {
        guard let documentsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first?.appendingPathComponent(CallSheetManager.projectFolder, conformingTo: .directory)
        else {
            print("ERROR: No document folder found");
            fatalError()
        }
        
        let fm = FileManager.default
        if !fm.fileExists(atPath: documentsURL.path()) {
            do {
                try fm.createDirectory(at: documentsURL, withIntermediateDirectories: true)
            } catch {
                print("ERROR:", error)
                fatalError()
            }
        }
        
        return documentsURL
    }
    
    
    /// Packages the available call sheets
    func package() -> URL? {
        let name = self.projectName.sanitizedFileName()
        guard let cachePath = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first
        else { return nil }
        
        let destinationURL = cachePath.appendingPathComponent(name + ".magicHour")
        
        do {
            if FileManager.default.fileExists(atPath: destinationURL.path()) {
                try FileManager.default.removeItem(at: destinationURL)
            }
            
            try FileManager.default.zipItem(at: documentsURL, to: destinationURL)
            return destinationURL
        } catch {
            print("Error saving saved call sheets: \(error.localizedDescription)")
            return nil
        }
    }
    
    /// Reloads all stored call sheets
    func reload() {
        callSheets = [:]
        fullScript = nil

        do {
            let fileURLs = try FileManager.default.contentsOfDirectory(at: documentsURL, includingPropertiesForKeys: nil)
            
            for fileURL in fileURLs where fileURL.pathExtension == "pdf" {
                guard let document = PDFDocument(url: fileURL) else { continue }
                
                let fileName = fileURL.deletingPathExtension().lastPathComponent
                let date = CallSheetManager.dateFromFileName(fileName)
                
                var callSheet = callSheets[date] ?? CallSheet(day: date)
                
                if fileName == Prefixes[.fullScript] {
                    fullScript = PDFDocument(url: fileURL)
                } else if fileName.hasPrefix(Prefixes[.callsheet]!) {
                    callSheet.pdf = document
                } else if fileName.hasPrefix(Prefixes[.dailyScript]!) {
                    callSheet.dailyScript = document
                }
                
                // Add to dictionary if applicable
                if callSheet.pdf != nil || callSheet.dailyScript != nil {
                    callSheets[date] = callSheet
                }
            }
        } catch {
            print("Error loading saved call sheets: \(error.localizedDescription)")
        }
    }
    
    /// Extracts the date from given file name
    public class func dateFromFileName(_ fileName:String) -> String {
        if let p = fileName.range(of: "_")?.upperBound {
            return String(fileName.suffix(from: p))
        } else {
            return ""
        }
    }
    
    /// Add or replace the file for current view mode
    func addOrReplaceFile(for day: Date, type:Mode, url: URL) {
        guard url.startAccessingSecurityScopedResource(),
            let document = PDFDocument(url: url) else {
            print("Not a PDF document")
            return
        }
        guard let prefix = Prefixes[type] else {
            print("No prefix for type found")
            return
        }
        
        // Get the file URL in the document directory for the given day
        // and save the PDF document as a file
        if let fileURL = getFileURL(for: day, prefix: prefix),
           let data = document.dataRepresentation() {
            do {
                try data.write(to: fileURL, options: .atomic)
            } catch {
                print("Error saving PDF: \(error.localizedDescription)")
                return
            }
        }
        
        url.stopAccessingSecurityScopedResource()
        
        // Reload all files
        CallSheetManager.shared.reload()
    }
    
    /// Deletes ALL call sheets from storage and resets state
    func deleteCallSheets() {
        UserDefaults.standard.set(nil, forKey: "projectName")
        
        let fileManager = FileManager.default
        
        do {
            let urls = try FileManager.default.contentsOfDirectory(at: documentsURL, includingPropertiesForKeys: nil)
            for url in urls where url.pathExtension == "pdf" {
                try fileManager.removeItem(at: url)
            }
        } catch {
            print("Error deleting call sheets: \(error.localizedDescription)")
        }
    }
    
    /// Delete a file with given name inside app sandbox
    func deleteFile(_ fileName:String) {
        let fileURL = documentsURL.appendingPathComponent(fileName)
        let fileManager = FileManager.default
        
        do {
            if fileManager.fileExists(atPath: fileURL.path) {
                try fileManager.removeItem(at: fileURL)
            }
        } catch {
            print("Error deleting file: \(error.localizedDescription)")
        }
        
        // Reload all documents
        CallSheetManager.shared.reload()
    }
    
    /// This is a little silly, but we return a URL for given day and document type prefix. Full script doesn't have a date at all, but a fixed file name.
    func getFileURL(for day: Date, prefix:String) -> URL? {
        // Convert the date to the string and create callsheet name
        let dateString = dayFormatter.string(from: day)
        var fileName = ""
        
        if prefix != Prefixes[.fullScript] {
            fileName = prefix + dateString + ".pdf"
        } else {
            fileName = prefix + ".pdf"
        }
        
        return documentsURL.appendingPathComponent(fileName)
    }
    
    func importPackage(url:URL, replace:Bool) {
        let fm = FileManager.default
        
        if replace { deleteCallSheets() }
        
        do {
            // Create a temporary directory for extraction
            let tempDirectory = fm.temporaryDirectory.appendingPathComponent(UUID().uuidString)
            try fm.createDirectory(at: tempDirectory, withIntermediateDirectories: true)
            
            // Unzip the file
            try fm.unzipItem(at: url, to: tempDirectory)
            
            let tempDocsUrl = tempDirectory.appendingPathComponent(CallSheetManager.projectFolder)
            let extractedUrls = try fm.contentsOfDirectory(at: tempDocsUrl, includingPropertiesForKeys: nil, options: .skipsHiddenFiles)
            
            for extractedUrl in extractedUrls {
                // Skip anything that's not a PDF to avoid any nefarious things
                if extractedUrl.pathExtension.lowercased() != "pdf" || extractedUrl.lastPathComponent.count == 0 { continue }
                
                let destination = documentsURL.appending(component: extractedUrl.lastPathComponent)
                print(extractedUrl.lastPathComponent)
                
                if fm.fileExists(atPath: destination.path) {
                    try fm.removeItem(at: destination)
                }
                    
                try fm.copyItem(at: extractedUrl, to: destination)
            }
            
            // Update project name
            var name = url.deletingPathExtension().lastPathComponent
            if name.count == 0 { name = "Untitled" }
            UserDefaults.standard.set(name, forKey: "projectKey")
        } catch {
            print("ERROR extracting:", error)
        }
        
        reload()
    }
}
