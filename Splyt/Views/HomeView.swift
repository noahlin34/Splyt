import SwiftUI
import SwiftData

// MARK: - HomeView

struct HomeView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Receipt.createdAt, order: .reverse) private var receipts: [Receipt]
    @Query(filter: #Predicate<Person> { $0.isCurrentUser }) private var currentUsers: [Person]

    @State private var showingScanView = false
    @State private var showingPersonManager = false
    @State private var showingAllReceipts = false
    @State private var pendingReceipt: Receipt?
    @State private var pendingImage: UIImage?
    @State private var navigateToReceipt = false

    private var currentUser: Person? { currentUsers.first }
    private var recentReceipts: [Receipt] { Array(receipts.prefix(3)) }

    private var amountOwedToYou: Double {
        receipts.reduce(0) { sum, receipt in
            PersonSplit.calculate(for: receipt)
                .filter { $0.person.persistentModelID != currentUser?.persistentModelID }
                .reduce(sum) { $0 + $1.total }
        }
    }

    private var amountYouOwe: Double {
        guard let me = currentUser else { return 0 }
        return receipts.reduce(0) { sum, receipt in
            let mySplit = PersonSplit.calculate(for: receipt)
                .first { $0.person.persistentModelID == me.persistentModelID }
            return sum + (mySplit?.total ?? 0)
        }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 8) {
                    balanceSummaryCards
                    scanButton
                    quickActionsGrid
                    recentActivitySection
                }
                .padding(.top, 8)
            }
            .background(Color.splytBackground)
            .toolbar(.hidden, for: .navigationBar)
            .navigationDestination(for: Receipt.self) { receipt in
                ReceiptDetailView(receipt: receipt)
            }
            .navigationDestination(isPresented: $navigateToReceipt) {
                if let receipt = pendingReceipt, let image = pendingImage {
                    ReceiptDetailView(receipt: receipt, capturedImage: image)
                }
            }
        }
        .sheet(isPresented: $showingScanView) {
            ScanView { image in handleScannedImage(image) }
        }
        .sheet(isPresented: $showingPersonManager) {
            PersonManagerView()
        }
        .sheet(isPresented: $showingAllReceipts) {
            ReceiptListView()
        }
    }

    // MARK: - Balance Summary Cards

    private var balanceSummaryCards: some View {
        HStack(spacing: 16) {
            BalanceCard(
                label: "You are owed",
                amount: amountOwedToYou,
                iconName: "arrow.down",
                iconColor: .splytGreen,
                changeText: "+5.2%",
                changeColor: .splytGreen
            )
            BalanceCard(
                label: "Your share",
                amount: amountYouOwe,
                iconName: "arrow.up",
                iconColor: .splytRed,
                changeText: "-2.1%",
                changeColor: .splytRed
            )
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 16)
        .frame(height: 170)
    }

    // MARK: - Scan Button

    private var scanButton: some View {
        Button { showingScanView = true } label: {
            HStack(spacing: 12) {
                Image(systemName: "qrcode.viewfinder")
                    .font(.system(size: 20, weight: .bold))
                Text("Scan New Receipt")
                    .font(.system(size: 18, weight: .bold))
            }
            .foregroundStyle(Color.splytDark)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(
                RoundedRectangle(cornerRadius: 24)
                    .fill(Color.splytGreen)
                    .shadow(color: .black.opacity(0.1), radius: 15, x: 0, y: 10)
                    .shadow(color: .black.opacity(0.1), radius: 6, x: 0, y: 4)
            )
        }
        .padding(.horizontal, 16)
    }

    // MARK: - Quick Actions

    private var quickActionsGrid: some View {
        HStack(spacing: 0) {
            QuickActionButton(icon: "person.badge.plus", label: "New Group") {
                showingPersonManager = true
            }
            QuickActionButton(icon: "creditcard.fill", label: "Settle Up") {}
            QuickActionButton(icon: "clock.fill", label: "Pending") {}
            QuickActionButton(icon: "square.grid.2x2.fill", label: "More") {}
        }
        .padding(.horizontal, 16)
    }

    // MARK: - Recent Activity

    private var recentActivitySection: some View {
        VStack(spacing: 16) {
            HStack {
                Text("Recent Activity")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundStyle(Color.splytDark)
                Spacer()
                Button { showingAllReceipts = true } label: {
                    Text("View All")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(Color.splytGreen)
                }
            }

            if recentReceipts.isEmpty {
                Text("No receipts yet. Scan a receipt to get started!")
                    .font(.system(size: 14))
                    .foregroundStyle(Color.splytMuted)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 32)
            } else {
                VStack(spacing: 16) {
                    ForEach(recentReceipts) { receipt in
                        NavigationLink(value: receipt) {
                            ActivityRow(receipt: receipt, currentUser: currentUser)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.top, 16)
        .padding(.bottom, 80)
    }

    // MARK: - Helpers

    private func handleScannedImage(_ image: UIImage) {
        let receipt = Receipt()
        receipt.imageData = image.jpegData(compressionQuality: 0.8)
        modelContext.insert(receipt)
        pendingReceipt = receipt
        pendingImage = image
        navigateToReceipt = true
    }
}

// MARK: - BalanceCard

private struct BalanceCard: View {
    let label: String
    let amount: Double
    let iconName: String
    let iconColor: Color
    let changeText: String
    let changeColor: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 8) {
                Image(systemName: iconName)
                    .font(.system(size: 9, weight: .bold))
                    .foregroundStyle(iconColor)
                Text(label)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(Color.splytSecondary)
            }

            Text(amount, format: .currency(code: "USD"))
                .font(.system(size: 24, weight: .bold))
                .foregroundStyle(Color.splytDark)
                .frame(maxWidth: .infinity, alignment: .leading)
                .minimumScaleFactor(0.7)

            HStack(spacing: 4) {
                Text(changeText)
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(changeColor)
                Text("this month")
                    .font(.system(size: 12))
                    .foregroundStyle(Color.splytMuted)
            }
        }
        .padding(25)
        .frame(maxWidth: .infinity, alignment: .leading)
        .frame(maxHeight: .infinity)
        .background(.white)
        .clipShape(RoundedRectangle(cornerRadius: 24))
        .overlay(
            RoundedRectangle(cornerRadius: 24)
                .stroke(Color.splytBorder, lineWidth: 1)
        )
        .shadow(color: .black.opacity(0.05), radius: 1, x: 0, y: 1)
    }
}

