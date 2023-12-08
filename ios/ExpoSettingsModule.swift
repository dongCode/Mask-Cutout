import ExpoModulesCore

public class ExpoSettingsModule: Module {
  public func definition() -> ModuleDefinition {
    Name("ExpoSettings")
    Events("onChangeImage")

    Function("getTheme") { () -> String in
      "system"
    }

     // 导出 processImages 函数
    Function("processImages") { 
      (maskImageUri: String, originalImageUri: String) in
            // 异步调用处理图片的逻辑
            DispatchQueue.global().async {
                // 获取 maskImage 和 originalImage 的 UIImage
                let maskImageUrl = URL(string: maskImageUri)!
                let originalImageUrl = URL(string: originalImageUri)!
                guard let maskImageData = try? Data(contentsOf: maskImageUrl),
                      let maskImage = UIImage(data: maskImageData) else {
                  return
                }
                guard let originalImageData = try? Data(contentsOf: originalImageUrl),
                      let originalImage = UIImage(data: originalImageData) else {
                  return
                }

                // 在这里添加你的图片处理逻辑
                let processedImage = self.processImages(maskImage: maskImage, originalImage: originalImage)

                // 将处理后的 UIImage 转成 base64 字符串
                guard let processedImageBase64 = processedImage?.toBase64() else {
                    return
                }

                self.sendEvent("onChangeImage", [
                        "base64": processedImageBase64
                ])
            }
        }
  }

  func processImages(maskImage: UIImage, originalImage: UIImage) -> UIImage? {
      guard let maskCGImage = maskImage.cgImage, let colorCGImage = originalImage.cgImage else {
             return nil
         }

         let width = maskCGImage.width
         let height = maskCGImage.height

         let colorSpace = CGColorSpaceCreateDeviceRGB()

         // 创建一个图形上下文
         guard let context = CGContext(data: nil, width: width, height: height, bitsPerComponent: 8, bytesPerRow: width * 4, space: colorSpace, bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue) else {
             return nil
         }

         // 绘制遮罩图
         context.draw(maskCGImage, in: CGRect(x: 0, y: 0, width: width, height: height))

         // 获取遮罩图像素数据
         guard let maskImageData = context.makeImage()?.dataProvider?.data, let maskPixels = CFDataGetBytePtr(maskImageData) else {
             return nil
         }

         // 绘制彩色图
         context.clear(CGRect(x: 0, y: 0, width: width, height: height))
         context.draw(colorCGImage, in: CGRect(x: 0, y: 0, width: width, height: height))

         // 获取彩色图像素数据
      guard let colorImageData = context.makeImage()?.dataProvider?.data, let colorMutableData = CFDataCreateMutableCopy(nil, 0, colorImageData), var colorPixels = CFDataGetMutableBytePtr(colorMutableData) else {
          return nil
      }

         // 处理每个像素
         for i in 0..<width * height {
             let index = i * 4 // 每个像素占4个字节

             // 判断遮罩图的像素是否为黑色
             if maskPixels[index] == 0 && maskPixels[index + 1] == 0 && maskPixels[index + 2] == 0 {
                 // 将彩色图对应像素设为白色
                 colorPixels[index] = 255
                 colorPixels[index + 1] = 255
                 colorPixels[index + 2] = 255
                 colorPixels[index + 3] = 255
             }
         }
      
      let data = NSData(bytes: colorPixels, length: width * height * 4)
      guard let dataProvider = CGDataProvider(data: data),
            let cgImage = CGImage(
                  width: width,
                  height: height,
                  bitsPerComponent: 8,
                  bitsPerPixel: 32,
                  bytesPerRow: width * 4,
                  space: CGColorSpaceCreateDeviceRGB(),
                  bitmapInfo: CGBitmapInfo(rawValue: CGImageAlphaInfo.premultipliedLast.rawValue),
                  provider: dataProvider,
                  decode: nil,
                  shouldInterpolate: false,
                  intent: .defaultIntent
              )
        else {
            return nil
        }

        // 将 CGImage 转换为 UIImage
        return UIImage(cgImage: cgImage)

    

  
}
}

extension UIImage {
    // 将 UIImage 转成 base64 字符串
    func toBase64() -> String? {
        guard let imageData = self.pngData() else { return nil }
        return imageData.base64EncodedString()
    }
}
