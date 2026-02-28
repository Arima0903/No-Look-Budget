import SwiftUI
import SwiftData

struct QuickInputModalView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Query(sort: \ItemCategory.orderIndex) private var categories: [ItemCategory]
    
    // ウィジェットからの遷移時に初期選択されるカテゴリ名
    var initialCategoryName: String?
    
    @State private var selectedCategory: ItemCategory?
    @State private var expressionText: String = "0"
    
    let columns = Array(repeating: GridItem(.flexible(), spacing: 10), count: 3)
    
    var body: some View {
        ZStack {
            Color(red: 0.15, green: 0.15, blue: 0.16).ignoresSafeArea()
            
            VStack(spacing: 20) {
                // Handle for modal
                Capsule()
                    .fill(Color.gray.opacity(0.5))
                    .frame(width: 40, height: 5)
                    .padding(.top, 10)
                
                // ヘッダー部（閉じるボタン）
                HStack {
                    Button(action: {
                        dismiss()
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.title2)
                            .foregroundColor(.gray)
                    }
                    Spacer()
                }
                .padding(.horizontal, 20)
                .padding(.top, 10)
                
                // 入力金額表示 (上部)
                VStack(alignment: .trailing, spacing: 5) {
                    Text(expressionText)
                        .font(.system(size: 50, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                        .lineLimit(1)
                        .minimumScaleFactor(0.5)
                        .frame(maxWidth: .infinity, alignment: .trailing)
                    
                    if let result = calculateResult(), result != expressionText {
                        Text("= ¥\(result)")
                            .font(.title3)
                            .foregroundColor(.gray)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 10)
                
                // 予算項目一覧 (中段: 2行3列)
                VStack(alignment: .leading, spacing: 10) {
                    Text("予算項目を選択")
                        .font(.caption)
                        .foregroundColor(.gray)
                        .padding(.horizontal, 20)
                    
                    LazyVGrid(columns: columns, spacing: 10) {
                        ForEach(categories) { category in
                            CategorySelectButton(
                                title: category.name,
                                isSelected: selectedCategory?.id == category.id
                            ) {
                                selectedCategory = category
                            }
                        }
                    }
                    .padding(.horizontal, 20)
                }
                
                Spacer(minLength: 10)
                
                // 電卓キーパッド (下部)
                CalculatorKeypad(expressionText: $expressionText, onCommit: logExpense)
                    .padding(.horizontal, 20)
                    .padding(.bottom, 20)
            }
        }
        .onAppear {
            // 初期表示時のカテゴリ自動選択
            if let initialName = initialCategoryName,
               let targetCategory = categories.first(where: { $0.name == initialName }) {
                selectedCategory = targetCategory
            } else {
                selectedCategory = categories.first
            }
        }
    }
    
    // --- 電卓の計算ロジック ---
    private func calculateResult() -> String? {
        let expression = expressionText
            .replacingOccurrences(of: "×", with: "*")
            .replacingOccurrences(of: "÷", with: "/")
            .replacingOccurrences(of: "％", with: "/100")
        
        let validChars = CharacterSet(charactersIn: "0123456789+-*/.() ")
        if expression.rangeOfCharacter(from: validChars.inverted) != nil {
            return nil
        }
        
        let nsExpr = NSExpression(format: expression)
        if let result = nsExpr.expressionValue(with: nil, context: nil) as? NSNumber {
            let intValue = result.intValue
            return intValue >= 0 ? "\(intValue)" : "0"
        }
        return nil
    }
    
    private func logExpense() {
        guard let finalResultString = calculateResult(),
              let amount = Double(finalResultString), amount > 0 else { return }
        
        // 選択されたカテゴリの残高を減らす
        if let category = selectedCategory {
            category.spentAmount += amount
        }
        
        // トランザクション履歴として保存
        let newTransaction = ExpenseTransaction(amount: amount, isIOU: false)
        modelContext.insert(newTransaction)
        
        // （MVP仕様: 全体予算とカテゴリは連動している前提で、全体予算も減らす場合はここで処理）
        
        // Haptic Feedback
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.success)
        
        dismiss()
    }
}

// MARK: - Subviews

struct CategorySelectButton: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 14, weight: .bold))
                .foregroundColor(isSelected ? .black : .white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(isSelected ? Color.yellow : Color.gray.opacity(0.3))
                .cornerRadius(10)
        }
    }
}

