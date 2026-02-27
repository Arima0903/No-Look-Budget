import SwiftUI
import SwiftData

struct QuickInputModalView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Query private var budgets: [Budget]
    
    @State private var amountText: String = ""
    @State private var isIOU: Bool = false // 立替(Front)スイッチ
    
    var body: some View {
        ZStack {
            Color(red: 0.15, green: 0.15, blue: 0.16).ignoresSafeArea()
            
            VStack(spacing: 25) {
                // Handle for modal
                Capsule()
                    .fill(Color.gray.opacity(0.5))
                    .frame(width: 40, height: 5)
                    .padding(.top, 10)
                
                // Toggle Switch (自分 vs 立替)
                HStack(spacing: 0) {
                    ToggleButton(title: "💳 自分の支出", isSelected: !isIOU) {
                        isIOU = false
                    }
                    ToggleButton(title: "🍻 立替 (Front)", isSelected: isIOU) {
                        isIOU = true
                    }
                }
                .background(Color.black.opacity(0.3))
                .cornerRadius(12)
                .padding(.horizontal)
                
                // Amount Input Display
                Text("¥ \(amountText.isEmpty ? "0" : amountText)")
                    .font(.system(size: 50, weight: .bold))
                    .foregroundColor(isIOU ? .orange : .white)
                    .frame(maxWidth: .infinity, alignment: .trailing)
                    .padding(.horizontal, 40)
                    .padding(.vertical, 10)
                
                // Custom Numpad
                VStack(spacing: 15) {
                    ForEach([[1,2,3], [4,5,6], [7,8,9]], id: \.self) { row in
                        HStack(spacing: 20) {
                            ForEach(row, id: \.self) { num in
                                NumpadButton(value: "\(num)") {
                                    if amountText.count < 8 {
                                        amountText.append("\(num)")
                                    }
                                }
                            }
                        }
                    }
                    HStack(spacing: 20) {
                        NumpadButton(value: "00") {
                            if !amountText.isEmpty && amountText.count < 7 {
                                amountText.append("00")
                            }
                        }
                        NumpadButton(value: "0") {
                            if !amountText.isEmpty && amountText.count < 8 {
                                amountText.append("0")
                            }
                        }
                        NumpadButton(value: "⌫") {
                            if !amountText.isEmpty {
                                amountText.removeLast()
                            }
                        }
                    }
                }
                
                // Log Button
                Button(action: logExpense) {
                    Text(isIOU ? "立替プールへ逃がす" : "使った！")
                        .font(.title3)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(
                            amountText.isEmpty ? Color.gray.opacity(0.3) :
                            (isIOU ? Color.orange : Color(red: 0.4, green: 0.9, blue: 0.6))
                        )
                        .cornerRadius(15)
                }
                .disabled(amountText.isEmpty)
                .padding(.horizontal, 40)
                .padding(.top, 10)
                
                Spacer()
            }
        }
    }
    
    private func logExpense() {
        guard let amount = Double(amountText) else { return }
        
        let newTransaction = ExpenseTransaction(amount: amount, isIOU: isIOU)
        modelContext.insert(newTransaction)
        
        if isIOU {
            let iouRecord = IOURecord(amount: amount)
            modelContext.insert(iouRecord)
        } else {
            if let budget = budgets.first {
                budget.spentAmount += amount
            }
        }
        
        // Haptic Feedback for physical satisfaction
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(isIOU ? .warning : .success)
        
        dismiss()
    }
}

struct ToggleButton: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.subheadline)
                .fontWeight(.bold)
                .foregroundColor(isSelected ? .white : .gray)
                .padding(.vertical, 12)
                .frame(maxWidth: .infinity)
                .background(isSelected ? Color.gray.opacity(0.4) : Color.clear)
                .cornerRadius(10)
        }
    }
}

struct NumpadButton: View {
    let value: String
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(value)
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.white)
                .frame(width: 75, height: 75)
                .background(Color.white.opacity(0.1))
                .clipShape(Circle())
        }
    }
}

#Preview {
    QuickInputModalView()
        .modelContainer(for: [Budget.self, ItemCategory.self, IOURecord.self, ExpenseTransaction.self], inMemory: true)
}
