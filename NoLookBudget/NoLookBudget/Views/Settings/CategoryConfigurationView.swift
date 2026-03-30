import SwiftUI
import SwiftData

struct CategoryConfigurationView: View {
    @StateObject private var viewModel = ConfigurationViewModel()
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        List {
            Section(header: Text("変動費カテゴリ (スワイプで削除、長押しで並び替え)").foregroundColor(.gray)) {
                ForEach(viewModel.categories) { category in
                    let isOther = category.name == ConfigurationViewModel.otherCategoryName
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            HStack(spacing: 4) {
                                Text(category.name)
                                    .font(.body.bold())
                                    .foregroundColor(.white)
                                if isOther {
                                    Text("自動")
                                        .font(.system(size: 10, weight: .bold))
                                        .foregroundColor(.white.opacity(0.6))
                                        .padding(.horizontal, 5)
                                        .padding(.vertical, 2)
                                        .background(Color.white.opacity(0.15))
                                        .cornerRadius(4)
                                }
                            }
                            Text("予算: ¥\(formatCurrency(category.totalAmount))")
                                .font(.caption)
                                .foregroundColor(isOther ? .white.opacity(0.5) : .gray)
                        }
                        Spacer()
                        if !isOther {
                            Button(action: {
                                let generator = UIImpactFeedbackGenerator(style: .light)
                                generator.impactOccurred()
                                viewModel.prepareEditingCategory(category)
                            }) {
                                Image(systemName: "pencil.circle.fill")
                                    .foregroundColor(.yellow)
                                    .font(.system(size: 22))
                            }
                        }
                    }
                    .padding(.vertical, 4)
                }
                .onDelete(perform: viewModel.deleteCategories)
                .onMove(perform: viewModel.moveCategories)
            }
            .listRowBackground(Color.white.opacity(0.05))
        }
        .navigationTitle("カテゴリの編集")
        .navigationBarTitleDisplayMode(.inline)
        .scrollContentBackground(.hidden)
        .background(Color(red: 0.1, green: 0.1, blue: 0.11).ignoresSafeArea())
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: {
                    let generator = UIImpactFeedbackGenerator(style: .light)
                    generator.impactOccurred()
                    viewModel.prepareAddingCategory()
                }) {
                    Image(systemName: "plus")
                        .fontWeight(.bold)
                        .foregroundColor(viewModel.canAddCategory ? .yellow : .gray)
                }
                .disabled(!viewModel.canAddCategory)
            }
        }
        .sheet(isPresented: $viewModel.showCategoryModal) {
            CategoryEditModalView(viewModel: viewModel)
        }
        // Realm/SwiftDataの同期を手動・自動で行うためのフック等
        .onAppear {
            viewModel.fetchData()
        }
    }
}

struct CategoryEditModalView: View {
    @ObservedObject var viewModel: ConfigurationViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var showNumberPad = false
    
    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("カテゴリ情報").foregroundColor(.gray)) {
                    VStack(alignment: .leading) {
                        TextField("カテゴリ名 (例: 食費)", text: $viewModel.draftCategoryName)
                            .foregroundColor(.white)
                        if !viewModel.draftCategoryName.isEmpty && !viewModel.isCategoryNameValid {
                            Text("※ 記号は使用できません（全角・半角英数のみ）")
                                .font(.caption2)
                                .foregroundColor(.red)
                        }
                    }
                    
                    Button(action: {
                        showNumberPad = true
                    }) {
                        HStack {
                            Text("¥").foregroundColor(.gray)
                            Text(viewModel.draftCategoryAmount.isEmpty ? "金額を設定" : viewModel.draftCategoryAmount)
                                .foregroundColor(viewModel.draftCategoryAmount.isEmpty ? .gray : .white)
                            Spacer()
                        }
                    }
                }
                .listRowBackground(Color.white.opacity(0.05))
            }
            .navigationTitle(viewModel.editingCategory == nil ? "カテゴリの追加" : "カテゴリの編集")
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
                    Button("一時保存") {
                        let generator = UIImpactFeedbackGenerator(style: .medium)
                        generator.impactOccurred()
                        viewModel.saveCategory()
                        dismiss()
                    }
                    .foregroundColor(.yellow)
                    .fontWeight(.bold)
                    // 名前か金額が空、または名前が無効な場合は非活性にする
                    .disabled(viewModel.draftCategoryName.isEmpty || viewModel.draftCategoryAmount.isEmpty || !viewModel.isCategoryNameValid)
                }
            }
            .sheet(isPresented: $showNumberPad) {
                NumberPadModalView(textValue: $viewModel.draftCategoryAmount, title: "カテゴリ予算の入力")
                    .presentationDetents([.fraction(0.85)])
                    .preferredColorScheme(.dark)
            }
        }
    }
}

#Preview {
    CategoryConfigurationView()
        .preferredColorScheme(.dark)
}
