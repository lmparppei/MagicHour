//
//  CallsheetManager.swift
//  Magic Hour
//
//  Created by Lauri-Matti Parppei on 5.2.2025.
//

import Foundation
import PDFKit

public class CallSheetManager:ObservableObject {
    static let shared = CallSheetManager()
    
    @Published public var callSheets:[String: CallSheet] = [:]
    @Published public var fullScript:PDFDocument?
    
    private init() {
        reload()
    }
    
    /// Packages the available call sheets
    func package() -> Data? {
        guard let documentDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else { return nil }
        let destinationURL = documentDirectory.appendingPathComponent("Package.magicHour")
        
        do {
            try FileManager.default.zipItem(at: documentDirectory, to: destinationURL)
        } catch {
            print("Error loading saved call sheets: \(error.localizedDescription)")
        }
        
        return Data()
    }
    
    /// Reloads all stored call sheets
    func reload() {
        guard let documentDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else { print("Reload failed"); return }
        
        callSheets = [:]
        fullScript = nil

        do {
            let fileURLs = try FileManager.default.contentsOfDirectory(at: documentDirectory, includingPropertiesForKeys: nil)
            
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
        print("TYPE:", type)
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
        let fileURL = getFileURL(for: day, prefix: prefix)
        
        // Save the PDF document as a file
        if let data = document.dataRepresentation() {
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
    
    /// Delete a file with given name inside app sandbox
    func deleteFile(_ fileName:String) {
        guard let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else { print("No document folder found"); return }
        
        let fileURL = documentsDirectory.appendingPathComponent(fileName)
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
    func getFileURL(for day: Date, prefix:String) -> URL {
        // Convert the date to the string and create callsheet name
        let dateString = dayFormatter.string(from: day)
        var fileName = ""
        
        if prefix != Prefixes[.fullScript] {
            fileName = prefix + dateString + ".pdf"
        } else {
            fileName = prefix + ".pdf"
        }
        
        let documentDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        return documentDirectory.appendingPathComponent(fileName)
    }
}
