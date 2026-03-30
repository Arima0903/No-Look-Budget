import Foundation
import SwiftData
import SwiftUI
import Combine

@MainActor
class QuickInputViewModel: ObservableObject {
    @Published var selectedCategory: ItemCategory?
    @Published var selectedIncomeCategory: String? = "給与"
    @Published var expressionText: String = "0"
    @Published var isIOUMode: Bool = false
    
    // 2段入力用
    @Published var iouExpression: String = "0"
    @Published var myExpenseExpression: String = "0"
    enum InputFocus {
        case iou
        case myExpense
    }
    @Published var currentFocus: InputFocus = .iou
    
    @Published var inputMode: QuickInputMode = .expense
    
    @Published var categories: [ItemCategory] = []
    
    @Published var alertMessage: String? = nil
    @Published var showAlert: Bool = false

    // メモ（案B: 折りたたみ式）
    @Published var memo: String = ""
    @Published var showMemoField: Bool = false

    // 入力完了ポップアップ
    @Published var showCompletionPopup: Bool = false
    @Published var completionAmount: String = ""
    @Published var completionCategory: String = ""
    
    let initialCategoryName: String?
    var editingTransactionId: UUID?
    
    private let context: ModelContext
    private let transactionService: TransactionServiceProtocol
    
    init(initialCategoryName: String?, editingTransactionId: UUID? = nil, initialAmount: String = "0", isIncome: Bool = false, isIOU: Bool = false, context: ModelContext? = nil) {
        self.initialCategoryName = initialCategoryName
        self.editingTransactionId = editingTransactionId
        self.expressionText = initialAmount
        self.inputMode = isIncome ? .income : .expense
        self.isIOUMode = isIOU
        
        let ctx = context ?? SharedModelContainer.shared.mainContext
        self.context = ctx
        self.transactionService = TransactionService(context: ctx)
        fetchCategories()
    }
    
    func fetchCategories() {
        let descriptor = FetchDescriptor<ItemCategory>(sortBy: [SortDescriptor(\.orderIndex)])
        self.categories = (try? context.fetch(descriptor)) ?? []
        
        if let initialName = initialCategoryName,
           let target = categories.first(where: { $0.name == initialName }) {
            self.selectedCategory = target
        } else {
            self.selectedCategory = categories.first
        }
    }
    
    func calculateResult() -> String? {
        return calculateResult(for: expressionText)
    }
    
    func calculateResult(for expressionText: String) -> String? {
        let expression = expressionText
            .replacingOccurrences(of: "×", with: "*")
            .replacingOccurrences(of: "÷", with: "/")
            .replacingOccurrences(of: "％", with: "/100")
        
        let validChars = CharacterSet(charactersIn: "0123456789+-*/.() ")
        if expression.rangeOfCharacter(from: validChars.inverted) != nil {
            return nil
        }
        
        // 末尾が演算子や小数点の場合は計算式として不完全なので評価しない
        if let last = expression.last, "+-*/.".contains(last) {
            return nil
        }
        
        // 連続する演算子がある場合は評価しない
        if expression.contains("++") || expression.contains("--") || expression.contains("**") || expression.contains("//") ||
           expression.contains("+-") || expression.contains("-+") || expression.contains("*/") || expression.contains("/*") {
            return nil
        }
        
        let nsExpr = NSExpression(format: expression)
        if let result = nsExpr.expressionValue(with: nil, context: nil) as? NSNumber {
            let intValue = result.intValue
            return intValue >= 0 ? "\(intValue)" : "0"
        }
        return nil
    }
    
    // 成功したら true を返す
    func logExpense() -> Bool {
        if inputMode == .expense && isIOUMode {
            // 2段入力の保存処理
            let totalValStr = calculateResult(for: iouExpression) ?? iouExpression
            let myValStr = calculateResult(for: myExpenseExpression) ?? myExpenseExpression
            
            let totalAmount = Double(totalValStr) ?? 0
            let myExpenseAmount = Double(myValStr) ?? 0
            
            // バリデーション
            if myExpenseExpression == "0" {
                self.alertMessage = "自分の支出額を入力してください。（立て替えたのみで自分の支出が本当に0円の場合は「0+0」などとご入力ください）"
                self.showAlert = true
                return false
            }
            if totalAmount < myExpenseAmount {
                self.alertMessage = "立替総額が自分の支出額より小さくなっています。正しい金額を入力してください。"
                self.showAlert = true
                return false
            }
            
            let actualIOUAmount = totalAmount - myExpenseAmount
            
            let memoValue = memo.isEmpty ? nil : memo
            if actualIOUAmount > 0 {
                try? transactionService.addExpense(amount: actualIOUAmount, category: selectedCategory, isIOU: true, memo: memoValue)
            }
            if myExpenseAmount > 0 {
                try? transactionService.addExpense(amount: myExpenseAmount, category: selectedCategory, isIOU: false, memo: memoValue)
            }
            // 完了ポップアップ用データをセット（立替総額を表示）
            self.completionAmount = "¥\(formatCurrency(totalAmount))"
            self.completionCategory = (selectedCategory?.name ?? "その他") + "（立替含む）"
        } else {
            // 通常の1段入力の保存処理
            guard let finalResultString = calculateResult(),
                  let amount = Double(finalResultString), amount > 0 else { return false }

            let memoValue = memo.isEmpty ? nil : memo
            if let id = editingTransactionId {
                if inputMode == .income {
                    try? transactionService.updateIncome(id: id, amount: amount)
                } else {
                    try? transactionService.updateExpense(id: id, amount: amount, category: selectedCategory, isIOU: false, memo: memoValue)
                }
            } else {
                if inputMode == .income {
                    try? transactionService.addIncome(amount: amount)
                } else {
                    try? transactionService.addExpense(amount: amount, category: selectedCategory, isIOU: false, memo: memoValue)
                }
            }
            // 完了ポップアップ用データをセット
            self.completionAmount = "¥\(formatCurrency(amount))"
            if inputMode == .income {
                self.completionCategory = selectedIncomeCategory ?? "収入"
            } else {
                self.completionCategory = selectedCategory?.name ?? "その他"
            }
        }
        
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.success)
        return true
    }

    // 完了ポップアップを閉じて次の入力に備えてフォームをリセット
    func resetForNextEntry() {
        expressionText = "0"
        iouExpression = "0"
        myExpenseExpression = "0"
        memo = ""
        showMemoField = false
        showCompletionPopup = false
    }
}
