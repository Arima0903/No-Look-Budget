import Foundation

/// 金額を3桁カンマ区切りでフォーマットする（Int版）
/// - Parameter value: フォーマットする金額
/// - Returns: カンマ区切りの文字列（例: 1,500）
func formatCurrency(_ value: Int) -> String {
    let formatter = NumberFormatter()
    formatter.numberStyle = .decimal
    formatter.groupingSeparator = ","
    return formatter.string(from: NSNumber(value: value)) ?? "\(value)"
}

/// 金額を3桁カンマ区切りでフォーマットする（Double版）
/// - Parameter value: フォーマットする金額（小数点以下は切り捨て）
/// - Returns: カンマ区切りの文字列（例: 1,500）
func formatCurrency(_ value: Double) -> String {
    formatCurrency(Int(value))
}
