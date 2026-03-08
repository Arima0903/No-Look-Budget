import Foundation
import SwiftData
import SwiftUI
import Combine

@MainActor
class IOUViewModel: ObservableObject {
    @Published var activeIOUs: [IOURecord] = []
    @Published var resolvedIOUs: [IOURecord] = []
    @Published var totalActiveAmount: Double = 0
    
    // スワイプ削除（返済済み）確認用状態
    @Published var showResolveConfirm = false
    @Published var pendingResolveIOU: IOURecord? = nil
    
    // 編集用状態
    @Published var showEditModal = false
    @Published var editingIOU: IOURecord? = nil
    @Published var draftTitle: String = ""
    @Published var draftAmount: String = ""
    @Published var draftMemo: String = ""
    
    private let context: ModelContext
    
    init(context: ModelContext? = nil) {
        self.context = context ?? SharedModelContainer.shared.mainContext
        fetchIOUs()
    }
    
    func fetchIOUs() {
        let descriptor = FetchDescriptor<IOURecord>(sortBy: [SortDescriptor(\.date, order: .reverse)])
        let allIOUs = (try? context.fetch(descriptor)) ?? []
        
        self.activeIOUs = allIOUs.filter { !$0.isResolved }
        self.resolvedIOUs = allIOUs.filter { $0.isResolved }
        
        self.totalActiveAmount = activeIOUs.reduce(0) { $0 + $1.amount }
    }
    
    func resolveIOU(iou: IOURecord) {
        iou.isResolved = true
        iou.resolvedDate = Date()
        try? context.save()
        fetchIOUs()
        
        // （仕様: 立替金が返ってきた時は、単にリストから消え、予算には戻さない（最初から引かれていないため））
    }
    
    func deleteIOU(iou: IOURecord) {
        context.delete(iou)
        try? context.save()
        fetchIOUs()
    }
    
    // 編集の準備
    func prepareEdit(iou: IOURecord) {
        self.editingIOU = iou
        self.draftTitle = iou.title
        self.draftAmount = "\(Int(iou.amount))"
        self.draftMemo = iou.memo ?? ""
        self.showEditModal = true
    }
    
    // 保存
    func saveEdit() {
        if let iou = editingIOU {
            iou.title = draftTitle
            iou.memo = draftMemo.isEmpty ? nil : draftMemo
            if let newAmount = Double(draftAmount) {
                iou.amount = newAmount
            }
            try? context.save()
            fetchIOUs()
        }
        showEditModal = false
        editingIOU = nil
    }
}
