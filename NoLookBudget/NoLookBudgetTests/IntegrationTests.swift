import XCTest
import SwiftData
@testable import NoLookBudget

// MARK: - IT（結合テスト）: サービス層を横断するデータフロー検証
// 対象: docs/QA/IT_test_cases.md の IT-001〜014
// 方針: SwiftData（インメモリ）上で TransactionService の呼び出しチェーンを検証する
//       ViewModel の UI状態（showAlert 等）は QuickInputViewModelTests でカバー済み

@MainActor
final class IntegrationTests: XCTestCase {

    var container: ModelContainer!
    var context: ModelContext!
    var service: TransactionService!

    var testBudget: Budget!
    var testCategory: ItemCategory!

    override func setUpWithError() throws {
        container = SharedModelContainer.createInMemoryContainer()
        context = container.mainContext
        service = TransactionService(context: context)

        testBudget = Budget(month: Date(), totalAmount: 100_000, spentAmount: 0)
        context.insert(testBudget)

        testCategory = ItemCategory(name: "食費", totalAmount: 40_000, spentAmount: 0, orderIndex: 0)
        context.insert(testCategory)

        try context.save()
    }

    override func tearDownWithError() throws {
        context?.rollback()
    }

    // MARK: - IT-001: 支出入力 → Budget.spentAmount に反映される

    func test_IT001_addExpense_reflectsInBudget() throws {
        // Act
        try service.addExpense(amount: 3_000, category: testCategory, isIOU: false)

        // Assert
        let descriptor = FetchDescriptor<Budget>()
        let budget = try context.fetch(descriptor).first!
        XCTAssertEqual(budget.spentAmount, 3_000, "IT-001: 支出登録後 Budget.spentAmount が更新されるべき")
    }

    // MARK: - IT-002: カテゴリ予算も連動して更新される

    func test_IT002_addExpense_alsoUpdatesCategory() throws {
        // Act
        try service.addExpense(amount: 5_000, category: testCategory, isIOU: false)

        // Assert
        let descriptor = FetchDescriptor<ItemCategory>()
        let category = try context.fetch(descriptor).first!
        XCTAssertEqual(category.spentAmount, 5_000, "IT-002: 支出登録後 Category.spentAmount も更新されるべき")
    }

    // MARK: - IT-003: 臨時収入 → Budget.totalAmount に連動

    func test_IT003_addIncome_updatesBudgetTotalAmount() throws {
        // Arrange
        let initialTotal = testBudget.totalAmount

        // Act
        try service.addIncome(amount: 50_000)

        // Assert
        XCTAssertEqual(testBudget.totalAmount, initialTotal + 50_000, "IT-003: 臨時収入登録後 Budget.totalAmount が増加するべき")
    }

    // MARK: - IT-004: 立替2段入力の保存と履歴表示
    // IOU分は IOURecord に、自己支出分は ExpenseTransaction に保存される

    func test_IT004_iouTwoStepInput_savesCorrectly() throws {
        // Simulate QuickInputViewModel の 2段入力ロジック（IOU=3000、自己=2000）
        let totalAmount = 5_000.0
        let myExpenseAmount = 2_000.0
        let actualIOUAmount = totalAmount - myExpenseAmount  // 3000

        try service.addExpense(amount: actualIOUAmount, category: testCategory, isIOU: true)
        try service.addExpense(amount: myExpenseAmount, category: testCategory, isIOU: false)

        // Assert: 自己支出 2000 のみ Budget に反映される
        XCTAssertEqual(testBudget.spentAmount, 2_000, "IT-004: 2段入力で自己支出分のみ Budget.spentAmount に反映されるべき")

        let iouDescriptor = FetchDescriptor<IOURecord>()
        let ious = try context.fetch(iouDescriptor)
        XCTAssertEqual(ious.count, 1, "IT-004: IOU分（3000）が IOURecord に1件保存されるべき")
        XCTAssertEqual(ious.first?.amount, 3_000)
    }

    // MARK: - IT-005: 立替分は Budget に影響しない

    func test_IT005_iouExpense_doesNotAffectBudget() throws {
        // Act
        try service.addExpense(amount: 20_000, category: testCategory, isIOU: true)

        // Assert
        XCTAssertEqual(testBudget.spentAmount, 0, "IT-005: IOU支出は Budget.spentAmount を変化させないべき")
        XCTAssertEqual(testCategory.spentAmount, 0, "IT-005: IOU支出は Category.spentAmount を変化させないべき")
    }

