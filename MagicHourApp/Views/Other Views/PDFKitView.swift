//
//  PDFKitView.swift
//  CallsheetApp
//
//  Created by Lauri-Matti Parppei on 6.10.2024.
//

import SwiftUI
import PDFKit

/// Singleton for remembering scroll position
class PDFScrollManager: ObservableObject {
    static let shared = PDFScrollManager()
    private var positions: [String: (page: Int, offset: CGFloat)] = [:]

    private init() {}

    func savePosition(for document: PDFDocument, page: Int, offset: CGFloat) {
        guard let documentID = document.documentURL?.absoluteString else { return }
        positions[documentID] = (page, offset)
    }

    func getPosition(for document: PDFDocument) -> (page: Int, offset: CGFloat)? {
        guard let documentID = document.documentURL?.absoluteString else { return nil }
        return positions[documentID]
    }
}

struct PDFKitView: UIViewRepresentable {
    let document: PDFDocument

    func makeUIView(context: Context) -> PDFView {
        let pdfView = PDFView()
        pdfView.document = document
        pdfView.autoScales = true
        pdfView.displayMode = .singlePageContinuous
        pdfView.backgroundColor = .systemBackground

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            restoreScrollPosition(pdfView)
        }

        return pdfView
    }

    func updateUIView(_ pdfView: PDFView, context: Context) {
        pdfView.document = document

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            restoreScrollPosition(pdfView)
        }
    }

    private func restoreScrollPosition(_ pdfView: PDFView) {
        guard let document = pdfView.document,
              let savedPosition = PDFScrollManager.shared.getPosition(for: document),
              let page = document.page(at: savedPosition.page) else { return }

        let destination = PDFDestination(page: page, at: CGPoint(x: 0, y: savedPosition.offset))
        pdfView.go(to: destination)
    }

    static func dismantleUIView(_ uiView: PDFView, coordinator: ()) {
        let pdfView = uiView
        guard let currentPage = pdfView.currentPage,
              let document = pdfView.document else { return }

        let pageIndex = document.index(for: currentPage)
        let pageBounds = currentPage.bounds(for: pdfView.displayBox)
        let currentOffset = pdfView.convert(pdfView.bounds.origin, to: currentPage).y

        PDFScrollManager.shared.savePosition(for: document, page: pageIndex, offset: currentOffset)
    }
}
