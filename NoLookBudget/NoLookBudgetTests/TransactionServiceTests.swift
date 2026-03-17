import XCTest
import SwiftData
@testable import NoLookBudget

// MARK: - PT（プログラムテスト）: TransactionService
// 対象: docs/QA/PT_test_cases.md の PT-TS-001〜007 および追加カバレッジ

@MainActor
final class TransactionServiceTests: XCTestCase {

    var container: ModelContainer!
    var context: ModelContext!
    var service: TransactionServiceProtocol!

    // テスト用の初期データ
    var testBudget: Budget!
    var testCategory: ItemCategory!

    override func setUpWithError() throws {
        container = SharedModelContainer.createInMemoryContainer()
        context = container.mainContext
        service = TransactionService(context: context)

        testBudget = Budget(month: Date(), totalAmount: 150_000, spentAmount: 0)
        context.insert(testBudget)

        testCategory = ItemCategory(name: "食費", totalAmount: 50_000, spentAmount: 0, orderIndex: 0)
        context.insert(testCategory)

        try context.save()
    }

    override func tearDownWithError() throws {
        context?.rollback()
    }

    // MARK: - PT-TS-001: 通常支出追加で Budget.spentAmount が増加する

    func test_addNormalExpense_increasesBudgetSpentAmount() throws {
        // Act
        try service.addExpense(amount: 5_000, category: testCategory, isIOU: false)

        // Assert
        XCTAssertEqual(testBudget.spentAmount, 5_000, "通常支出追加で Budget.spentAmount が 5000 増加するべき")
    }

    // MARK: - PT-TS-002: 立替追加で Budget.spentAmount は変化しない

    func test_addIOUExpense_doesNotAffectBudgetSpentAmount() throws {
        // Arrange
        let initialSpent = testBudget.spentAmount

        // Act
        try service.addExpense(amount: 10_000, category: testCategory, isIOU: true)

        // Assert
        XCTAssertEqual(testBudget.spentAmount, initialSpent, "立替追加では Budget.spentAmount を変更しないべき")

        let iouDescriptor = FetchDescriptor<IOURecord>()
        let ious = try context.fetch(iouDescriptor)
        XCTAssertEqual(ious.count, 1, "立替追加で IOURecord が1件作成されるべき")
        XCTAssertEqual(ious.first?.amount, 10_000)
    }

    // MARK: - PT-TS-003: 通常支出追加で ItemCategory.spentAmount も増加する

    func test_addNormalExpense_alsoUpdatesCategorySpentAmount() throws {
        // Act
        try service.addExpense(amount: 3_000, category: testCategory, isIOU: false)

        // Assert
        XCTAssertEqual(testCategory.spentAmount, 3_000, "通常支出追加で Category.spentAmount が 3000 増加するべき")
    }

    // MARK: - PT-TS-004（通常）: 通常支出削除で Budget・Category が復元される

    func test_deleteNormalExpense_restoresBudgetAndCategory() throws {
        // Arrange: 5000円の通常支出を追加
        try service.addExpense(amount: 5_000, category: testCategory, isIOU: false)
        XCTAssertEqual(testBudget.spentAmount, 5_000)
        XCTAssertEqual(testCategory.spentAmount, 5_000)

        let txDescriptor = FetchDescriptor<ExpenseTransaction>()
        let transactions = try context.fetch(txDescriptor)
        let transactionId = transactions.first!.id

        // Act: 削除
        try service.deleteTransaction(id: transactionId)

        // Assert
        XCTAssertEqual(testBudget.spentAmount, 0, "通常支出削除で Budget.spentAmount が元に戻るべき")
        XCTAssertEqual(testCategory.spentAmount, 0, "通常支出削除で Category.spentAmount が元に戻るべき")

        let remaining = try context.fetch(txDescriptor)
        XCTAssertTrue(remaining.isEmpty, "削除後は ExpenseTransaction が0件になるべき")
    }

    // MARK: - PT-TS-004（IOU/BUG-001回帰）: IOU削除で Budget.spentAmount は変化しない

    func test_deleteIOUTransaction_doesNotAffectBudgetSpentAmount() throws {
        // Arrange: 通常支出を5000追加してからIOU10000を追加
        try service.addExpense(amount: 5_000, category: testCategory, isIOU: false)
        try service.addExpense(amount: 10_000, category: testCategory, isIOU: true)
        let spentAfterAdd = testBudget.spentAmount
        XCTAssertEqual(spentAfterAdd, 5_000, "IOU追加後もBudget.spentAmountは通常支出分のみであるべき")

        let txDescriptor = FetchDescriptor<ExpenseTransaction>(
            predicate: #Predicate { $0.isIOU == true }
        )
        let iouTransactions = try context.fetch(txDescriptor)
        guard let iouTx = iouTransactions.first else {
            XCTFail("IOU ExpenseTransactionが存在しない")
            return
        }

        // Act: IOU削除
        try service.deleteTransaction(id: iouTx.id)

        // Assert: Budget.spentAmount は変化しない（BUG-001が修正済みであることを確認）
        XCTAssertEqual(
            testBudget.spentAmount, 5_000,
            "IOU削除後も Budget.spentAmount は通常支出分（5000円）のまま変わらないべき（BUG-001回帰テスト）"
        )
    }

