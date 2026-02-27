import Foundation
import Combine

class MainViewModel: ObservableObject {
    @Published var remainingBudget: Double = 0.0
    @Published var todaysSpent: Double = 0.0
    // Setup more properties later
}
