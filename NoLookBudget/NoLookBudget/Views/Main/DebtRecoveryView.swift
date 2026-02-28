import SwiftUI

struct DebtRecoveryView: View {
    let categoryName: String
    let debtAmount: Int
    
    @State private var selectedPlan: RecoveryPlan? = nil
    @Environment(\.dismiss) private var dismiss
    
    enum RecoveryPlan: String, CaseIterable {
        case oneShot = "翌月一括"
        case threeMonths = "3ヶ月分割"
        case sixMonths = "半年分割"
        case oneYear = "1年分割"
        
        var description: String {
            switch self {
            case .oneShot: return "ドカンと引いて早く身軽になる"
            case .threeMonths: return "少しペースを落として返済"
            case .sixMonths: return "毎月の負担を最小限に抑える"
            case .oneYear: return "長期でじっくりリカバリー"
            }
        }
        
        var divider: Int {
            switch self {
            case .oneShot: return 1
            case .threeMonths: return 3
            case .sixMonths: return 6
            case .oneYear: return 12
            }
        }
        
        var icon: String {
            switch self {
            case .oneShot: return "bolt.fill"
            case .threeMonths: return "hare.fill"
            case .sixMonths: return "tortoise.fill"
            case .oneYear: return "leaf.fill"
            }
        }
        
        var isPremium: Bool {
            return self != .oneShot
        }
    }
    
    var body: some View {
        ZStack {
            Color(red: 0.13, green: 0.13, blue: 0.14).ignoresSafeArea()
            
            VStack(spacing: 20) {
                // ヘッダー
                VStack(spacing: 8) {
                    Text("\(categoryName)の借金回収設定")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                    
                    Text("回収対象額: ¥\(debtAmount)")
                        .font(.title3)
                        .fontWeight(.black)
                        .foregroundColor(Color(red: 0.9, green: 0.4, blue: 0.4))
                }
                .padding(.top, 20)
                
                Text("来月以降の予算からどのように差し引くかを選択してください。")
                    .font(.footnote)
                    .foregroundColor(.gray)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 30)
                
                // プラン選択リスト
                ScrollView {
                    VStack(spacing: 15) {
                        ForEach(RecoveryPlan.allCases, id: \.self) { plan in
                            RecoveryPlanRow(
                                plan: plan,
                                debtAmount: debtAmount,
                                isSelected: selectedPlan == plan
                            )
                            .onTapGesture {
                                selectedPlan = plan
                            }
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 10)
                }
                
                // 次へボタン
                NavigationLink(destination: DebtRecoverySourceSelectionView(targetCategoryName: categoryName, debtAmount: debtAmount, selectedPlan: selectedPlan)) {
                    Text(selectedPlan == nil ? "プランを選択してください" : "次へ（減額元の選択）")
                        .font(.headline)
                        .fontWeight(.bold)
                        .foregroundColor(selectedPlan == nil ? .gray : .white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(selectedPlan == nil ? Color(white: 0.2) : Color.blue)
                        .cornerRadius(12)
                }
                .disabled(selectedPlan == nil)
                .padding(.horizontal, 20)
                .padding(.bottom, 30)
            }
        }
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct RecoveryPlanRow: View {
    let plan: DebtRecoveryView.RecoveryPlan
    let debtAmount: Int
    let isSelected: Bool
    
    var monthlyDeduction: Int {
        return debtAmount / plan.divider
    }
    
    var body: some View {
        HStack(spacing: 15) {
            // アイコン
            ZStack {
                Circle()
                    .fill(isSelected ? Color.blue.opacity(0.2) : Color(white: 0.2))
                    .frame(width: 40, height: 40)
                
                Image(systemName: plan.icon)
                    .foregroundColor(isSelected ? .blue : .gray)
            }
            
            // テキスト
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(plan.rawValue)
                        .font(.headline)
                        .foregroundColor(.white)
                    
                    if plan.isPremium {
                        Text("実装予定")
                            .font(.system(size: 9, weight: .bold))
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.gray.opacity(0.8))
                            .foregroundColor(.white)
                            .cornerRadius(4)
                    }
                }
                
                Text(plan.description)
                    .font(.caption)
                    .foregroundColor(.gray)
            }
            
            Spacer()
            
            // 金額
            VStack(alignment: .trailing, spacing: 2) {
                Text("来月は")
                    .font(.system(size: 10))
                    .foregroundColor(.gray)
                Text("-¥\(monthlyDeduction)")
                    .font(.subheadline)
                    .fontWeight(.bold)
                    .foregroundColor(Color(red: 0.9, green: 0.4, blue: 0.4))
            }
            
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
        DebtRecoveryView(categoryName: "食費", debtAmount: 12000)
    }
}
