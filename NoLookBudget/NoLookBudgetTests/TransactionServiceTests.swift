import XCTest
import SwiftData
@testable import NoLookBudget

@MainActor
final class TransactionServiceTests: XCTestCase {
    
    var container: ModelContainer!
    var context: ModelContext!
    var service: TransactionServiceProtocol!
    
    override func setUpWithError() throws {
        // インメモリコンテナの作成
        container = SharedModelContainer.createInMemoryContainer()
        context = container.mainContext
        service = TransactionService(context: context)
        
        // テスト用の初期データ投入
        let budget = Budget(month: Date(), totalAmount: 150000, spentAmount: 0)
        context.insert(budget)
        
        let category = ItemCategory(name: "食費", totalAmount: 50000, spentAmount: 0, orderIndex: 0)
        context.insert(category)
        
        try context.save()
    }

    override func tearDownWithError() throws {
        // コンテナの参照を外す前に、未保存の変更があれば破棄するよう明確化
        context?.rollback()
        // `service = nil` など明示的な解放はARCに任せることで、SwiftData + MainActorのライフサイクルクラッシュを回避
    }

    func test_addTransaction_reducesBudgetBalance() throws {
        // Arrange
        let descriptor = FetchDescriptor<ItemCategory>()
        let category = try context.fetch(descriptor).first!
        let initialSpent = category.spentAmount
        
        // Act
        try service.addExpense(amount: 5000, category: category, isIOU: false)
        
        // Assert
        XCTAssertEqual(category.spentAmount, initialSpent + 5000, "通常支出時はカテゴリの使用額（spentAmount）が増加（実質残高が減少）するべき")
        
        let txDescriptor = FetchDescriptor<ExpenseTransaction>()
        let transactions = try context.fetch(txDescriptor)
        XCTAssertEqual(transactions.count, 1)
        XCTAssertEqual(transactions.first!.amount, 5000)
    }
    
    func test_iouTransaction_doesNotAffectMainBudget() throws {
        // Arrange
        let descriptor = FetchDescriptor<ItemCategory>()
        let category = try context.fetch(descriptor).first!
        let initialSpent = category.spentAmount
        
        // Act
        try service.addExpense(amount: 10000, category: category, isIOU: true)
        
        // Assert
        XCTAssertEqual(category.spentAmount, initialSpent, "立替時はカテゴリの使用額に影響しないべき")
        
        let iouDescriptor = FetchDescriptor<IOURecord>()
        let ious = try context.fetch(iouDescriptor)
        XCTAssertEqual(ious.count, 1)
        XCTAssertEqual(ious.first!.amount, 10000)
    }

    func test_carryOverDebt_deductsFromNextMonthBudget() throws {
        // Arrange
        let budgetDescriptor = FetchDescriptor<Budget>()
        let budget = try context.fetch(budgetDescriptor).first!
        
        // 予算を1万円オーバーさせる
        budget.spentAmount = budget.totalAmount + 10000
        try context.save()
        
        // Act
        try service.processMonthlyReview(currentDate: Date())
        
        // Assert
        let allBudgets = try context.fetch(budgetDescriptor)
        XCTAssertEqual(allBudgets.count, 2, "次月の予算が新規作成されるべき")
        
        let nextMonthBudget = allBudgets.sorted(by: { $0.month > $1.month }).first!
        XCTAssertEqual(nextMonthBudget.spentAmount, 10000, "前月のオーバー分（10000円）が初期使用額として繰り越されているべき")
    }
}
