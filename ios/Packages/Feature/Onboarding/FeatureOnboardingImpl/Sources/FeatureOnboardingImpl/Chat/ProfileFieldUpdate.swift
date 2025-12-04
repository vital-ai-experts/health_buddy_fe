import Foundation

/// 基础档案可编辑字段
enum ProfileFieldUpdate: Identifiable {
    case gender(String)
    case age(Int)
    case height(Int)
    case weight(Int)

    var id: String {
        switch self {
        case .gender: return "gender"
        case .age: return "age"
        case .height: return "height"
        case .weight: return "weight"
        }
    }
}
