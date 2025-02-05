//
//  CallSheet.swift
//  Magic Hour
//
//  Created by Lauri-Matti Parppei on 5.2.2025.
//

import Foundation
import PDFKit

/// A misleading name. This is a basic struct which represents all data for given day, and `.pdf` is the actual callsheet.
public struct CallSheet: Identifiable {
    public let id = UUID()
    public let day: String
    public var pdf: PDFDocument?
    public var dailyScript: PDFDocument?
}

