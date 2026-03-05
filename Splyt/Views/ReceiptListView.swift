import SwiftUI
import SwiftData

struct ReceiptListView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Receipt.createdAt, order: .reverse) private var receipts: [Receipt]

    @State private var showingScanView = false
    @State private var showingPersonManager = false
    @State private var pendingReceipt: Receipt?
    @State private var pendingImage: UIImage?
    @State private var navigateToReceipt = false
    @State private var activeFilter: HistoryFilter = .all

    enum HistoryFilter: String, CaseIterable {
        case all     = "All Splits"
        case settled = "Settled"
        case pending = "Pending"
        case drafts  = "Drafts"
    }

    var body: some View {
        NavigationStack {
            ZStack(alignment: .bottomTrailing) {
                VStack(spacing: 0) {
                    header
                    filterTabs
                    Divider().background(Color.splytGreen.opacity(0.1))
                    scrollContent
                }
                .background(Color.splytBackground)
                .ignoresSafeArea(edges: .top)

                fab
            }
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
    }

    // MARK: - Header

    private var header: some View {
        HStack {
            HStack(spacing: 8) {
                ZStack {
                    RoundedRectangle(cornerRadius: 10)
                        .fill(Color.splytGreen.opacity(0.15))
                        .frame(width: 34, height: 36)
                    Image(systemName: "arrow.left.arrow.right")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundStyle(Color.splytGreen)
                }
                Text("History")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundStyle(Color.splytDark)
                    .tracking(-0.5)
            }
            Spacer()
            Button {} label: {
                Image(systemName: "magnifyingglass")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundStyle(Color.splytDark)
                    .padding(8)
            }
        }
        .padding(16)
        .padding(.top, 44) // status bar clearance
        .background(
            Color(hex: "f6f8f7")!.opacity(0.8)
                .background(.ultraThinMaterial)
        )
        .overlay(alignment: .bottom) {
            Rectangle()
                .fill(Color.splytGreen.opacity(0.1))
                .frame(height: 1)
        }
    }

    // MARK: - Filter Tabs

    private var filterTabs: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 24) {
                ForEach(HistoryFilter.allCases, id: \.self) { filter in
                    Button { activeFilter = filter } label: {
                        VStack(spacing: 0) {
                            Text(filter.rawValue)
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundStyle(activeFilter == filter ? Color.splytGreen : Color.splytSecondary)
                                .padding(.top, 12)
                                .padding(.bottom, 14)
                        }
                        .overlay(alignment: .bottom) {
                            Rectangle()
                                .fill(activeFilter == filter ? Color.splytGreen : Color.clear)
                                .frame(height: 2)
                        }
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 16)
        }
        .frame(height: 46)
        .background(
            Color(hex: "f6f8f7")!.opacity(0.8)
                .background(.ultraThinMaterial)
        )
    }

    // MARK: - Scroll Content

    private var scrollContent: some View {
        ScrollView {
            if groupedReceipts.isEmpty {
                emptyState
            } else {
                VStack(spacing: 24) {
                    ForEach(groupedReceipts, id: \.month) { group in
                        monthSection(group)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.top, 16)
                .padding(.bottom, 100)
            }
        }
    }

    private var emptyState: some View {
        VStack(spacing: 12) {
            Image(systemName: "clock")
                .font(.system(size: 48))
                .foregroundStyle(Color.splytMuted)
            Text("No receipts yet")
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(Color.splytDark)
            Text("Tap + to scan your first bill.")
                .font(.system(size: 14))
                .foregroundStyle(Color.splytMuted)
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 80)
    }

    // MARK: - Month Section

    private func monthSection(_ group: (month: String, receipts: [Receipt])) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(group.month.uppercased())
                .font(.system(size: 12, weight: .bold))
                .foregroundStyle(Color.splytMuted)
                .tracking(1.2)
                .padding(.horizontal, 4)

            VStack(spacing: 12) {
                ForEach(group.receipts) { receipt in
                    historyItem(for: receipt)
                }
            }
        }
    }

    // MARK: - History Item

    private func historyItem(for receipt: Receipt) -> some View {
        NavigationLink(value: receipt) {
            HStack(spacing: 16) {
                ZStack {
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color.splytGreen.opacity(0.1))
                        .frame(width: 48, height: 48)
                    Image(systemName: "fork.knife")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundStyle(Color.splytGreen)
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text(receipt.restaurantName ?? "Receipt")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundStyle(Color.splytDark)
                        .lineLimit(1)
                    Text(subtitleText(for: receipt))
                        .font(.system(size: 12))
                        .foregroundStyle(Color.splytSecondary)
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 4) {
                    Text(receipt.total, format: .currency(code: "USD"))
                        .font(.system(size: 16, weight: .bold))
                        .foregroundStyle(Color.splytDark)
                    StatusBadge(status: ReceiptStatus.of(receipt))
                }
            }
            .padding(17)
            .background(.white)
            .clipShape(RoundedRectangle(cornerRadius: 24))
            .overlay(
                RoundedRectangle(cornerRadius: 24)
                    .stroke(Color.splytGreen.opacity(0.05), lineWidth: 1)
            )
            .shadow(color: .black.opacity(0.05), radius: 1, x: 0, y: 1)
        }
        .buttonStyle(.plain)
    }

    // MARK: - FAB

    private var fab: some View {
        Button { showingScanView = true } label: {
            ZStack {
                Circle()
                    .fill(Color.splytGreen)
                    .frame(width: 56, height: 56)
                    .shadow(color: Color.splytGreen.opacity(0.2), radius: 15, x: 0, y: 10)
                    .shadow(color: Color.splytGreen.opacity(0.2), radius: 6, x: 0, y: 4)
                Image(systemName: "plus")
                    .font(.system(size: 22, weight: .bold))
                    .foregroundStyle(Color.splytDark)
            }
        }
        .padding(.trailing, 24)
        .padding(.bottom, 96)
    }

    // MARK: - Computed Properties

    private var filteredReceipts: [Receipt] {
        switch activeFilter {
        case .all:     return receipts
        case .settled: return receipts.filter { ReceiptStatus.of($0) == .settled }
        case .pending: return receipts.filter { ReceiptStatus.of($0) == .pending }
        case .drafts:  return receipts.filter { ReceiptStatus.of($0) == .draft }
        }
    }

    private var groupedReceipts: [(month: String, receipts: [Receipt])] {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"
        var groups: [(String, [Receipt])] = []
        var index: [String: Int] = [:]
        for receipt in filteredReceipts {
            let key = formatter.string(from: receipt.createdAt)
            if let i = index[key] {
                groups[i].1.append(receipt)
            } else {
                index[key] = groups.count
                groups.append((key, [receipt]))
            }
        }
        return groups.map { (month: $0.0, receipts: $0.1) }
    }

    private func subtitleText(for receipt: Receipt) -> String {
        let dateStr = receipt.createdAt.formatted(Date.FormatStyle().month(.abbreviated).day())
        let peopleCount = Set(receipt.lineItems.compactMap { $0.assignedPerson?.name }).count
        if peopleCount > 0 {
            return "\(dateStr) • \(peopleCount) \(peopleCount == 1 ? "person" : "people")"
        }
        return dateStr
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
