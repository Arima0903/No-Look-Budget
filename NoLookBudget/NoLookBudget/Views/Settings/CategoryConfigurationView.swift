import SwiftUI
import SwiftData

struct CategoryConfigurationView: View {
    @StateObject private var viewModel = ConfigurationViewModel()
    @Environment(\.dismiss) private var dismiss
    @AppStorage("isPremiumEnabled") private var isPremium = false
    @State private var deletionOffsets: IndexSet? = nil
    @State private var showDeleteConfirmation = false
    @State private var showPaywall = false

    var body: some View {
        List {
            // 注意書きセクション
            Section {
                VStack(alignment: .leading, spacing: 6) {
                    HStack(spacing: 4) {
                        Image(systemName: "info.circle.fill")
                            .font(.caption)
                            .foregroundColor(.blue.opacity(0.8))
                        Text("カテゴリについて")
                            .font(.caption)
                            .fontWeight(.semibold)
                            .foregroundColor(.white.opacity(0.8))
                    }
                    Text("予算カテゴリに設定されなかった分の残り予算は全て「その他」に分類されます。固定カテゴリは削除・名前変更ができません。")
                        .font(.caption2)
                        .foregroundColor(.gray)
                        .fixedSize(horizontal: false, vertical: true)
                    if !isPremium {
                        Text("※ デフォルトの6カテゴリは削除・名前変更ができません。プレミアムプランではカスタムカテゴリを3つまで追加できます。")
                            .font(.caption2)
                            .foregroundColor(.yellow.opacity(0.7))
                            .fixedSize(horizontal: false, vertical: true)
                            .padding(.top, 2)

                        Button(action: {
                            showPaywall = true
                        }) {
                            HStack(spacing: 6) {
                                Image(systemName: "crown.fill")
                                    .font(.caption)
                                    .foregroundColor(.yellow)
                                Text("プレミアムプラン加入はこちらから")
                                    .font(.caption)
                                    .fontWeight(.semibold)
                                    .foregroundColor(.yellow)
                                Spacer()
                                Image(systemName: "chevron.right")
                                    .font(.caption2)
                                    .foregroundColor(.yellow.opacity(0.7))
                            }
                            .padding(.vertical, 8)
                            .padding(.horizontal, 10)
                            .background(Color.yellow.opacity(0.08))
                            .cornerRadius(8)
                        }
                        .padding(.top, 4)
                    }
                }
                .padding(.vertical, 4)
            }
            .listRowBackground(Color.blue.opacity(0.08))

            Section(header: Text("固定カテゴリ").foregroundColor(.gray)) {
                ForEach(viewModel.categories.filter { ConfigurationViewModel.defaultCategoryNames.contains($0.name) }) { category in
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            HStack(spacing: 4) {
                                Text(category.name)
                                    .font(.body.bold())
                                    .foregroundColor(.white)
                                Text("固定")
                                    .font(.system(size: 10, weight: .bold))
                                    .foregroundColor(.white.opacity(0.6))
                                    .padding(.horizontal, 5)
                                    .padding(.vertical, 2)
                                    .background(Color.white.opacity(0.15))
                                    .cornerRadius(4)
                            }
                            Text("予算: ¥\(formatCurrency(category.totalAmount))")
                                .font(.caption)
                                .foregroundColor(.gray)
                        }
                        Spacer()
                        // デフォルトカテゴリは予算額のみ編集可能
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
                    .padding(.vertical, 4)
                }
            }
            .listRowBackground(Color.white.opacity(0.05))

            // カスタムカテゴリセクション（プレミアムのみ）
            if isPremium {
                Section(header: Text("カスタムカテゴリ (最大3個・スワイプで削除)").foregroundColor(.gray)) {
                    let customCategories = viewModel.categories.filter { cat in
                        !ConfigurationViewModel.isDefaultCategory(cat.name)
                    }
                    if customCategories.isEmpty {
                        Text("右上の＋ボタンからカスタムカテゴリを追加できます")
                            .font(.caption)
                            .foregroundColor(.gray)
                            .padding(.vertical, 8)
                    } else {
                        ForEach(customCategories) { category in
                            HStack {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(category.name)
                                        .font(.body.bold())
                                        .foregroundColor(.white)
                                    Text("予算: ¥\(formatCurrency(category.totalAmount))")
                                        .font(.caption)
                                        .foregroundColor(.gray)
                                }
                                Spacer()
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
                            .padding(.vertical, 4)
                        }
                        .onDelete { offsets in
                            // カスタムカテゴリのみ削除可能
                            deletionOffsets = offsets
                            showDeleteConfirmation = true
                        }
                    }
                }
                .listRowBackground(Color.white.opacity(0.05))
            }

            // 「その他」セクション
            Section(header: Text("自動計算").foregroundColor(.gray)) {
                if let otherCat = viewModel.categories.first(where: { $0.name == ConfigurationViewModel.otherCategoryName }) {
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            HStack(spacing: 4) {
                                Text(otherCat.name)
                                    .font(.body.bold())
                                    .foregroundColor(.white)
                                Text("自動")
                                    .font(.system(size: 10, weight: .bold))
                                    .foregroundColor(.white.opacity(0.6))
                                    .padding(.horizontal, 5)
                                    .padding(.vertical, 2)
                                    .background(Color.white.opacity(0.15))
                                    .cornerRadius(4)
                            }
                            Text("予算: ¥\(formatCurrency(otherCat.totalAmount))")
                                .font(.caption)
                                .foregroundColor(.white.opacity(0.5))
                        }
                        Spacer()
                    }
                    .padding(.vertical, 4)
                }
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
        .alert("カテゴリの削除", isPresented: $showDeleteConfirmation) {
            Button("削除する", role: .destructive) {
                if let offsets = deletionOffsets {
                    // カスタムカテゴリリストからのオフセットを元のcategoriesリストに変換
                    let customCategories = viewModel.categories.filter { cat in
                        !ConfigurationViewModel.isDefaultCategory(cat.name)
                    }
                    let realOffsets = IndexSet(offsets.compactMap { offset in
                        guard offset < customCategories.count else { return nil }
                        let targetCat = customCategories[offset]
                        return viewModel.categories.firstIndex(where: { $0.id == targetCat.id })
                    })
                    viewModel.deleteCategories(at: realOffsets)
                }
                deletionOffsets = nil
            }
            Button("キャンセル", role: .cancel) {
                deletionOffsets = nil
            }
        } message: {
            Text("このカテゴリを削除すると、過去の支出データのカテゴリが「不明」になります。本当に削除しますか？")
        }
        .sheet(isPresented: $viewModel.showCategoryModal) {
            CategoryEditModalView(viewModel: viewModel)
        }
        .sheet(isPresented: $showPaywall) {
            PaywallView()
                .preferredColorScheme(.dark)
        }
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
                    if viewModel.isEditingDefaultCategory {
                        // デフォルトカテゴリの場合は名前変更不可
                        HStack {
                            Text(viewModel.draftCategoryName)
                                .foregroundColor(.white.opacity(0.6))
                            Spacer()
                            Text("名前変更不可")
                                .font(.caption2)
                                .foregroundColor(.gray)
                        }
                    } else {
                        VStack(alignment: .leading) {
                            TextField("カテゴリ名 (例: 教育費)", text: $viewModel.draftCategoryName)
                                .foregroundColor(.white)
                            if !viewModel.draftCategoryName.isEmpty && !viewModel.isCategoryNameValid {
                                Text("※ 記号は使用できません（全角・半角英数のみ）")
                                    .font(.caption2)
                                    .foregroundColor(.red)
                            }
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
            .navigationTitle(viewModel.editingCategory == nil ? "カテゴリの追加" : "予算額の編集")
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
                        viewModel.saveCategory()
                        dismiss()
                    }
                    .foregroundColor(.yellow)
                    .fontWeight(.bold)
                    .disabled(viewModel.draftCategoryAmount.isEmpty || (!viewModel.isEditingDefaultCategory && (viewModel.draftCategoryName.isEmpty || !viewModel.isCategoryNameValid)))
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