    // MARK: - PT-TS-005: 月跨ぎ借金繰越

    func test_carryOverDebt_deductsFromNextMonthBudget() throws {
        // Arrange: 1万円オーバー
        testBudget.spentAmount = testBudget.totalAmount + 10_000
        try context.save()

        // Act
        try service.processMonthlyReview(currentDate: Date())

        // Assert
        let budgetDescriptor = FetchDescriptor<Budget>()
        let allBudgets = try context.fetch(budgetDescriptor)
        XCTAssertEqual(allBudgets.count, 2, "次月の予算レコードが新規作成されるべき")

        let nextMonthBudget = allBudgets.sorted { $0.month > $1.month }.first!
        XCTAssertEqual(nextMonthBudget.spentAmount, 10_000, "前月のオーバー分（10000円）が次月の初期spentAmountとして繰り越されるべき")
    }

    // MARK: - PT-TS-006: 臨時収入追加で Budget.totalAmount が増加する

    func test_addIncome_increasesBudgetTotalAmount() throws {
        // Arrange
        let initialTotal = testBudget.totalAmount

        // Act
        try service.addIncome(amount: 20_000)

        // Assert
        XCTAssertEqual(testBudget.totalAmount, initialTotal + 20_000, "臨時収入追加で Budget.totalAmount が 20000 増加するべき")

        let txDescriptor = FetchDescriptor<ExpenseTransaction>(
            predicate: #Predicate { $0.isIncome == true }
        )
        let incomeTxs = try context.fetch(txDescriptor)
        XCTAssertEqual(incomeTxs.count, 1, "臨時収入追加で isIncome=true の ExpenseTransaction が1件作成されるべき")
    }

    // MARK: - 臨時収入削除で Budget.totalAmount が復元される