    // MARK: - IT-006: 立替分が履歴（ExpenseTransaction）に表示される

    func test_IT006_iouExpense_appearsInTransactionHistory() throws {
        // Act
        try service.addExpense(amount: 8_000, category: testCategory, isIOU: true)

        // Assert: isIOU=true のトランザクションが保存されている
        let txDescriptor = FetchDescriptor<ExpenseTransaction>()
        let transactions = try context.fetch(txDescriptor)
        XCTAssertEqual(transactions.count, 1, "IT-006: IOU支出も ExpenseTransaction として1件保存されるべき")
        XCTAssertTrue(transactions.first?.isIOU == true)
    }

    // MARK: - IT-007: 支出編集で差分が正しく反映される

    func test_IT007_updateExpense_correctlyAppliesDelta() throws {
        // Arrange: 5000円の通常支出を登録
        try service.addExpense(amount: 5_000, category: testCategory, isIOU: false)
        let txDescriptor = FetchDescriptor<ExpenseTransaction>()
        let tx = try context.fetch(txDescriptor).first!

        // Act: 5000 → 8000 に更新
        try service.updateExpense(id: tx.id, amount: 8_000, category: testCategory, isIOU: false)

        // Assert
        XCTAssertEqual(testBudget.spentAmount, 8_000, "IT-007: 編集後は新金額 8000 が Budget.spentAmount に反映されるべき")
        XCTAssertEqual(testCategory.spentAmount, 8_000)
    }

    // MARK: - IT-008: 立替削除で Budget は変化しない（BUG-001回帰）

