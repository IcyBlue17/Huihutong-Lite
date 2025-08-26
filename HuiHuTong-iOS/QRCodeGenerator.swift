import UIKit
import CoreImage.CIFilterBuiltins

class QRCodeGenerator {
    // 使用单例模式减少创建开销
    static private let context = CIContext()
    
    static func generateQRCode(from string: String) -> UIImage? {
        let filter = CIFilter.qrCodeGenerator()
        filter.message = Data(string.utf8)
        filter.correctionLevel = "M" // 中等错误纠正级别，平衡大小和纠错能力
        
        guard let outputImage = filter.outputImage else { return nil }
        
        // 使用更精确的缩放
        let scaleX = 300.0 / outputImage.extent.width
        let scaleY = 300.0 / outputImage.extent.height
        let scale = min(scaleX, scaleY)
        
        let transform = CGAffineTransform(scaleX: scale, y: scale)
        let scaledImage = outputImage.transformed(by: transform)
        
        // 使用缓存的context提高性能
        if let cgImage = context.createCGImage(scaledImage, from: scaledImage.extent) {
            return UIImage(cgImage: cgImage)
        }
        
        return nil
    }
}
