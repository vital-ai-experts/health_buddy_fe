import Foundation

/// Chat 场景的通用 mock 工具
public enum ChatMocking {
    public static let prefix = "#mock#"
    public static let photoUploadPrefix = "[图片上传]"
    public static let photoRequestKeywords = ["请拍摄", "请上传", "请发送照片"]

    public static func hasMockPrefix(in text: String) -> Bool {
        text.trimmingCharacters(in: .whitespacesAndNewlines).hasPrefix(prefix)
    }

    public static func stripMockPrefix(from text: String) -> String {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard trimmed.hasPrefix(prefix) else { return trimmed }
        let dropped = trimmed.dropFirst(prefix.count)
        return dropped.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    public static func isPhotoUploadMessage(_ text: String) -> Bool {
        text.hasPrefix(photoUploadPrefix)
    }

    public static func extractTaskNameFromPhotoUpload(_ text: String) -> String {
        guard text.hasPrefix(photoUploadPrefix) else { return text }
        return String(text.dropFirst(photoUploadPrefix.count)).trimmingCharacters(in: .whitespacesAndNewlines)
    }

    public static func makePhotoUploadMessage(for taskName: String) -> String {
        return "\(prefix)\(photoUploadPrefix)\(taskName)"
    }

    public static func isRequestingPhotoUpload(in text: String) -> Bool {
        for keyword in photoRequestKeywords where text.contains(keyword) {
            return true
        }
        return false
    }

    public static func extractTaskNameFromRequest(_ requestText: String, userMessageText: String) -> String {
        let taskKeywords = ["采集光子", "彩虹协议", "晨曦猎人", "填充冷却液", "最后一杯",
                           "燃烧葡萄糖", "系统强制冷却", "全景扫描", "模式切换",
                           "调暗灯光", "切断连接", "强制关机", "引擎重铸", "静默领域"]
        for keyword in taskKeywords where userMessageText.contains(keyword) {
            return keyword
        }
        return "任务"
    }
}
