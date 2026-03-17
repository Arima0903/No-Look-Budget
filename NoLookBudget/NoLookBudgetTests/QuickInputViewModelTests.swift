import XCTest
import SwiftData
@testable import NoLookBudget

// MARK: - PT（プログラムテスト）: QuickInputViewModel
// 対象: docs/QA/PT_test_cases.md の PT-QI-001〜007、PT-CR-001〜009

@MainActor
final class QuickInputViewModelTests: XCTestCase {

    var container: ModelContainer!
    var context: ModelContext!
    var viewModel: QuickInputViewModel!

    override func setUpWithError() throws {
        container = SharedModelContainer.createInMemoryContainer()
        context = container.mainContext

        // テスト用の初期データ
        let budget = Budget(month: Date(), totalAmount: 150_000, spentAmount: 0)
        context.insert(budget)

        let category = ItemCategory(name: "食費", totalAmount: 50_000, spentAmount: 0, orderIndex: 0)
        context.insert(category)
        try context.save()

        viewModel = QuickInputViewModel(initialCategoryName: "食費", context: context)
    }

    override func tearDownWithError() throws {
        context?.rollback()
    }

    // MARK: - PT-CR: calculateResult のテスト（純粋関数）

    // PT-CR-001: 単純な数値 "500" → "500"
    func test_calculateResult_simpleNumber() {
        XCTAssertEqual(viewModel.calculateResult(for: "500"), "500")
    }

    // PT-CR-002: 加算 "100+200" → "300"
    func test_calculateResult_addition() {
        XCTAssertEqual(viewModel.calculateResult(for: "100+200"), "300")
    }

    // PT-CR-003: 掛け算（×） "100×3" → "300"
    func test_calculateResult_multiplication() {
        XCTAssertEqual(viewModel.calculateResult(for: "100×3"), "300")
    }

    // PT-CR-004: 割り算（÷） "300÷3" → "100"
    func test_calculateResult_division() {
        XCTAssertEqual(viewModel.calculateResult(for: "300÷3"), "100")
    }

    // PT-CR-005: 末尾が演算子 "100+" → nil
    func test_calculateResult_trailingOperator_returnsNil() {
        XCTAssertNil(viewModel.calculateResult(for: "100+"))
        XCTAssertNil(viewModel.calculateResult(for: "500-"))
        XCTAssertNil(viewModel.calculateResult(for: "200×"))
    }

    // PT-CR-006: 連続演算子 "100++200" → nil
    func test_calculateResult_consecutiveOperators_returnsNil() {
        XCTAssertNil(viewModel.calculateResult(for: "100++200"))
        XCTAssertNil(viewModel.calculateResult(for: "100--200"))
        XCTAssertNil(viewModel.calculateResult(for: "100**200"))
    }

    // PT-CR-007: 不正文字 "abc" → nil
    func test_calculateResult_invalidChars_returnsNil() {
        XCTAssertNil(viewModel.calculateResult(for: "abc"))
        XCTAssertNil(viewModel.calculateResult(for: "1万円"))
        XCTAssertNil(viewModel.calculateResult(for: "1,000"))
    }

    // PT-CR-008: 負の結果 "100-200" → "0"（負の支出は0に丸める）
    func test_calculateResult_negativeResult_returnsZero() {
        XCTAssertEqual(viewModel.calculateResult(for: "100-200"), "0")
    }

    // PT-CR-009: パーセント "1000％" → "10"（1000 / 100）
    func test_calculateResult_percentage() {
        XCTAssertEqual(viewModel.calculateResult(for: "1000％"), "10")
    }

    // MARK: - PT-QI: logExpense のテスト

    // PT-QI-001: 通常支出が正常に保存される（return true）
    func test_logExpense_normalExpense_returnsTrue() throws {
        // Arrange
        viewModel.expressionText = "500"
        viewModel.inputMode = .expense
        viewModel.isIOUMode = false

        // Act
        let result = viewModel.logExpense()

        // Assert
        XCTAssertTrue(result, "正常な支出入力では true を返すべき")

        let txDescriptor = FetchDescriptor<ExpenseTransaction>()
        let transactions = try context.fetch(txDescriptor)
        XCTAssertEqual(transactions.count, 1)
        XCTAssertEqual(transactions.first?.amount, 500)
    }

    // PT-QI-002: 金額 0 の支出は保存されない（return false）
    func test_logExpense_zeroAmount_returnsFalse() {
        // Arrange
        viewModel.expressionText = "0"
        viewModel.inputMode = .expense
        viewModel.isIOUMode = false

        // Act
        let result = viewModel.logExpense()

        // Assert
        XCTAssertFalse(result, "金額 0 の入力では false を返すべき")
    }

