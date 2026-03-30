import SwiftUI
import SwiftData

struct BudgetConfigurationView: View {
    @StateObject private var viewModel = ConfigurationViewModel()
    @Environment(\.dismiss) private var dismiss
    @State private var activeInputType: InputType? = nil
    
    enum InputType {
        case income
        case savings
    }
    
    var body: some View {
        Form {
            // 手取り額セクション
            Section(header: Text("今月の手取り総額").foregroundColor(.gray)) {
                VStack(alignment: .leading, spacing: 10) {
                    Text("給与などの今月自由に使えるお金の総額を入力してください。")
                        .font(.caption)
                        .foregroundColor(.gray)
                    
                    Button(action: {
                        activeInputType = .income
                    }) {
                        HStack {
                            Text("¥")
                                .foregroundColor(.gray)
                            Text(viewModel.incomeAmount.isEmpty ? "金額を入力" : viewModel.incomeAmount)
                                .foregroundColor(viewModel.incomeAmount.isEmpty ? .gray : .white)
                                .font(.system(size: 20, weight: .bold))
                            Spacer()
                        }
                        .padding()
                        .background(Color.white.opacity(0.1))
                        .cornerRadius(8)
                    }
                }
                .padding(.vertical, 5)
            }
            .listRowBackground(Color.white.opacity(0.05))
            
            // 限定機能だった先取り貯金セクションを開放
            Section(header: Text("先取り貯金").foregroundColor(.gray)) {
                VStack(alignment: .leading, spacing: 10) {
                    Text("強制的に貯金に回す額を設定します（入力すると予算から天引きされます）。")
                        .font(.caption)
                        .foregroundColor(.gray)
                    
                    Button(action: {
                        activeInputType = .savings
                    }) {
                        HStack {
                            Text("¥")
                                .foregroundColor(.gray)
                            Text(viewModel.savingsAmount.isEmpty ? "0" : viewModel.savingsAmount)
                                .foregroundColor(.white)
                                .font(.system(size: 20, weight: .bold))
                            Spacer()
                        }
                        .padding()
                        .background(Color.white.opacity(0.1))
                        .cornerRadius(8)
                    }
                }
                .padding(.vertical, 5)
            }
            .listRowBackground(Color.white.opacity(0.05))
            
            // 固定費リストセクション
            Section(header: Text("固定費の設定").foregroundColor(.gray)) {
                List {
                    ForEach(viewModel.fixedCosts) { cost in
                        Button(action: {
                            viewModel.prepareEditingFixedCost(cost)
                        }) {
                            HStack {
                                Text(cost.name)
                                    .foregroundColor(.white)
                                Spacer()
                                Text("¥\(formatCurrency(cost.amount))")
                                    .fontWeight(.bold)
                                    .foregroundColor(.white)
                                Image(systemName: "chevron.right")
                                    .foregroundColor(.gray)
                                    .font(.caption)
                            }
                        }
                    }
                    .onDelete(perform: viewModel.deleteFixedCosts)
                    .onMove(perform: viewModel.moveFixedCosts)
                    .listRowBackground(Color.white.opacity(0.05))
                    
                    Button(action: {
                        viewModel.prepareAddingFixedCost()
                    }) {
                        HStack {
                            Image(systemName: "plus.circle.fill")
                            Text("新規固定費を追加")
                        }
                        .foregroundColor(.yellow)
                    }
                    .listRowBackground(Color.white.opacity(0.05))
                }
            }
            
            // 最終計算結果
            Section(header: Text("最終的なベース予算 (変動費)").foregroundColor(.gray)) {
                let income = Double(viewModel.incomeAmount) ?? 0
                let savings = Double(viewModel.savingsAmount) ?? 0
                let totalFixed = viewModel.fixedCosts.reduce(0) { $0 + $1.amount }
                let calculatedBaseBudget = max(0, income - savings - totalFixed)
                
                HStack {
                    Text("¥\(formatCurrency(calculatedBaseBudget))")
                        .font(.system(size: 24, weight: .black, design: .rounded))
                        .foregroundColor(Color(red: 0.4, green: 0.9, blue: 0.6))
                    Spacer()
                    Text("自由に使えるお金")
                        .font(.caption)
                        .foregroundColor(.gray)
                }
                .padding(.vertical, 5)
            }
            .listRowBackground(Color.white.opacity(0.05))
        }
        .navigationTitle("基本予算と固定費")
        .navigationBarTitleDisplayMode(.inline)
        .scrollContentBackground(.hidden)
        .background(Color(red: 0.1, green: 0.1, blue: 0.11).ignoresSafeArea())
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("保存") {
                    let generator = UIImpactFeedbackGenerator(style: .medium)
                    generator.impactOccurred()
                    viewModel.saveBudget()
                    dismiss()
                }
                .fontWeight(.bold)
                .foregroundColor(.yellow)
            }
        }
        .sheet(item: $activeInputType) { inputType in
            switch inputType {
            case .income:
                NumberPadModalView(textValue: $viewModel.incomeAmount, title: "手取り総額の入力")
                    .presentationDetents([.fraction(0.85)])
            case .savings:
                NumberPadModalView(textValue: $viewModel.savingsAmount, title: "先取り貯金額の入力")
                    .presentationDetents([.fraction(0.85)])
            }
        }
        .sheet(isPresented: $viewModel.showFixedCostModal) {
            FixedCostEditModalView(viewModel: viewModel)
                .presentationDetents([.fraction(0.7)])
        }
    }
}

