import SwiftUI

struct NumberPadModalView: View {
    @Binding var textValue: String
    @Environment(\.dismiss) private var dismiss
    
    // 内部で入力状態を持つ
    @State private var currentInput: String = "0"
    
    var title: String = "金額の入力"
    var onCommit: () -> Void = {}
    
    let buttons: [[String]] = [
        ["1", "2", "3"],
        ["4", "5", "6"],
        ["7", "8", "9"],
        ["C", "0", "⌫"]
    ]
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color(red: 0.1, green: 0.1, blue: 0.11).ignoresSafeArea()
                
                VStack(spacing: 20) {
                    Spacer()
                    
                    // 表示部
                    Text("¥ \(currentInput)")
                        .font(.system(size: 40, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                        .lineLimit(1)
                        .minimumScaleFactor(0.5)
                        .padding()
                        .frame(maxWidth: .infinity, alignment: .trailing)
                        .background(Color.white.opacity(0.1))
                        .cornerRadius(12)
                        .padding(.horizontal, 20)
                    
                    Spacer()
                    
                    // キーパッド
                    VStack(spacing: 12) {
                        ForEach(buttons, id: \.self) { row in
                            HStack(spacing: 12) {
                                ForEach(row, id: \.self) { btn in
                                    Button(action: {
                                        handleTap(btn)
                                    }) {
                                        Text(btn)
                                            .font(.title)
                                            .fontWeight(.bold)
                                            .foregroundColor(.white)
                                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                                            .padding(.vertical, 20)
                                            .background(btn == "C" || btn == "⌫" ? Color.gray.opacity(0.3) : Color.white.opacity(0.1))
                                            .cornerRadius(12)
                                    }
                                }
                            }
                        }
                    }
                    .padding(.horizontal, 20)
                    
                    // 確定ボタン
                    Button(action: {
                        let generator = UIImpactFeedbackGenerator(style: .medium)
                        generator.impactOccurred()
                        textValue = currentInput == "0" ? "" : currentInput
                        onCommit()
                        dismiss()
                    }) {
                        Text("決定")
                            .font(.title3.bold())
                            .foregroundColor(.black)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(Color.yellow)
                            .cornerRadius(12)
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 30)
                }
            }
            .navigationTitle(title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("キャンセル") { dismiss() }
                        .foregroundColor(.gray)
                }
            }
        }
        .onAppear {
            if !textValue.isEmpty, let _ = Int(textValue) {
                currentInput = textValue
            } else {
                currentInput = "0"
            }
        }
    }
    
    private func handleTap(_ btn: String) {
        let generator = UIImpactFeedbackGenerator(style: .light)
        generator.impactOccurred()
        
        if btn == "C" {
             currentInput = "0"
        } else if btn == "⌫" {
            if currentInput.count > 1 {
                currentInput.removeLast()
            } else {
                currentInput = "0"
            }
        } else {
            // max 9桁程度に制限
            if currentInput.count < 9 {
                if currentInput == "0" {
                    currentInput = btn
                } else {
                    currentInput += btn
                }
            }
        }
    }
}

#Preview {
    NumberPadModalView(textValue: .constant("1000"))
}
