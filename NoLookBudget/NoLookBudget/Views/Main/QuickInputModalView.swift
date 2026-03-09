import SwiftUI
import SwiftData

enum QuickInputMode {
    case expense
    case income
}

struct QuickInputModalView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel: QuickInputViewModel
    
    init(initialCategoryName: String? = nil, editingTransactionId: UUID? = nil, initialAmount: String = "0", isIncome: Bool = false, isIOU: Bool = false) {
        _viewModel = StateObject(wrappedValue: QuickInputViewModel(
            initialCategoryName: initialCategoryName,
            editingTransactionId: editingTransactionId,
            initialAmount: initialAmount,
            isIncome: isIncome,
            isIOU: isIOU
        ))
    }
    
    let columns = Array(repeating: GridItem(.flexible(), spacing: 10), count: 3)
    
    var body: some View {
        ZStack {
            // 背景（すりガラス効果 + ダークベース）
            Theme.spaceNavy.ignoresSafeArea()
            
            // 立替モード時は背景にオレンジの微かなグローを追加
            if viewModel.isIOUMode {
                RadialGradient(
                    gradient: Gradient(colors: [Theme.warmOrange.opacity(0.15), Color.clear]),
                    center: .bottom,
                    startRadius: 50,
                    endRadius: 500
                )
                .ignoresSafeArea()
                .transition(.opacity)
            }
            
            // 右下にマスコットを薄く表示 (透かしのように)
            VStack {
                Spacer()
                HStack {
                    Spacer()
                    Image("astronaut_mascot")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 80, height: 80)
                        .blendMode(.screen) // 追加: 黒背景を透過(合成)させる
                        .opacity(0.2)
                        .padding(.bottom, 20)
                        .padding(.trailing, 20)
                }
            }
            
            VStack(spacing: 20) {
                // Handle for modal
                Capsule()
                    .fill(Color.gray.opacity(0.5))
                    .frame(width: 40, height: 5)
                    .padding(.top, 10)
                
                // ヘッダー部（閉じるボタン + モード切替 + 立替トグル）
                HStack {
                    Button(action: {
                        dismiss()
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.title2)
                            .foregroundColor(.gray.opacity(0.8))
                    }
                    
                    Spacer()
                    
                    // 支出・収入のセグメント切替
                    Picker("入力モード", selection: $viewModel.inputMode.animation(.spring())) {
                        Text("支出").tag(QuickInputMode.expense)
                        Text("臨時収入").tag(QuickInputMode.income)
                    }
                    .pickerStyle(.segmented)
                    .frame(width: 150)
                    
                    Spacer()
                    
                    // 立替セパレーター (入力モードが支出の時のみ)
                    if viewModel.inputMode == .expense {
                        HStack(spacing: 8) {
                            Text("立替")
                                .font(.caption)
                                .fontWeight(.bold)
                                .foregroundColor(viewModel.isIOUMode ? Theme.warmOrange : .gray)
                            
                            Toggle("", isOn: $viewModel.isIOUMode.animation(.spring(response: 0.3, dampingFraction: 0.7)))
                                .labelsHidden()
                                .tint(Theme.warmOrange)
                                .onChange(of: viewModel.isIOUMode) { oldValue, newValue in
                                    let generator = UIImpactFeedbackGenerator(style: .light)
                                    generator.impactOccurred()
                                }
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(.ultraThinMaterial)
                        .cornerRadius(20)
                        .shadow(color: viewModel.isIOUMode ? Theme.warmOrange.opacity(0.3) : .clear, radius: 8, x: 0, y: 0)
                    } else {
                        // スペースのバランスを取るためのダミー
                        Color.clear.frame(width: 70, height: 30)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 10)
                
                // 入力金額表示 (上部)
                if viewModel.inputMode == .expense && viewModel.isIOUMode {
                    // 2段入力UI
                    VStack(spacing: 10) {
                        // 立替分枠
                        Button(action: {
                            let generator = UISelectionFeedbackGenerator()
                            generator.selectionChanged()
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                viewModel.currentFocus = .iou
                            }
                        }) {
                            HStack {
                                Text("みんなの立替分")
                                    .font(.subheadline).bold()
                                    .foregroundColor(viewModel.currentFocus == .iou ? Theme.warmOrange : .gray)
                                Spacer()
                                VStack(alignment: .trailing, spacing: 2) {
                                    Text(viewModel.iouExpression)
                                        .font(.system(size: 36, weight: .black, design: .rounded))
                                        .foregroundColor(viewModel.currentFocus == .iou ? Theme.warmOrange : .gray.opacity(0.5))
                                        .lineLimit(1)
                                        .minimumScaleFactor(0.4)
                                    if let res = viewModel.calculateResult(for: viewModel.iouExpression), res != viewModel.iouExpression {
                                        Text("= ¥\(res)")
                                            .font(.caption.bold())
                                            .foregroundColor(.gray)
                                    }
                                }
                            }
                            .padding(.horizontal, 15)
                            .padding(.vertical, 8)
                            .background(RoundedRectangle(cornerRadius: 15).fill(Color.white.opacity(viewModel.currentFocus == .iou ? 0.08 : 0.02)))
                            .overlay(
                                RoundedRectangle(cornerRadius: 15)
                                    .stroke(viewModel.currentFocus == .iou ? Theme.warmOrange.opacity(0.5) : Color.clear, lineWidth: 2)
                            )
                        }
                        
                        // 自分の支出枠
                        Button(action: {
                            let generator = UISelectionFeedbackGenerator()
                            generator.selectionChanged()
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                viewModel.currentFocus = .myExpense
                            }
                        }) {
                            HStack {
                                Text("自分自身の支出")
                                    .font(.subheadline).bold()
                                    .foregroundColor(viewModel.currentFocus == .myExpense ? .white : .gray)
                                Spacer()
                                VStack(alignment: .trailing, spacing: 2) {
                                    Text(viewModel.myExpenseExpression)
                                        .font(.system(size: 36, weight: .black, design: .rounded))
                                        .foregroundColor(viewModel.currentFocus == .myExpense ? .white : .gray.opacity(0.5))
                                        .lineLimit(1)
                                        .minimumScaleFactor(0.4)
                                    if let res = viewModel.calculateResult(for: viewModel.myExpenseExpression), res != viewModel.myExpenseExpression {
                                        Text("= ¥\(res)")
                                            .font(.caption.bold())
                                            .foregroundColor(.gray)
                                    }
                                }
                            }
                            .padding(.horizontal, 15)
                            .padding(.vertical, 8)
                            .background(RoundedRectangle(cornerRadius: 15).fill(Color.white.opacity(viewModel.currentFocus == .myExpense ? 0.08 : 0.02)))
                            .overlay(
                                RoundedRectangle(cornerRadius: 15)
                                    .stroke(viewModel.currentFocus == .myExpense ? Color.white.opacity(0.5) : Color.clear, lineWidth: 2)
                            )
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 5)
                } else {
                    // 通常の1段入力
                    VStack(alignment: .trailing, spacing: 2) {
                        Text(viewModel.expressionText)
                            .font(.system(size: 60, weight: .black, design: .rounded))
                            .foregroundColor(viewModel.inputMode == .income ? Theme.spaceGreen : .white)
                            .lineLimit(1)
                            .minimumScaleFactor(0.4)
                            .frame(maxWidth: .infinity, alignment: .trailing)
                            .contentTransition(.numericText(value: Double(viewModel.expressionText) ?? 0))
                            .animation(.spring(), value: viewModel.expressionText)
                        
                        if let result = viewModel.calculateResult(), result != viewModel.expressionText {
                            Text("= ¥\(result)")
                                .font(.title3.bold())
                                .foregroundColor(.gray)
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 5)
                }
                
                // 予算項目一覧 (中段: 2行3列)
                VStack(alignment: .leading, spacing: 10) {
                    if viewModel.inputMode == .income {
                        Text("収入の種類を選択")
                            .font(.caption)
                            .fontWeight(.bold)
                            .foregroundColor(Theme.spaceGreen)
                            .padding(.horizontal, 20)
                            
                        let incomeTypes = ["給与", "賞与", "副業", "投資", "お小遣い", "その他"]
                        LazyVGrid(columns: columns, spacing: 10) {
                            ForEach(incomeTypes, id: \.self) { type in
                                CategorySelectButton(
                                    title: type,
                                    isSelected: viewModel.selectedIncomeCategory == type,
                                    isIOUMode: false
                                ) {
                                    let generator = UIImpactFeedbackGenerator(style: .light)
                                    generator.impactOccurred()
                                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                        viewModel.selectedIncomeCategory = type
                                    }
                                }
                            }
                        }
                        .padding(.horizontal, 20)
                    } else {
                        Text(viewModel.isIOUMode ? "対象のカテゴリ (立替用)" : "予算項目を選択")
                            .font(.caption)
                            .fontWeight(.bold)
                            .foregroundColor(.gray)
                            .padding(.horizontal, 20)
                        
                        LazyVGrid(columns: columns, spacing: 10) {
                            ForEach(viewModel.categories) { category in
                                CategorySelectButton(
                                    title: category.name,
                                    isSelected: viewModel.selectedCategory?.id == category.id,
                                    isIOUMode: viewModel.isIOUMode
                                ) {
                                    let generator = UIImpactFeedbackGenerator(style: .light)
                                    generator.impactOccurred()
                                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                        viewModel.selectedCategory = category
                                    }
                                }
                            }
                        }
                        .padding(.horizontal, 20)
                    }
                }
                
                Spacer(minLength: 10)
                
                // 電卓キーパッド (下部)
                let activeBinding = Binding<String>(
                    get: {
                        if viewModel.inputMode == .expense && viewModel.isIOUMode {
                            return viewModel.currentFocus == .iou ? viewModel.iouExpression : viewModel.myExpenseExpression
                        }
                        return viewModel.expressionText
                    },
                    set: { newValue in
                        if viewModel.inputMode == .expense && viewModel.isIOUMode {
                            if viewModel.currentFocus == .iou {
                                viewModel.iouExpression = newValue
                            } else {
                                viewModel.myExpenseExpression = newValue
                            }
                        } else {
                            viewModel.expressionText = newValue
                        }
                    }
                )
                
                CalculatorKeypad(expressionText: activeBinding, inputMode: viewModel.inputMode, isIOUMode: viewModel.isIOUMode, isEditing: viewModel.editingTransactionId != nil, onCommit: submitExpense)
                    .padding(.horizontal, 20)
                    .padding(.bottom, 20)
                    .alert(isPresented: $viewModel.showAlert) {
                        Alert(
                            title: Text("入力エラー"),
                            message: Text(viewModel.alertMessage ?? ""),
                            dismissButton: .default(Text("OK"))
                        )
                    }
            }
        }
        .onAppear {
            // fetchDataはViewModelのinit等で呼ばれる想定
        }
    }
    
    private func submitExpense() {
        if viewModel.logExpense() {
            dismiss()
        }
    }
}

