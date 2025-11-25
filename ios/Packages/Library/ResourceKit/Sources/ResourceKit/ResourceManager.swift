import SwiftUI

/// 资源管理器，提供对模块内资源的访问
public enum ResourceManager {
    /// 模块的 Bundle
    public static let bundle = Bundle.module

    /// 获取模拟图片
    public static var mockPhotoImage: Image {
        Image("MockPhoto", bundle: bundle)
    }

    /// 获取模拟图片的 UIImage
    public static var mockPhotoUIImage: UIImage? {
        UIImage(named: "MockPhoto", in: bundle, with: nil)
    }
}