// MARK: - QuickActionButton

private struct QuickActionButton: View {
    let icon: String
    let label: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                ZStack {
                    Circle()
                        .fill(Color.splytGreen.opacity(0.1))
                        .frame(width: 48, height: 48)
                    Image(systemName: icon)
                        .font(.system(size: 18, weight: .medium))
                        .foregroundStyle(Color.splytGreen)
                }
                Text(label)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(Color.splytDark)
                    .multilineTextAlignment(.center)
            }
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - ActivityRow

private struct ActivityRow: View {
    let receipt: Receipt
    let currentUser: Person?

    private var splits: [PersonSplit] { PersonSplit.calculate(for: receipt) }

    private var othersTotal: Double {
        splits
            .filter { $0.person.persistentModelID != currentUser?.persistentModelID }
            .reduce(0) { $0 + $1.total }
    }

    private var myTotal: Double {
        guard let me = currentUser else { return 0 }
        return splits.first { $0.person.persistentModelID == me.persistentModelID }?.total ?? 0
    }

    private var hasUnassigned: Bool { receipt.lineItems.contains { $0.assignedPerson == nil } }

    private var peopleCount: Int {
        Set(receipt.lineItems.compactMap { $0.assignedPerson?.name }).count
    }

    private var subtitle: String {
        let dateStr = receipt.createdAt.formatted(.relative(presentation: .named))
        if peopleCount > 0 {
            return "Split with \(peopleCount) \(peopleCount == 1 ? "person" : "people") • \(dateStr)"
        }
        return dateStr
    }

    var body: some View {
        HStack(spacing: 16) {
            VStack(alignment: .leading, spacing: 2) {
                Text(receipt.restaurantName ?? "Receipt")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundStyle(Color.splytDark)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)
                Text(subtitle)
                    .font(.system(size: 12))
                    .foregroundStyle(Color.splytSecondary)
                    .lineLimit(2)
            }

            Spacer()

            amountColumn
        }
        .padding(17)
        .background(.white)
        .clipShape(RoundedRectangle(cornerRadius: 24))
        .overlay(
            RoundedRectangle(cornerRadius: 24)
                .stroke(Color.splytBorder, lineWidth: 1)
        )
    }

    @ViewBuilder
    private var amountColumn: some View {
        if currentUser != nil {
            if othersTotal > 0 && myTotal > 0 {
                // Mixed: show what others owe you, plus a smaller "you owe" line
                VStack(alignment: .trailing, spacing: 2) {
                    Text(othersTotal, format: .currency(code: "USD"))
                        .font(.system(size: 16, weight: .bold))
                        .foregroundStyle(Color.splytGreen)
                    Text("OWED TO YOU")
                        .font(.system(size: 10))
                        .foregroundStyle(Color.splytMuted)
                        .tracking(0.5)
                    Text("-\(myTotal.formatted(.currency(code: "USD")))")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(Color.splytRed)
                    Text("YOU OWE")
                        .font(.system(size: 9))
                        .foregroundStyle(Color.splytMuted)
                        .tracking(0.5)
                }
            } else if othersTotal > 0 {
                VStack(alignment: .trailing, spacing: 2) {
                    Text(othersTotal, format: .currency(code: "USD"))
                        .font(.system(size: 16, weight: .bold))
                        .foregroundStyle(Color.splytGreen)
                    Text(hasUnassigned ? "PENDING" : "OWED TO YOU")
                        .font(.system(size: 10))
                        .foregroundStyle(Color.splytMuted)
                        .tracking(0.5)
                }
            } else if myTotal > 0 {
                VStack(alignment: .trailing, spacing: 2) {
                    Text(myTotal, format: .currency(code: "USD"))
                        .font(.system(size: 16, weight: .bold))
                        .foregroundStyle(Color.splytRed)
                    Text("YOU OWE")
                        .font(.system(size: 10))
                        .foregroundStyle(Color.splytMuted)
                        .tracking(0.5)
                }
            } else {
                fallbackAmount
            }
        } else {
            fallbackAmount
        }
    }

    // Used when no current user is set or no splits exist
    private var fallbackAmount: some View {
        let total = splits.reduce(0) { $0 + $1.total }
        let hasAny = !splits.isEmpty
        return VStack(alignment: .trailing, spacing: 2) {
            Text(hasAny ? total : receipt.total, format: .currency(code: "USD"))
                .font(.system(size: 16, weight: .bold))
                .foregroundStyle(hasAny ? Color.splytGreen : Color.splytDark)
            Text(hasAny ? (hasUnassigned ? "PENDING" : "OWED TO YOU") : "UNSPLIT")
                .font(.system(size: 10))
                .foregroundStyle(Color.splytMuted)
                .tracking(0.5)
        }
    }
}
