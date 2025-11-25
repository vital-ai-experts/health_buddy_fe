import Foundation

/// Mock 聊天相关的工具
public enum ChatMocking {
    /// 触发 mock 流程的前缀
    public static let prefix = "#mock#"

    /// 图片上传消息的标识前缀
    public static let photoUploadPrefix = "[图片上传]"

    /// 请求图片上传的关键词（系统消息中包含这些词时，会触发自动上传图片）
    public static let photoRequestKeywords = ["请拍摄", "请上传", "请发送照片"]

    /// 是否包含 mock 前缀（会先做首尾空白裁剪）
    public static func hasMockPrefix(in text: String) -> Bool {
        text.trimmingCharacters(in: .whitespacesAndNewlines).hasPrefix(prefix)
    }

    /// 移除 mock 前缀后的纯文本（会移除首尾空白）
    public static func stripMockPrefix(from text: String) -> String {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard trimmed.hasPrefix(prefix) else { return trimmed }
        let dropped = trimmed.dropFirst(prefix.count)
        return dropped.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    // MARK: - Photo Upload

    /// 检查消息是否是图片上传消息
    public static func isPhotoUploadMessage(_ text: String) -> Bool {
        text.hasPrefix(photoUploadPrefix)
    }

    /// 从图片上传消息中提取任务名称
    /// 格式: "[图片上传]任务名称"
    public static func extractTaskNameFromPhotoUpload(_ text: String) -> String {
        guard text.hasPrefix(photoUploadPrefix) else { return text }
        return String(text.dropFirst(photoUploadPrefix.count)).trimmingCharacters(in: .whitespacesAndNewlines)
    }

    /// 生成图片上传消息
    /// - Parameter taskName: 任务名称
    /// - Returns: 带mock前缀的图片上传消息
    public static func makePhotoUploadMessage(for taskName: String) -> String {
        return "\(prefix)\(photoUploadPrefix)\(taskName)"
    }

    /// 检查系统消息是否在请求上传图片
    public static func isRequestingPhotoUpload(in text: String) -> Bool {
        for keyword in photoRequestKeywords {
            if text.contains(keyword) {
                return true
            }
        }
        return false
    }

    /// 从系统消息中提取任务名称（用于后续的图片上传）
    /// 根据上下文推断任务名称
    public static func extractTaskNameFromRequest(_ requestText: String, userMessageText: String) -> String {
        // 优先从用户消息中提取任务名称
        let taskKeywords = ["采集光子", "彩虹协议", "晨曦猎人", "填充冷却液", "最后一杯",
                           "燃烧葡萄糖", "系统强制冷却", "全景扫描", "模式切换",
                           "调暗灯光", "切断连接", "强制关机", "引擎重铸", "静默领域"]
        for keyword in taskKeywords {
            if userMessageText.contains(keyword) {
                return keyword
            }
        }
        return "任务"
    }
}
