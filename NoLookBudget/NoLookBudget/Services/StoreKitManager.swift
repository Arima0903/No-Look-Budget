import Foundation
import StoreKit
import Combine
import WidgetKit

/// StoreKit2 を使用したサブスクリプション課金管理サービス
/// シングルトンとして利用し、アプリ全体でプレミアム状態を共有する
@MainActor
class StoreKitManager: ObservableObject {

    // MARK: - シングルトン

    static let shared = StoreKitManager()

    // MARK: - 商品ID

    private let productID = "com.arima0903.NoLookBudget.commander_monthly"

    // MARK: - Published プロパティ

    /// プレミアム状態（サブスクリプション有効かどうか）
    @Published var isPremium: Bool = false {
        didSet {
            // AppStorage / ウィジェットとの同期
            UserDefaults.standard.set(isPremium, forKey: "isPremiumEnabled")
            WidgetCenter.shared.reloadAllTimelines()
        }
    }

    /// 利用可能な商品一覧
    @Published var products: [Product] = []

    /// エラーメッセージ（購入失敗時など）
    @Published var purchaseError: String? = nil

    // MARK: - Private プロパティ

    /// トランザクション更新の監視タスク
    private var updateListenerTask: Task<Void, Never>? = nil

    // MARK: - 初期化

    private init() {
        // トランザクション監視を開始
        updateListenerTask = listenForTransactions()

        // 起動時に購入状態を復元
        Task {
            await checkPremiumStatus()
            await loadProducts()
        }
    }

    deinit {
        updateListenerTask?.cancel()
    }

    // MARK: - 公開メソッド

    /// App Store から商品情報を取得する
    func loadProducts() async {
        do {
            let storeProducts = try await Product.products(for: [productID])
            products = storeProducts
        } catch {
            purchaseError = "商品情報の取得に失敗しました: \(error.localizedDescription)"
        }
    }

    /// サブスクリプションを購入する
    func purchase() async {
        purchaseError = nil

        guard let product = products.first else {
            purchaseError = "購入可能な商品が見つかりません。"
            return
        }

        do {
            let result = try await product.purchase()

            switch result {
            case .success(let verification):
                let transaction = try checkVerified(verification)
                await handleTransaction(transaction)

            case .userCancelled:
                // ユーザーが購入をキャンセルした場合は何もしない
                break

            case .pending:
                // 保護者の承認待ちなど
                purchaseError = "購入が保留中です。承認後に反映されます。"

            @unknown default:
                purchaseError = "予期しない購入結果が返されました。"
            }
        } catch {
            purchaseError = "購入処理に失敗しました: \(error.localizedDescription)"
        }
    }

    /// 購入を復元する（別デバイスやアプリ再インストール時）
    func restorePurchases() async {
        purchaseError = nil
        await checkPremiumStatus()

        if !isPremium {
            purchaseError = "復元可能な購入が見つかりませんでした。"
        }
    }

    // MARK: - Private メソッド

    /// トランザクション更新を継続的に監視する
    /// サブスクリプションの期限切れや更新を検知する
    private func listenForTransactions() -> Task<Void, Never> {
        Task.detached { [weak self] in
            for await result in Transaction.updates {
                do {
                    let transaction = try self?.checkVerified(result)
                    if let transaction = transaction {
                        await self?.handleTransaction(transaction)
                    }
                } catch {
                    // 検証に失敗したトランザクションは無視する
                }
            }
        }
    }

    /// 現在の購入状態（entitlements）を確認する
    private func checkPremiumStatus() async {
        var hasPremium = false

        for await result in Transaction.currentEntitlements {
            do {
                let transaction = try checkVerified(result)

                // 有効なサブスクリプションかどうかを確認
                if transaction.productID == productID {
                    // 失効していないことを確認
                    if transaction.revocationDate == nil {
                        hasPremium = true
                    }
                }
            } catch {
                // 検証に失敗したトランザクションは無視
            }
        }

        isPremium = hasPremium
    }

    /// トランザクションを処理し、購入状態を更新する
    private func handleTransaction(_ transaction: Transaction) async {
        if transaction.productID == productID {
            // 失効チェック
            if transaction.revocationDate == nil {
                isPremium = true
            } else {
                isPremium = false
            }
        }

        // トランザクションを完了としてマークする
        await transaction.finish()
    }

    /// トランザクションの検証を行う
    /// - Parameter result: 検証結果
    /// - Returns: 検証済みトランザクション
    /// - Throws: 検証に失敗した場合
    nonisolated private func checkVerified<T>(_ result: VerificationResult<T>) throws -> T {
        switch result {
        case .unverified(_, let error):
            throw error
        case .verified(let safe):
            return safe
        }
    }
}