    func test_deleteIncome_decreasesBudgetTotalAmount() throws {
        // Arrange
        let initialTotal = testBudget.totalAmount
        try service.addIncome(amount: 20_000)
        XCTAssertEqual(testBudget.totalAmount, initialTotal + 20_000)

        let txDescriptor = FetchDescriptor<ExpenseTransaction>(predicate: #Predicate { $0.isIncome == true })
        let incomeTx = try context.fetch(txDescriptor).first!

        // Act
        try service.deleteTransaction(id: incomeTx.id)

        // Assert
        XCTAssertEqual(testBudget.totalAmount, initialTotal, "臨時収入削除で Budget.totalAmount が元の値に戻るべき")
    }

    // MARK: - PT-TS-007a: 通常支出の更新（通常→通常）で差分が正しく反映される

    func test_updateExpense_normalToNormal_correctlyAppliesDelta() throws {
        // Arrange: 5000円の支出を登録
        try service.addExpense(amount: 5_000, category: testCategory, isIOU: false)
        XCTAssertEqual(testBudget.spentAmount, 5_000)

        let txDescriptor = FetchDescriptor<ExpenseTransaction>()
        let tx = try context.fetch(txDescriptor).first!

        // Act: 5000→8000に更新
        try service.updateExpense(id: tx.id, amount: 8_000, category: testCategory, isIOU: false)

        // Assert: 差分（+3000）だけ反映される
        XCTAssertEqual(testBudget.spentAmount, 8_000, "更新後は新金額 8000 が Budget.spentAmount に反映されるべき")
        XCTAssertEqual(testCategory.spentAmount, 8_000, "更新後は新金額 8000 が Category.spentAmount に反映されるべき")
    }

    // MARK: - PT-TS-007b: IOU→通常支出に更新（BUG-002回帰）

    func test_updateExpense_iouToNormal_correctlyUpdatesBudget() throws {
        // Arrange: IOU 10000円を登録
        try service.addExpense(amount: 10_000, category: testCategory, isIOU: true)
        let spentBeforeUpdate = testBudget.spentAmount
        XCTAssertEqual(spentBeforeUpdate, 0, "IOU登録後は Budget.spentAmount が 0 のままであるべき")

        let txDescriptor = FetchDescriptor<ExpenseTransaction>(predicate: #Predicate { $0.isIOU == true })
        let iouTx = try context.fetch(txDescriptor).first!

        // Act: IOU → 通常支出 (7000円)に変更
        try service.updateExpense(id: iouTx.id, amount: 7_000, category: testCategory, isIOU: false)

        // Assert: 通常支出として 7000 が加算される（BUG-002が修正済みであることを確認）
        XCTAssertEqual(
            testBudget.spentAmount, 7_000,
            "IOU→通常支出への変更後、Budget.spentAmount は新金額 7000 になるべき（BUG-002回帰テスト）"
        )
        XCTAssertEqual(testCategory.spentAmount, 7_000)
    }

    // MARK: - PT-TS-007c: 通常支出→IOUに更新（BUG-002回帰）

    func test_updateExpense_normalToIOU_correctlyUpdatesBudget() throws {
        // Arrange: 通常支出 5000円を登録
        try service.addExpense(amount: 5_000, category: testCategory, isIOU: false)
        XCTAssertEqual(testBudget.spentAmount, 5_000)

        let txDescriptor = FetchDescriptor<ExpenseTransaction>(predicate: #Predicate { $0.isIOU == false && $0.isIncome == false })
        let normalTx = try context.fetch(txDescriptor).first!

        // Act: 通常支出 → IOU (8000円)に変更
        try service.updateExpense(id: normalTx.id, amount: 8_000, category: testCategory, isIOU: true)

        // Assert: 通常支出分（5000）が取り消されて Budget.spentAmount が 0 に戻るべき（BUG-002回帰）
        XCTAssertEqual(
            testBudget.spentAmount, 0,
            "通常支出→IOU変更後、Budget.spentAmount は 0 に戻るべき（BUG-002回帰テスト）"
        )
        XCTAssertEqual(testCategory.spentAmount, 0)
    }

    // MARK: - 臨時収入の更新で差分が正しく反映される

    func test_updateIncome_correctlyAppliesDeltaToBudget() throws {
        // Arrange
        let initialTotal = testBudget.totalAmount
        try service.addIncome(amount: 20_000)
        XCTAssertEqual(testBudget.totalAmount, initialTotal + 20_000)

        let txDescriptor = FetchDescriptor<ExpenseTransaction>(predicate: #Predicate { $0.isIncome == true })
        let incomeTx = try context.fetch(txDescriptor).first!

        // Act: 20000→30000に更新
        try service.updateIncome(id: incomeTx.id, amount: 30_000)

        // Assert
        XCTAssertEqual(testBudget.totalAmount, initialTotal + 30_000, "臨時収入更新後は新金額 30000 が totalAmount に反映されるべき")
    }

    // MARK: - recoverDebt で source/target カテゴリが正しく調整される

    func test_recoverDebt_adjustsSourceAndTargetCategories() throws {
        // Arrange: 2カテゴリを用意
        let sourceCategory = ItemCategory(name: "外食費", totalAmount: 30_000, spentAmount: 0, orderIndex: 1)
        let targetCategory = ItemCategory(name: "交通費", totalAmount: 20_000, spentAmount: 25_000, orderIndex: 2) // 5000オーバー
        context.insert(sourceCategory)
        context.insert(targetCategory)
        try context.save()

        // Act: 外食費の予算を5000削って、交通費の超過分を相殺
        try service.recoverDebt(sourceCategoryName: "外食費", targetCategoryName: "交通費", amount: 5_000)

        // Assert
        XCTAssertEqual(sourceCategory.totalAmount, 25_000, "sourceCategory の totalAmount が 5000 減額されるべき")
        XCTAssertEqual(targetCategory.spentAmount, 20_000, "targetCategory の spentAmount が 5000 相殺されるべき")
    }

    // MARK: - 金額 0 の支出は保存されない

    func test_addExpense_withZeroAmount_doesNotSave() throws {
        // Act
        try service.addExpense(amount: 0, category: testCategory, isIOU: false)

        // Assert
        let txDescriptor = FetchDescriptor<ExpenseTransaction>()
        let transactions = try context.fetch(txDescriptor)
        XCTAssertTrue(transactions.isEmpty, "金額 0 の支出は保存されないべき")
        XCTAssertEqual(testBudget.spentAmount, 0)
    }

    // MARK: - 複数支出の合算が正しく Budget に反映される

    func test_multipleExpenses_accumulateBudgetSpentAmount() throws {
        // Act
        try service.addExpense(amount: 1_000, category: testCategory, isIOU: false)
        try service.addExpense(amount: 2_000, category: testCategory, isIOU: false)
        try service.addExpense(amount: 3_000, category: testCategory, isIOU: false)

        // Assert
        XCTAssertEqual(testBudget.spentAmount, 6_000, "3件の支出合計 6000 が Budget.spentAmount に反映されるべき")
        XCTAssertEqual(testCategory.spentAmount, 6_000)
    }
}