    // PT-QI-003: 2段入力（立替）の正常保存
    func test_logExpense_iouMode_savesCorrectly() throws {
        // Arrange: 合計 5000、自己支出 2000 → IOU = 3000
        viewModel.inputMode = .expense
        viewModel.isIOUMode = true
        viewModel.iouExpression = "5000"
        viewModel.myExpenseExpression = "2000"

        // Act
        let result = viewModel.logExpense()

        // Assert
        XCTAssertTrue(result, "正常な2段入力では true を返すべき")

        let txDescriptor = FetchDescriptor<ExpenseTransaction>()
        let transactions = try context.fetch(txDescriptor)

        // IOU 3000 と 通常 2000 の 2件が保存される
        XCTAssertEqual(transactions.count, 2, "IOU分と自己支出分の2件が保存されるべき")

        let iouTx = transactions.first(where: { $0.isIOU })
        let normalTx = transactions.first(where: { !$0.isIOU })
        XCTAssertEqual(iouTx?.amount, 3_000, "IOU分は総額 - 自己支出 = 3000 であるべき")
        XCTAssertEqual(normalTx?.amount, 2_000, "自己支出分は 2000 であるべき")
    }

    // PT-QI-004: VLD-101: 2段入力で自己支出未入力（"0"）はエラー
    func test_logExpense_iouMode_zeroMyExpense_showsAlert() {
        // Arrange: 自己支出が "0" のまま
        viewModel.inputMode = .expense
        viewModel.isIOUMode = true
        viewModel.iouExpression = "5000"
        viewModel.myExpenseExpression = "0"  // 未入力（"0"のまま）

        // Act
        let result = viewModel.logExpense()

        // Assert
        XCTAssertFalse(result, "自己支出未入力では false を返すべき")
        XCTAssertTrue(viewModel.showAlert, "アラートが表示されるべき")
    }

    // PT-QI-005: VLD-102: 2段入力で総額 < 自己支出はエラー
    func test_logExpense_iouMode_totalLessThanMyExpense_showsAlert() {
        // Arrange: 総額 2000 < 自己支出 5000
        viewModel.inputMode = .expense
        viewModel.isIOUMode = true
        viewModel.iouExpression = "2000"
        viewModel.myExpenseExpression = "5000"

        // Act
        let result = viewModel.logExpense()

        // Assert
        XCTAssertFalse(result, "総額 < 自己支出の場合は false を返すべき")
        XCTAssertTrue(viewModel.showAlert, "アラートが表示されるべき")
    }

    // PT-QI-006: 自己支出 "0+0" は "0" ≠ "0" なのでエラーにならず、IOUのみ保存
    func test_logExpense_iouMode_myExpenseZeroPlusZero_savesIOUOnly() throws {
        // Arrange: "0+0" は計算結果0だが、式 "0+0" は "0" と等しくないのでバリデーション通過
        viewModel.inputMode = .expense
        viewModel.isIOUMode = true
        viewModel.iouExpression = "5000"
        viewModel.myExpenseExpression = "0+0"  // "0"とは異なる式

        // Act
        let result = viewModel.logExpense()

        // Assert: myExpenseAmount = 0 なので IOU(5000)のみ保存
        XCTAssertTrue(result, "\"0+0\" の入力ではバリデーションを通過して true を返すべき")

        let iouDescriptor = FetchDescriptor<IOURecord>()
        let ious = try context.fetch(iouDescriptor)
        XCTAssertEqual(ious.count, 1, "IOU分（5000）が1件保存されるべき")
        XCTAssertEqual(ious.first?.amount, 5_000)
    }

    // PT-QI-007: 臨時収入の保存
    func test_logExpense_incomeMode_savesIncome() throws {
        // Arrange
        viewModel.expressionText = "30000"
        viewModel.inputMode = .income
        viewModel.isIOUMode = false

        // Act
        let result = viewModel.logExpense()

        // Assert
        XCTAssertTrue(result, "臨時収入入力では true を返すべき")

        let txDescriptor = FetchDescriptor<ExpenseTransaction>(predicate: #Predicate { $0.isIncome == true })
        let incomeTxs = try context.fetch(txDescriptor)
        XCTAssertEqual(incomeTxs.count, 1, "臨時収入トランザクションが1件保存されるべき")
        XCTAssertEqual(incomeTxs.first?.amount, 30_000)
    }
}
