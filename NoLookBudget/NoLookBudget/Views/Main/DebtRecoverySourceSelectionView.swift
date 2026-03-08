import SwiftUI

struct DebtRecoverySourceSelectionView: View {
    let targetCategoryName: String
    let debtAmount: Int
    let selectedPlan: DebtRecoveryView.RecoveryPlan?
    
    @Environment(\.dismiss) private var dismiss
    @State private var selectedSourceCategory: String? = nil
    
    // --- モック用のカテゴリ一覧 ---
    @StateObject private var viewModel = DebtRecoveryViewModel()
    
    var body: some View {
        ZStack {
            Color(red: 0.13, green: 0.13, blue: 0.14).ignoresSafeArea()
            
            VStack(spacing: 20) {
                // ヘッダー
                VStack(spacing: 8) {
                    Text("減額元の予算を選択")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                    
                    Text("\(targetCategoryName) のマイナス分を補填します")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                }
                .padding(.top, 20)
                
                Text("来月以降、どの項目の予算を減らして借金を回収するか選んでください。")
                    .font(.footnote)
                    .foregroundColor(.gray)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 30)
                
                // カテゴリ選択リスト
                ScrollView {
                    VStack(spacing: 12) {
                        ForEach(viewModel.categories) { category in
                            SourceCategoryRow(
                                name: category.name,
                                isTarget: category.name == targetCategoryName,
                                isSelected: selectedSourceCategory == category.name
                            )
                            .onTapGesture {
                                selectedSourceCategory = category.name
                            }
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 10)
                }
                
                // 決定ボタン
                Button(action: {
                    if let source = selectedSourceCategory {
                        let monthlyDeduction = Double(debtAmount) / Double(selectedPlan?.divider ?? 1)
                        _ = viewModel.recoverDebt(sourceCategoryName: source, targetCategoryName: targetCategoryName, amount: monthlyDeduction)
                        dismiss()
                    }
                }) {
                    Text(selectedSourceCategory == nil ? "カテゴリを選択してください" : "設定を完了する")
                        .font(.headline)
                        .fontWeight(.bold)
                        .foregroundColor(selectedSourceCategory == nil ? .gray : .white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(selectedSourceCategory == nil ? Color(white: 0.2) : Color.blue)
                        .cornerRadius(12)
                }
                .disabled(selectedSourceCategory == nil)
                .padding(.horizontal, 20)
                .padding(.bottom, 30)
            }
        }
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct SourceCategoryRow: View {
    let name: String
    let isTarget: Bool
    let isSelected: Bool
    
    var body: some View {
        HStack(spacing: 15) {
            // アイコン代わりの円形
            ZStack {
                Circle()
                    .fill(isSelected ? Color.blue.opacity(0.2) : Color(white: 0.2))
                    .frame(width: 40, height: 40)
                
                Image(systemName: isTarget ? "arrow.turn.down.right" : "folder.fill")
                    .foregroundColor(isSelected ? .blue : .gray)
            }
            
            Text(isTarget ? "\(name) (自身の来月予算から引く)" : name)
                .font(.headline)
                .foregroundColor(isTarget ? .yellow : .white)
            
            Spacer()
            
            // チェックマーク
            if isSelected {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(.blue)
                    .font(.title3)
            }
        }
        .padding()
        .background(isSelected ? Color.blue.opacity(0.1) : Color(red: 0.18, green: 0.18, blue: 0.19))
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(isSelected ? Color.blue : Color.clear, lineWidth: 2)
        )
    }
}

#Preview {
    NavigationStack {
        DebtRecoverySourceSelectionView(targetCategoryName: "食費", debtAmount: 12000, selectedPlan: .oneShot)
    }
}
