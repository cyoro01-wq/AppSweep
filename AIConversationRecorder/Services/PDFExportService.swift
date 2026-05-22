import Foundation
import UIKit

class PDFExportService {
    func export(record: ConversationRecord) -> URL? {
        let bounds = CGRect(x: 0, y: 0, width: 595, height: 842)
        let renderer = UIGraphicsPDFRenderer(bounds: bounds)
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent("\(record.title).pdf")

        let attrs: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 12)
        ]
        let body = "\(record.title)\n\n\(record.summary)\n\n" +
            record.transcriptSegments.map { "\($0.speakerName): \($0.text)" }.joined(separator: "\n")

        try? renderer.writePDF(to: url) { ctx in
            ctx.beginPage()
            body.draw(in: CGRect(x: 40, y: 40, width: 515, height: 762), withAttributes: attrs)
        }
        return url
    }
}