// MARK: - Subviews

struct CategorySelectButton: View {
    let title: String
    let isSelected: Bool
    let isIOUMode: Bool // 追加
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 14, weight: .bold))
                .foregroundColor(isSelected ? (isIOUMode ? .white : .black) : .white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(
                    ZStack {
                        if isSelected {
                            if isIOUMode {
                                Theme.dangerGradient
                            } else {
                                Theme.safeGradient
                            }
                        } else {
                            Rectangle().fill(.ultraThinMaterial)
                        }
                    }
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(isSelected ? Color.clear : Color.white.opacity(0.1), lineWidth: 1)
                )
                .cornerRadius(12)
                .shadow(color: isSelected ? (isIOUMode ? Theme.warmOrange.opacity(0.4) : Theme.spaceGreen.opacity(0.4)) : .clear, radius: 8, x: 0, y: 4)
        }
        .buttonStyle(ScaleButtonStyle())
    }
}

// --- 電卓のキーパッド部品 ---
struct CalculatorKeypad: View {
    @Binding var expressionText: String
    var inputMode: QuickInputMode
    var isIOUMode: Bool
    var isEditing: Bool
    let onCommit: () -> Void
    
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
                            let generator = UIImpactFeedbackGenerator(style: .light)
                            generator.impactOccurred()
                            handleButtonTap(btn)
                        }) {
                            Text(btn == "=" ? (isEditing ? "更新" : (inputMode == .income ? "追加" : (isIOUMode ? "立替" : "使う"))) : btn)
                                .font(.system(size: btn == "=" ? 20 : 26, weight: .bold, design: .rounded))
                                .foregroundColor(foregroundColor(for: btn))
                                .frame(maxWidth: .infinity, maxHeight: .infinity)
                                .background(backgroundView(for: btn))
                                .clipShape(Circle())
                                .shadow(color: shadowColor(for: btn), radius: btn == "=" ? 10 : 0, x: 0, y: btn == "=" ? 5 : 0)
                        }
                        .buttonStyle(ScaleButtonStyle())
                    }
                }
            }
        }
    }
    
    @ViewBuilder
    private func backgroundView(for button: String) -> some View {
        switch button {
        case "C", "⌫":
            Color.white.opacity(0.1)
        case "％", "÷", "×", "-", "+":
            Color.white.opacity(0.15)
        case "=":
            if inputMode == .income {
                Theme.safeGradient
            } else if isIOUMode {
                Theme.dangerGradient
            } else {
                Theme.safeGradient
            }
        default:
            Rectangle().fill(.ultraThinMaterial)
        }
    }
    
    private func shadowColor(for button: String) -> Color {
        if button == "=" {
            return (inputMode == .income || !isIOUMode) ? Theme.spaceGreen.opacity(0.4) : Theme.warmOrange.opacity(0.4)
        }
        return .clear
    }
    
    private func foregroundColor(for button: String) -> Color {
        switch button {
        case "=": return (inputMode == .income || isIOUMode) ? .white : .black
        case "C", "⌫", "％", "÷", "×", "-", "+": return .gray
        default: return .white
        }
    }
    
    private func handleButtonTap(_ btn: String) {
        let isOperator = ["+", "-", "×", "÷", "％", "."].contains(btn)
        
        switch btn {
        case "C":
            withAnimation(.spring()) {
                expressionText = "0"
            }
        case "⌫":
            var nextText = expressionText
            if nextText.count > 1 {
                nextText.removeLast()
            } else {
                nextText = "0"
            }
            withAnimation(.spring()) {
                expressionText = nextText
            }
        case "=":
            onCommit()
        default:
            var nextText = expressionText
            if nextText == "0" && !isOperator {
                nextText = btn
            } else {
                // 演算子の連続入力を防ぐ（最後が演算子なら置き換える）
                if isOperator {
                    if let last = nextText.last, ["+", "-", "×", "÷", "％", "."].contains(String(last)) {
                        nextText.removeLast()
                    }
                }
                // 長すぎる入力を防ぐ
                if nextText.count < 15 {
                    nextText.append(btn)
                }
            }
            withAnimation(.spring()) {
                expressionText = nextText
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
