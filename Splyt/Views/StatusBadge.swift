import SwiftUI

// MARK: - ReceiptStatus

enum ReceiptStatus: Equatable {
    case settled
    case pending
    case notSent
    case draft

    static func of(_ receipt: Receipt) -> ReceiptStatus {
        guard !receipt.lineItems.isEmpty, receipt.restaurantName != nil else {
            return .draft
        }
        let hasUnassigned = receipt.lineItems.contains { $0.assignedPerson == nil }
        let hasAssigned   = receipt.lineItems.contains { $0.assignedPerson != nil }
        if !hasUnassigned { return .settled }
        if hasAssigned    { return .pending }
        return .notSent
    }

    var label: String {
        switch self {
        case .settled: return "SETTLED"
        case .pending: return "PENDING"
        case .notSent: return "NOT SENT"
        case .draft:   return "DRAFT"
        }
    }

    var dotColor: Color {
        switch self {
        case .settled: return .splytGreen
        case .pending: return Color(hex: "f97316") ?? .orange
        case .notSent: return Color(hex: "ff5f57") ?? .red
        case .draft:   return .splytMuted
        }
    }

    var textColor: Color {
        switch self {
        case .settled: return .splytGreen
        case .pending: return Color(hex: "ea580c") ?? .orange
        case .notSent: return Color(hex: "ff5f57") ?? .red
        case .draft:   return .splytMuted
        }
    }

    var badgeBackground: Color {
        switch self {
        case .settled: return Color.splytGreen.opacity(0.2)
        case .pending: return Color(hex: "ffedd5") ?? Color.orange.opacity(0.15)
        case .notSent: return Color(hex: "ff383c")?.opacity(0.5) ?? Color.red.opacity(0.3)
        case .draft:   return Color.splytMuted.opacity(0.15)
        }
    }
}

// MARK: - StatusBadge

struct StatusBadge: View {
    let status: ReceiptStatus

    var body: some View {
        HStack(spacing: 4) {
            Circle()
                .fill(status.dotColor)
                .frame(width: 6, height: 6)
            Text(status.label)
                .font(.system(size: 10, weight: .bold))
                .foregroundStyle(status.textColor)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 2)
        .background(status.badgeBackground)
        .clipShape(Capsule())
    }
}
