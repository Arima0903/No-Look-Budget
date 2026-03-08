import SwiftUI
import SwiftData

struct IOURecordView: View {
    @StateObject private var viewModel = IOUViewModel()
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color(red: 0.1, green: 0.1, blue: 0.11).ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // ヘッダー合計
                    VStack(spacing: 8) {
                        Text("現在立て替えている合計額")
                            .font(.subheadline)
                            .foregroundColor(.gray)
                        Text("¥\(Int(viewModel.totalActiveAmount))")
                            .font(.system(size: 36, weight: .black, design: .rounded))
                            .foregroundColor(.orange)
                    }
                    .padding(.vertical, 30)
                    .frame(maxWidth: .infinity)
                    .background(Color.white.opacity(0.02))
                    
                    List {
                        // 未回収リスト
                        Section(header: Text("未回収の立替").foregroundColor(.gray)) {
                            if viewModel.activeIOUs.isEmpty {
                                Text("現在立て替えているお金はありません")
                                    .foregroundColor(.gray)
                                    .padding(.vertical, 10)
                                    .listRowBackground(Color.white.opacity(0.05))
                            } else {
                                ForEach(viewModel.activeIOUs) { iou in
                                    VStack(alignment: .leading, spacing: 12) {
                                        HStack {
                                            VStack(alignment: .leading, spacing: 4) {
                                                Text(iou.title)
                                                    .font(.headline)
                                                    .foregroundColor(.white)
                                                Text(iou.date.formatted(.dateTime.month().day().hour().minute()))
                                                    .font(.caption)
                                                    .foregroundColor(.gray)
                                            }
                                            Spacer()
                                            Text("¥\(Int(iou.amount))")
                                                .font(.title3.bold())
                                                .foregroundColor(.orange)
                                        }
                                        
                                        // メモの表示
                                        if let memo = iou.memo, !memo.isEmpty {
                                            Text(memo)
                                                .font(.subheadline)
                                                .foregroundColor(.white)
                                                .padding(10)
                                                .frame(maxWidth: .infinity, alignment: .leading)
                                                .background(Color.white.opacity(0.1))
                                                .cornerRadius(8)
                                        }
                                        
                                        // アクションエリア
                                        HStack {
                                            if iou.memo == nil || iou.memo!.isEmpty {
                                                Button(action: {
                                                    viewModel.prepareEdit(iou: iou)
                                                }) {
                                                    Label("メモを追加", systemImage: "pencil")
                                                        .font(.caption.bold())
                                                        .foregroundColor(.yellow)
                                                        .padding(.vertical, 4)
                                                }
                                            }
                                            Spacer()
                                            Button(action: {
                                                viewModel.pendingResolveIOU = iou
                                                viewModel.showResolveConfirm = true
                                            }) {
                                                Label("回収完了", systemImage: "checkmark.circle.fill")
                                                    .font(.caption.bold())
                                                    .foregroundColor(.white)
                                                    .padding(.horizontal, 12)
                                                    .padding(.vertical, 8)
                                                    .background(Color.green.opacity(0.8))
                                                    .cornerRadius(8)
                                            }
                                            .buttonStyle(PlainButtonStyle())
                                        }
                                    }
                                    .padding(.vertical, 8)
                                    .contentShape(Rectangle())
                                    .onTapGesture {
                                        viewModel.prepareEdit(iou: iou)
                                    }
                                    .listRowBackground(Color.white.opacity(0.05))
                                    // スワイプアクション（回収済みにする）も一応残す
                                    .swipeActions(edge: .leading, allowsFullSwipe: true) {
                                        Button {
                                            viewModel.pendingResolveIOU = iou
                                            viewModel.showResolveConfirm = true
                                        } label: {
                                            Label("回収済み", systemImage: "checkmark.circle.fill")
                                        }
                                        .tint(.green)
                                    }
                                }
                            }
                        }
                        
                        // 回収済みリスト
                        Section(header: Text("回収済みの履歴").foregroundColor(.gray)) {
                            if viewModel.resolvedIOUs.isEmpty {
                                Text("履歴はありません")
                                    .foregroundColor(.gray)
                                    .padding(.vertical, 10)
                                    .listRowBackground(Color.white.opacity(0.05))
                            } else {
                                ForEach(viewModel.resolvedIOUs) { iou in
                                    HStack {
                                        VStack(alignment: .leading, spacing: 4) {
                                            Text(iou.title)
                                                .font(.headline)
                                                .foregroundColor(.gray)
                                                .strikethrough()
                                            
                                            // 回収日の表示
                                            if let resolvedDate = iou.resolvedDate {
                                                Text("回収日: \(resolvedDate.formatted(.dateTime.month().day()))")
                                                    .font(.caption)
                                                    .foregroundColor(.gray.opacity(0.6))
                                            }
                                        }
                                        Spacer()
                                        Text("¥\(Int(iou.amount))")
                                            .fontWeight(.bold)
                                            .foregroundColor(.gray)
                                    }
                                    .padding(.vertical, 4)
                                    .listRowBackground(Color.white.opacity(0.05))
                                }
                                .onDelete { offsets in
                                    offsets.forEach { index in
                                        let iou = viewModel.resolvedIOUs[index]
                                        viewModel.deleteIOU(iou: iou)
                                    }
                                }
                            }
                        }
                    }
                    .scrollContentBackground(.hidden)
                }
            }
            .navigationTitle("立替リスト")
            .navigationBarTitleDisplayMode(.inline)
            .preferredColorScheme(.dark)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("閉じる") { dismiss() }
                        .foregroundColor(.yellow)
                }
            }
            // 回収済み確認アラート
            .alert("立替の回収", isPresented: $viewModel.showResolveConfirm) {
                Button("キャンセル", role: .cancel) {
                    viewModel.pendingResolveIOU = nil
                }
                Button("回収済みにする") {
                    if let iou = viewModel.pendingResolveIOU {
                        viewModel.resolveIOU(iou: iou)
                    }
                    viewModel.pendingResolveIOU = nil
                }
            } message: {
                if let iou = viewModel.pendingResolveIOU {
                    Text("\(iou.title)の ¥\(Int(iou.amount)) を回収済みにしますか？")
                } else {
                    Text("回収済みにしますか？")
                }
            }
            // 編集用モーダル
            .sheet(isPresented: $viewModel.showEditModal) {
                IOUEditModalView(viewModel: viewModel)
            }
        }
    }
}

