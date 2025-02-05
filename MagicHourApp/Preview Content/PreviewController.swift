//
//  PreviewController.swift
//  CallsheetApp
//
//  Created by Lauri-Matti Parppei on 1.10.2024.
//

import SwiftUI
import QuickLook

struct QuickLookPreview: UIViewControllerRepresentable {
    let url: URL

    func makeUIViewController(context: Context) -> QLPreviewController {
        let previewController = QLPreviewController()
        previewController.dataSource = context.coordinator
        previewController.delegate = context.coordinator
        previewController.setEditing(true, animated: true)

        return previewController
    }

    func updateUIViewController(_ uiViewController: QLPreviewController, context: Context) {
        // No need to update the controller in this case
        uiViewController.setEditing(true, animated: true)
    }

    func makeCoordinator() -> Coordinator {
        return Coordinator(self)
    }

    class Coordinator: NSObject, QLPreviewControllerDataSource, QLPreviewControllerDelegate {
        let parent: QuickLookPreview

        init(_ parent: QuickLookPreview) {
            self.parent = parent
        }

        // MARK: - QLPreviewControllerDataSource
        func numberOfPreviewItems(in controller: QLPreviewController) -> Int {
            return 1
        }

        func previewController(_ controller: QLPreviewController, previewItemAt index: Int) -> QLPreviewItem {
            return parent.url as NSURL
        }

        // MARK: - QLPreviewControllerDelegate
        // Allow markup for annotation if available

        func previewController(_ controller: QLPreviewController, editingModeFor previewItem: any QLPreviewItem) -> QLPreviewItemEditingMode {
            return .updateContents
        }

        func previewController(_ controller: QLPreviewController, didUpdateContentsOf previewItem: QLPreviewItem) {
            // Handle the updated contents after annotation, such as saving the file back to disk.
            print("PDF contents were updated")
        }
    }
}