// --- 電卓のキーパッド部品 ---
struct CalculatorKeypad: View {
    @Binding var expressionText: String
    let onCommit: () -> Void // 確定ボタン用
    
    let buttons: [[String]] = [
        ["C", "％", "÷", "⌫"],
        ["7", "8", "9", "×"],
        ["4", "5", "6", "-"],
        ["1", "2", "3", "+"],
        ["0", "00", ".", "="]
    ]
    
    var body: some View {
        VStack(spacing: 12) {
            ForEach(buttons, id: \.self) { row in
                HStack(spacing: 12) {
                    ForEach(row, id: \.self) { btn in
                        Button(action: {
                            handleButtonTap(btn)
                        }) {
                            Text(btn == "=" ? "使う" : btn)
                                .font(.system(size: btn == "=" ? 18 : 24, weight: .bold, design: .rounded))
                                .foregroundColor(foregroundColor(for: btn))
                                .frame(maxWidth: .infinity, maxHeight: .infinity)
                                .aspectRatio(1, contentMode: .fit) // 正方形に近づける
                                .background(backgroundColor(for: btn))
                                .clipShape(Circle())
                        }
                    }
                }
            }
        }
    }
    
    private func backgroundColor(for button: String) -> Color {
        switch button {
        case "C", "⌫": return Color.gray.opacity(0.5)
        case "％", "÷", "×", "-", "+": return Color.gray.opacity(0.4) // 赤(オレンジ)からダークテーマに合わせた色へ変更
        case "=": return Color(red: 0.4, green: 0.9, blue: 0.6) // 使うボタン
        default: return Color.white.opacity(0.15) // 数字キー
        }
    }
    
    private func foregroundColor(for button: String) -> Color {
        switch button {
        case "=": return .black // 使うボタンの文字色
        default: return .white
        }
    }
    
    private func handleButtonTap(_ btn: String) {
        let isOperator = ["+", "-", "×", "÷", "％", "."].contains(btn)
        
        switch btn {
        case "C":
            expressionText = "0"
        case "⌫":
            if expressionText.count > 1 {
                expressionText.removeLast()
            } else {
                expressionText = "0"
            }
        case "=":
            onCommit()
        default:
            if expressionText == "0" && !isOperator {
                expressionText = btn
            } else {
                // 長すぎる入力を防ぐ
                if expressionText.count < 15 {
                    expressionText.append(btn)
                }
            }
        }
    }
}

#Preview {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: Budget.self, ItemCategory.self, IOURecord.self, ExpenseTransaction.self, configurations: config)
    
    // モックデータ挿入
    let context = container.mainContext
    context.insert(ItemCategory(name: "食費", totalAmount: 50000, spentAmount: 10000, orderIndex: 0))
    context.insert(ItemCategory(name: "交際費", totalAmount: 30000, spentAmount: 15000, orderIndex: 1))
    context.insert(ItemCategory(name: "変動費", totalAmount: 20000, spentAmount: 5000, orderIndex: 2))
    context.insert(ItemCategory(name: "変動費 A", totalAmount: 20000, spentAmount: 10000, orderIndex: 3))
    context.insert(ItemCategory(name: "変動費 B", totalAmount: 10000, spentAmount: 2000, orderIndex: 4))
    context.insert(ItemCategory(name: "変動費 C", totalAmount: 15000, spentAmount: 20000, orderIndex: 5))
    
    return QuickInputModalView()
        .modelContainer(container)
}