// 編集画面の下部シート
struct IOUEditModalView: View {
    @ObservedObject var viewModel: IOUViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var showNumberPad = false
    
    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("立替内容").foregroundColor(.gray)) {
                    TextField("タイトル (誰と飲み等)", text: $viewModel.draftTitle)
                        .foregroundColor(.white)
                    
                    Button(action: {
                        showNumberPad = true
                    }) {
                        HStack {
                            Text("¥").foregroundColor(.gray)
                            Text(viewModel.draftAmount.isEmpty ? "金額を入力" : viewModel.draftAmount)
                                .foregroundColor(viewModel.draftAmount.isEmpty ? .gray : .white)
                            Spacer()
                        }
                    }
                }
                .listRowBackground(Color.white.opacity(0.05))
                
                Section(header: Text("メモ (誰からいくら等)").foregroundColor(.gray)) {
                    TextEditor(text: $viewModel.draftMemo)
                        .frame(height: 100)
                        .foregroundColor(.white)
                        .scrollContentBackground(.hidden)
                        .background(Color.clear)
                }
                .listRowBackground(Color.white.opacity(0.05))
            }
            .navigationTitle("立替の編集")
            .navigationBarTitleDisplayMode(.inline)
            .scrollContentBackground(.hidden)
            .background(Color(red: 0.1, green: 0.1, blue: 0.11).ignoresSafeArea())
            .preferredColorScheme(.dark)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("キャンセル") { dismiss() }
                        .foregroundColor(.gray)
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("保存") {
                        let generator = UIImpactFeedbackGenerator(style: .medium)
                        generator.impactOccurred()
                        viewModel.saveEdit()
                        dismiss()
                    }
                    .foregroundColor(.yellow)
                    .fontWeight(.bold)
                    // タイトルか金額が空の場合は非活性
                    .disabled(viewModel.draftTitle.isEmpty || viewModel.draftAmount.isEmpty)
                }
            }
            .sheet(isPresented: $showNumberPad) {
                NumberPadModalView(textValue: $viewModel.draftAmount, title: "立替金額の入力")
                    .presentationDetents([.fraction(0.85)])
            }
        }
    }
}

#Preview {
    IOURecordView()
}