extension BudgetConfigurationView.InputType: Identifiable {
    var id: Self { self }
}

// ---------------------------------------------------------
// 固定費専用の追加・編集モーダル
// ---------------------------------------------------------
struct FixedCostEditModalView: View {
    @ObservedObject var viewModel: ConfigurationViewModel
    @State private var showNumberPad = false
    
    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("固定費の名称")) {
                    TextField("例: 家賃、サブスク等", text: $viewModel.draftFixedCostName)
                        .foregroundColor(.white)
                }
                .listRowBackground(Color.white.opacity(0.1))
                
                Section(header: Text("金額")) {
                    Button(action: {
                        showNumberPad = true
                    }) {
                        HStack {
                            Text("¥")
                                .foregroundColor(.gray)
                            Text(viewModel.draftFixedCostAmount.isEmpty ? "金額を入力" : viewModel.draftFixedCostAmount)
                                .foregroundColor(viewModel.draftFixedCostAmount.isEmpty ? .gray : .white)
                            Spacer()
                        }
                    }
                }
                .listRowBackground(Color.white.opacity(0.1))
            }
            .scrollContentBackground(.hidden)
            .background(Color(red: 0.1, green: 0.1, blue: 0.11).ignoresSafeArea())
            .navigationTitle(viewModel.editingFixedCost == nil ? "固定費の追加" : "固定費の編集")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("キャンセル") {
                        viewModel.showFixedCostModal = false
                    }
                    .foregroundColor(.gray)
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("保存") {
                        let generator = UIImpactFeedbackGenerator(style: .medium)
                        generator.impactOccurred()
                        viewModel.saveFixedCost()
                    }
                    .foregroundColor(.yellow)
                    .fontWeight(.bold)
                    // 名前か金額が空なら押せない
                    .disabled(viewModel.draftFixedCostName.isEmpty || viewModel.draftFixedCostAmount.isEmpty)
                }
            }
            .sheet(isPresented: $showNumberPad) {
                NumberPadModalView(textValue: $viewModel.draftFixedCostAmount, title: "固定費の金額")
                    .presentationDetents([.fraction(0.85)])
                    .preferredColorScheme(.dark)
            }
        }
        .preferredColorScheme(.dark)
    }
}

#Preview {
    BudgetConfigurationView()
        .preferredColorScheme(.dark)
}
