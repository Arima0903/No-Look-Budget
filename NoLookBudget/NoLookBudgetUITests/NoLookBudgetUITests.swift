import XCTest

// ─────────────────────────────────────────────────────────────
// MARK: - No-Look-Budget UIテスト（統合テスト自動化）
// オンボーディングから実際の操作までを自動で検証し、
// 各ステップでスクリーンショットを保存する
// ─────────────────────────────────────────────────────────────

final class NoLookBudgetUITests: XCTestCase {

    var app: XCUIApplication!

    /// スクリーンショット保存先ディレクトリ
    static let screenshotDir: String = {
        let dir = NSTemporaryDirectory() + "NoLookBudgetUITestScreenshots/"
        try? FileManager.default.createDirectory(
            atPath: dir,
            withIntermediateDirectories: true
        )
        return dir
    }()

    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
    }

    /// アプリを初回起動状態（オンボーディング未完了）で起動
    func launchWithReset() {
        app.launchEnvironment["UI_TEST_RESET"] = "1"
        app.launch()
    }

    override func tearDownWithError() throws {
        app = nil
    }

    // MARK: - ヘルパー

    /// スクリーンショットを撮影してテスト結果に添付 + ファイル保存
    func takeScreenshot(name: String) {
        let screenshot = app.windows.firstMatch.screenshot()
        let attachment = XCTAttachment(screenshot: screenshot)
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)

        // ファイルにも保存
        let filePath = Self.screenshotDir + "\(name).png"
        try? screenshot.pngRepresentation.write(
            to: URL(fileURLWithPath: filePath)
        )
    }

    /// オンボーディング済みの状態でアプリを起動
    func launchWithOnboardingComplete() {
        app.launchArguments = [
            "-agreedTermsVersion", "1.0.0",
            "-hasCompletedTutorial", "1"
        ]
        app.launch()
    }

    /// ダッシュボード表示を待機
    @discardableResult
    func waitForDashboard() -> XCUIElement {
        let dashboard = app.otherElements["dashboardView"]
        XCTAssertTrue(dashboard.waitForExistence(timeout: 10), "ダッシュボードが表示されるべき")
        return dashboard
    }

    /// 入力モーダルを開く
    func openQuickInput() {
        let addButton = app.buttons["addExpenseButton"]
        XCTAssertTrue(addButton.waitForExistence(timeout: 5), "記録ボタンが存在するべき")
        addButton.tap()
        // モーダルが表示されるまで待機（closeModalButtonの存在で確認）
        let closeBtn = app.buttons["closeModalButton"]
        XCTAssertTrue(closeBtn.waitForExistence(timeout: 5), "入力モーダルが表示されるべき")
    }

    /// テンキーのボタンをラベルで押す（ボタンのlabelベースで検索）
    func tapKeypad(_ key: String) {
        // 特定の識別子があるキーはそれを使う
        let identifier = key == "=" ? "commitButton" : "keypad_\(key)"
        let button = app.buttons[identifier]
        if button.exists {
            button.tap()
            return
        }
        // フォールバック: ラベルで検索
        let byLabel = app.buttons.matching(NSPredicate(format: "label == %@", key))
        XCTAssertTrue(byLabel.count > 0, "キー '\(key)' が見つからない")
        byLabel.element(boundBy: 0).tap()
    }

    // MARK: - IT-UI-001: オンボーディング完全フロー

    func testOnboardingFullFlow() throws {
        launchWithReset()
        sleep(2)

        // ── ステップ1: 規約同意画面 ──
        // 「同意してはじめる」ボタンの存在で規約画面を確認
        let agreeButton = app.buttons["agreeButton"]
        XCTAssertTrue(agreeButton.waitForExistence(timeout: 10), "同意ボタンが表示されるべき")
        takeScreenshot(name: "IT-UI-001_01_規約同意画面")

        agreeButton.tap()
        sleep(3)

        // ── ステップ2: チュートリアル画面 ──
        // nextButton（識別子）またはラベルで検索
        var nextButton = app.buttons["nextButton"]
        if !nextButton.waitForExistence(timeout: 10) {
            // フォールバック: ラベルで検索
            nextButton = app.buttons.matching(
                NSPredicate(format: "label CONTAINS '次へ'")
            ).firstMatch
        }
        XCTAssertTrue(nextButton.waitForExistence(timeout: 5), "次へボタンが表示されるべき")
        takeScreenshot(name: "IT-UI-001_02_チュートリアル_ステップ1")

        nextButton.tap()
        sleep(1)
        takeScreenshot(name: "IT-UI-001_03_チュートリアル_ステップ2")

        nextButton.tap()
        sleep(1)
        takeScreenshot(name: "IT-UI-001_04_チュートリアル_ステップ3")

        nextButton.tap()
        sleep(1)
        takeScreenshot(name: "IT-UI-001_05_チュートリアル_ステップ4")

        // 最後の「はじめる！」をタップ
        nextButton.tap()
        sleep(1)

        // ── ステップ3: ダッシュボード表示 ──
        waitForDashboard()
        takeScreenshot(name: "IT-UI-001_06_ダッシュボード初期状態")
    }

    // MARK: - IT-UI-002: チュートリアルスキップ

    func testTutorialSkip() throws {
        launchWithReset()
        sleep(2)

        // 規約同意
        let agreeButton = app.buttons["agreeButton"]
        XCTAssertTrue(agreeButton.waitForExistence(timeout: 10), "同意ボタンが表示されるべき")
        agreeButton.tap()
        sleep(3)

        // スキップ（識別子またはラベルで検索）
        var skipButton = app.buttons["skipButton"]
        if !skipButton.waitForExistence(timeout: 10) {
            skipButton = app.buttons.matching(
                NSPredicate(format: "label CONTAINS 'スキップ'")
            ).firstMatch
        }
        XCTAssertTrue(skipButton.waitForExistence(timeout: 5), "スキップボタンが表示されるべき")
        skipButton.tap()
        sleep(1)

        // ダッシュボード表示
        waitForDashboard()
        takeScreenshot(name: "IT-UI-002_01_スキップ後ダッシュボード")
    }

    // MARK: - IT-UI-003: 支出入力フロー

    func testExpenseInputFlow() throws {
        launchWithOnboardingComplete()
        waitForDashboard()
        takeScreenshot(name: "IT-UI-003_01_ダッシュボード_入力前")

        // 入力モーダルを開く
        openQuickInput()
        takeScreenshot(name: "IT-UI-003_02_入力モーダル表示")

        // テンキーで「1500」を入力
        tapKeypad("1")
        tapKeypad("5")
        tapKeypad("0")
        tapKeypad("0")
        sleep(1)
        takeScreenshot(name: "IT-UI-003_03_金額入力済み_1500円")

        // カテゴリ選択（あれば）
        let categoryButtons = app.buttons.matching(
            NSPredicate(format: "identifier BEGINSWITH 'category_'")
        )
        if categoryButtons.count > 0 {
            categoryButtons.element(boundBy: 0).tap()
            sleep(1)
            takeScreenshot(name: "IT-UI-003_04_カテゴリ選択済み")
        }

        // 「確定」をタップ
        tapKeypad("=")
        sleep(2)
        takeScreenshot(name: "IT-UI-003_05_入力完了ポップアップ")

        // ポップアップ閉じる（OKボタン or 背景タップ）
        let okButton = app.buttons.matching(NSPredicate(format: "label CONTAINS 'OK'"))
        if okButton.count > 0 {
            okButton.element(boundBy: 0).tap()
            sleep(1)
        }

        // モーダルを閉じる
        let closeButton = app.buttons["closeModalButton"]
        if closeButton.exists {
            closeButton.tap()
            sleep(1)
        }

        takeScreenshot(name: "IT-UI-003_06_ダッシュボード_入力後")
    }

    // MARK: - IT-UI-004: サイドメニュー・設定画面遷移

    func testSideMenuNavigation() throws {
        launchWithOnboardingComplete()
        waitForDashboard()

        // サイドメニューを開く
        let menuButton = app.buttons["sideMenuButton"]
        XCTAssertTrue(menuButton.exists, "メニューボタンが存在するべき")
        menuButton.tap()
        sleep(1)

        // メニュー項目の存在確認
        let settingsMenu = app.buttons["menu_settings"]
        XCTAssertTrue(settingsMenu.waitForExistence(timeout: 5), "設定メニューが表示されるべき")
        takeScreenshot(name: "IT-UI-004_01_サイドメニュー表示")

        // 設定画面へ遷移
        settingsMenu.tap()
        sleep(1)

        // 設定画面の確認（「設定」というナビゲーションタイトルを探す）
        let settingsTitle = app.navigationBars["設定"]
        XCTAssertTrue(settingsTitle.waitForExistence(timeout: 5), "設定画面が表示されるべき")
        takeScreenshot(name: "IT-UI-004_02_設定画面")

        // 閉じる
        let closeButton = app.buttons["閉じる"]
        if closeButton.exists {
            closeButton.tap()
            sleep(1)
        }

        // サイドメニュー再表示 → 予算設定
        menuButton.tap()
        sleep(1)

        let budgetMenu = app.buttons["menu_budgetConfig"]
        if budgetMenu.waitForExistence(timeout: 3) {
            budgetMenu.tap()
            sleep(1)
            takeScreenshot(name: "IT-UI-004_03_予算設定画面")

            let closeBudget = app.buttons["閉じる"]
            if closeBudget.exists {
                closeBudget.tap()
                sleep(1)
            }
        }

        // サイドメニュー再表示 → カテゴリ設定
        menuButton.tap()
        sleep(1)

        let categoryMenu = app.buttons["menu_categoryConfig"]
        if categoryMenu.waitForExistence(timeout: 3) {
            categoryMenu.tap()
            sleep(1)
            takeScreenshot(name: "IT-UI-004_04_カテゴリ設定画面")
        }
    }

    // MARK: - IT-UI-005: テンキー計算機能

    func testCalculatorFunction() throws {
        launchWithOnboardingComplete()
        waitForDashboard()
        openQuickInput()

        // 「1000 + 500」を入力
        tapKeypad("1")
        tapKeypad("0")
        tapKeypad("0")
        tapKeypad("0")
        tapKeypad("+")
        tapKeypad("5")
        tapKeypad("0")
        tapKeypad("0")
        sleep(1)
        takeScreenshot(name: "IT-UI-005_01_計算式_1000+500")

        // Cキーでクリア
        tapKeypad("C")
        sleep(1)
        takeScreenshot(name: "IT-UI-005_02_クリア後")

        // モーダルを閉じる
        app.buttons["closeModalButton"].tap()
    }

    // MARK: - IT-UI-006: 収入入力モード切替

    func testIncomeInputMode() throws {
        launchWithOnboardingComplete()
        waitForDashboard()
        openQuickInput()
        takeScreenshot(name: "IT-UI-006_01_支出モード初期")

        // 「収入」タブに切替
        let incomeTab = app.buttons["収入"]
        XCTAssertTrue(incomeTab.exists, "収入タブが存在するべき")
        incomeTab.tap()
        sleep(1)
        takeScreenshot(name: "IT-UI-006_02_収入モード")

        // 収入額入力（300000）
        tapKeypad("3")
        tapKeypad("0")
        tapKeypad("0")
        tapKeypad("0")
        tapKeypad("0")
        tapKeypad("0")
        sleep(1)
        takeScreenshot(name: "IT-UI-006_03_収入金額入力")

        // 「給与」カテゴリ選択
        let salaryButton = app.buttons["category_給与"]
        if salaryButton.exists {
            salaryButton.tap()
            sleep(1)
            takeScreenshot(name: "IT-UI-006_04_給与カテゴリ選択")
        }

        app.buttons["closeModalButton"].tap()
    }

    // MARK: - IT-UI-007: 立替（IOU）モード

    func testIOUMode() throws {
        launchWithOnboardingComplete()
        waitForDashboard()
        openQuickInput()

        // 立替トグル（Switch）を探してONにする
        let toggle = app.switches.firstMatch
        if toggle.exists && toggle.value as? String == "0" {
            toggle.tap()
            sleep(1)
        }
        takeScreenshot(name: "IT-UI-007_01_立替モードON")

        // 2段入力UIの確認
        let iouLabel = app.staticTexts["みんなの立替分"]
        XCTAssertTrue(iouLabel.waitForExistence(timeout: 3), "立替モードの2段入力UIが表示されるべき")
        takeScreenshot(name: "IT-UI-007_02_立替モード_2段入力UI")

        app.buttons["closeModalButton"].tap()
    }

    // MARK: - IT-UI-008: 月切替ナビゲーション

    func testMonthNavigation() throws {
        launchWithOnboardingComplete()
        waitForDashboard()
        takeScreenshot(name: "IT-UI-008_01_当月表示")

        // 前月に移動（◀ ボタン: identifier='chevron.left'）
        let prevButton = app.buttons.matching(
            NSPredicate(format: "identifier == 'chevron.left'")
        ).firstMatch
        if prevButton.exists {
            prevButton.tap()
            sleep(1)
            takeScreenshot(name: "IT-UI-008_02_前月表示")

            prevButton.tap()
            sleep(1)
            takeScreenshot(name: "IT-UI-008_03_2ヶ月前表示")

            // 次月に戻る（▶ ボタン: identifier='chevron.right'）
            let nextButton = app.buttons.matching(
                NSPredicate(format: "identifier == 'chevron.right'")
            ).firstMatch
            if nextButton.exists {
                nextButton.tap()
                sleep(1)
                takeScreenshot(name: "IT-UI-008_04_次月に戻る")
            }
        }
    }

    // MARK: - IT-UI-009: 2回目起動時はオンボーディングスキップ

    func testSecondLaunchSkipsOnboarding() throws {
        launchWithOnboardingComplete()

        // 直接ダッシュボードが表示される
        waitForDashboard()

        // 同意ボタンが表示されないことを確認
        let agreeButton = app.buttons["agreeButton"]
        XCTAssertFalse(agreeButton.exists, "規約同意画面は表示されないべき")

        takeScreenshot(name: "IT-UI-009_01_2回目起動_ダッシュボード直接表示")
    }

    // MARK: - IT-UI-010: バックスペース（⌫）キー

    func testBackspaceKey() throws {
        launchWithOnboardingComplete()
        waitForDashboard()
        openQuickInput()

        // 「123」を入力
        tapKeypad("1")
        tapKeypad("2")
        tapKeypad("3")
        sleep(1)
        takeScreenshot(name: "IT-UI-010_01_入力123")

        // ⌫で1文字削除
        tapKeypad("⌫")
        sleep(1)
        takeScreenshot(name: "IT-UI-010_02_バックスペース後_12")

        tapKeypad("⌫")
        sleep(1)
        takeScreenshot(name: "IT-UI-010_03_バックスペース後_1")

        app.buttons["closeModalButton"].tap()
    }
}