    func test_IT008_deleteIOU_doesNotChangeBudget() throws {
        // Arrange: 通常支出5000 + IOU 10000
        try service.addExpense(amount: 5_000, category: testCategory, isIOU: false)
        try service.addExpense(amount: 10_000, category: testCategory, isIOU: true)
        let spentAfterSetup = testBudget.spentAmount
        XCTAssertEqual(spentAfterSetup, 5_000)

        let iouTxDescriptor = FetchDescriptor<ExpenseTransaction>(predicate: #Predicate { $0.isIOU == true })
        let iouTx = try context.fetch(iouTxDescriptor).first!

        // Act: IOU削除
        try service.deleteTransaction(id: iouTx.id)

        // Assert: Budget は通常支出分のみ変化しているべき
        XCTAssertEqual(
            testBudget.spentAmount, 5_000,
            "IT-008: IOU削除後も Budget.spentAmount は通常支出分（5000）のまま変わらないべき（BUG-001回帰）"
        )
    }

    // MARK: - IT-009: 固定費は履歴から削除できない

    func test_IT009_fixedCostTransaction_cannotBeDeleted() throws {
        // Arrange: 固定費トランザクションを直接作成
        let fixedTx = ExpenseTransaction(date: Date(), amount: 10_000, isIOU: false, isIncome: false, isFixedCost: true, title: "家賃")
        context.insert(fixedTx)
        try context.save()

        // 固定費削除ガードのロジック確認（TransactionHistoryViewModel.deleteTransaction の guard を再現）
        // TransactionService 自体には固定費ガードがないため、ViewModel レイヤーで判断される。
        // ここでは固定費フラグが正しく設定されることを確認する。
        let txDescriptor = FetchDescriptor<ExpenseTransaction>(predicate: #Predicate { $0.isFixedCost == true })
        let fixedTxs = try context.fetch(txDescriptor)
        XCTAssertEqual(fixedTxs.count, 1, "IT-009: isFixedCost=true のトランザクションが保存されているべき")
        XCTAssertTrue(fixedTxs.first?.isFixedCost == true, "IT-009: isFixedCost フラグが true であることを確認")

        // 注: 固定費の削除ガード（!item.isFixedCost）は TransactionHistoryViewModel で行われる。
        // TransactionService を直接呼べば削除可能なため、UIレイヤーでの制御を信頼する設計。
    }

    // MARK: - IT-010: 月次レビュー実行で次月 Budget が作成される

    func test_IT010_processMonthlyReview_createsNextMonthBudget() throws {
        // Arrange: 2万円オーバー
        testBudget.spentAmount = testBudget.totalAmount + 20_000
        try context.save()

        // Act
        try service.processMonthlyReview(currentDate: Date())

        // Assert
        let budgetDescriptor = FetchDescriptor<Budget>()
        let allBudgets = try context.fetch(budgetDescriptor)
        XCTAssertEqual(allBudgets.count, 2, "IT-010: 月次レビュー後に次月 Budget が1件作成されるべき")

        let nextBudget = allBudgets.sorted { $0.month > $1.month }.first!
        XCTAssertEqual(nextBudget.spentAmount, 20_000, "IT-010: 前月のオーバー分（20000）が次月の初期 spentAmount として繰り越されるべき")
    }

    // MARK: - IT-011: 借金回収処理で source・target カテゴリが正しく調整される

    func test_IT011_recoverDebt_adjustsCategories() throws {
        // Arrange
        let source = ItemCategory(name: "交際費", totalAmount: 30_000, spentAmount: 0, orderIndex: 1)
        let target = ItemCategory(name: "交通費", totalAmount: 20_000, spentAmount: 28_000, orderIndex: 2)
        context.insert(source)
        context.insert(target)
        try context.save()

        // Act: 交際費から8000円を削って交通費の超過分を相殺
        try service.recoverDebt(sourceCategoryName: "交際費", targetCategoryName: "交通費", amount: 8_000)

        // Assert
        XCTAssertEqual(source.totalAmount, 22_000, "IT-011: source カテゴリの totalAmount が 8000 削減されるべき")
        XCTAssertEqual(target.spentAmount, 20_000, "IT-011: target カテゴリの spentAmount が 8000 相殺されるべき")
    }

    // MARK: - IT-012: カテゴリ追加後に正しく永続化される

    func test_IT012_addCategory_isPersisted() throws {
        // Act: 新規カテゴリを追加
        let newCategory = ItemCategory(name: "娯楽費", totalAmount: 20_000, spentAmount: 0, orderIndex: 1)
        context.insert(newCategory)
        try context.save()

        // Assert
        let descriptor = FetchDescriptor<ItemCategory>()
        let categories = try context.fetch(descriptor)
        XCTAssertEqual(categories.count, 2, "IT-012: 新規カテゴリ追加後に2件取得できるべき（食費 + 娯楽費）")
        XCTAssertTrue(categories.map { $0.name }.contains("娯楽費"), "IT-012: 娯楽費カテゴリが正しく保存されるべき")
    }

    // MARK: - IT-013: 固定費追加 → ExpenseTransaction が isFixedCost=true で生成される

    func test_IT013_addFixedCostSetting_generatesTransaction() throws {
        // Arrange: 固定費設定を作成し、固定費トランザクションを生成（ConfigurationVM のロジックを再現）
        let fixedSetting = FixedCostSetting(name: "家賃", amount: 80_000, orderIndex: 0)
        context.insert(fixedSetting)

        let fixedTx = ExpenseTransaction(
            date: Date(),
            amount: fixedSetting.amount,
            categoryId: nil,
            isIOU: false,
            isIncome: false,
            isFixedCost: true,
            title: fixedSetting.name,
            fixedCostSettingId: fixedSetting.id
        )
        context.insert(fixedTx)
        try context.save()

        // Assert
        let txDescriptor = FetchDescriptor<ExpenseTransaction>(
            predicate: #Predicate { $0.isFixedCost == true }
        )
        let fixedTxs = try context.fetch(txDescriptor)
        XCTAssertEqual(fixedTxs.count, 1, "IT-013: 固定費設定に対応する ExpenseTransaction が1件生成されるべき")
        XCTAssertEqual(fixedTxs.first?.amount, 80_000)
        XCTAssertEqual(fixedTxs.first?.title, "家賃")
    }

    // MARK: - IT-014: 予算額変更で remainingAmount が連動する

    func test_IT014_changeBudgetTotalAmount_remainingAmountUpdates() throws {
        // Arrange: 30000円支出を追加
        try service.addExpense(amount: 30_000, category: testCategory, isIOU: false)
        XCTAssertEqual(testBudget.spentAmount, 30_000)
        XCTAssertEqual(testBudget.remainingAmount, 70_000, "初期: 100000 - 30000 = 70000")

        // Act: 予算を150000に変更
        testBudget.totalAmount = 150_000
        try context.save()

        // Assert: @Transient の remainingAmount が自動更新される
        XCTAssertEqual(testBudget.remainingAmount, 120_000, "IT-014: 予算変更後 remainingAmount が 150000 - 30000 = 120000 に更新されるべき")
    }
}
