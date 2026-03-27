import SwiftUI

// MARK: - Data Model

struct HelpArticle: Identifiable {
    let id = UUID()
    let question: String
    let answer: String
}

struct HelpCategory: Identifiable {
    let id = UUID()
    let icon: String
    let title: String
    let articles: [HelpArticle]
}

// MARK: - Help Center View

struct HelpCenterView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var searchText = ""
    @State private var expandedArticleID: UUID?

    private let categories = HelpCategory.all

    private var filteredCategories: [HelpCategory] {
        guard !searchText.isEmpty else { return categories }
        let query = searchText.lowercased()
        return categories.compactMap { category in
            let matched = category.articles.filter {
                $0.question.lowercased().contains(query)
                || $0.answer.lowercased().contains(query)
            }
            guard !matched.isEmpty else { return nil }
            return HelpCategory(icon: category.icon, title: category.title, articles: matched)
        }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color.vpnBackground.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: VPNSpacing.lg) {
                        searchBar

                        if filteredCategories.isEmpty {
                            emptyState
                        } else {
                            ForEach(filteredCategories) { category in
                                categorySection(category)
                            }
                        }

                        contactSupport
                    }
                    .padding(.horizontal, VPNSpacing.md)
                    .padding(.top, VPNSpacing.md)
                    .padding(.bottom, VPNSpacing.xxl)
                }
                .scrollIndicators(.hidden)
            }
            .navigationTitle(L10n.HelpCenter.title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(L10n.Common.done) { dismiss() }
                        .foregroundStyle(Color.vpnPrimary)
                }
            }
        }
    }

    // MARK: - Search Bar

    private var searchBar: some View {
        HStack(spacing: VPNSpacing.sm) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 14))
                .foregroundStyle(Color.vpnTextTertiary)

            TextField(L10n.HelpCenter.searchPlaceholder, text: $searchText)
                .vpnTextStyle(.body)
                .autocorrectionDisabled()
                .textInputAutocapitalization(.never)

            if !searchText.isEmpty {
                Button {
                    searchText = ""
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 14))
                        .foregroundStyle(Color.vpnTextTertiary)
                }
            }
        }
        .padding(.horizontal, VPNSpacing.md)
        .padding(.vertical, VPNSpacing.sm + VPNSpacing.xs)
        .background(
            RoundedRectangle(cornerRadius: VPNRadius.textField)
                .fill(.ultraThinMaterial)
        )
        .overlay(
            RoundedRectangle(cornerRadius: VPNRadius.textField)
                .stroke(Color.vpnBorder.opacity(0.5), lineWidth: 1)
        )
    }

    // MARK: - Category Section

    private func categorySection(_ category: HelpCategory) -> some View {
        VStack(alignment: .leading, spacing: VPNSpacing.sm) {
            HStack(spacing: VPNSpacing.sm) {
                Image(systemName: category.icon)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(Color.vpnTextTertiary)

                Text(category.title.uppercased())
                    .vpnTextStyle(.statusBadge, color: .vpnTextTertiary)
            }
            .padding(.horizontal, VPNSpacing.xs)

            VStack(spacing: 0) {
                ForEach(Array(category.articles.enumerated()), id: \.element.id) { index, article in
                    if index > 0 {
                        Divider()
                            .background(Color.vpnBorder.opacity(0.5))
                            .padding(.leading, VPNSpacing.md)
                    }

                    articleRow(article)
                }
            }
            .background(
                RoundedRectangle(cornerRadius: VPNRadius.card)
                    .fill(.ultraThinMaterial)
            )
            .overlay(
                RoundedRectangle(cornerRadius: VPNRadius.card)
                    .stroke(Color.vpnBorder.opacity(0.5), lineWidth: 1)
            )
        }
    }

    // MARK: - Article Row

    private func articleRow(_ article: HelpArticle) -> some View {
        let isExpanded = expandedArticleID == article.id

        return Button {
            withAnimation(.easeInOut(duration: 0.25)) {
                expandedArticleID = isExpanded ? nil : article.id
            }
        } label: {
            VStack(alignment: .leading, spacing: 0) {
                HStack(spacing: VPNSpacing.md) {
                    Text(article.question)
                        .vpnTextStyle(.body)
                        .multilineTextAlignment(.leading)

                    Spacer()

                    Image(systemName: "chevron.down")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(Color.vpnTextTertiary)
                        .rotationEffect(.degrees(isExpanded ? 180 : 0))
                }
                .padding(.horizontal, VPNSpacing.md)
                .padding(.vertical, VPNSpacing.md)

                if isExpanded {
                    Text(article.answer)
                        .vpnTextStyle(.body, color: .vpnTextSecondary)
                        .multilineTextAlignment(.leading)
                        .padding(.horizontal, VPNSpacing.md)
                        .padding(.bottom, VPNSpacing.md)
                        .transition(.opacity.combined(with: .move(edge: .top)))
                }
            }
        }
    }

    // MARK: - Empty State

    private var emptyState: some View {
        VStack(spacing: VPNSpacing.md) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 32))
                .foregroundStyle(Color.vpnTextTertiary)

            Text(L10n.HelpCenter.noResults)
                .vpnTextStyle(.sectionHeader)

            Text(L10n.HelpCenter.noResultsHint)
                .vpnTextStyle(.body, color: .vpnTextSecondary)
                .multilineTextAlignment(.center)
        }
        .padding(.vertical, VPNSpacing.xxl)
    }

    // MARK: - Contact Support

    private var contactSupport: some View {
        VStack(spacing: VPNSpacing.sm) {
            Text(L10n.HelpCenter.stillNeedHelp)
                .vpnTextStyle(.sectionHeader)

            Text(L10n.HelpCenter.contactPrompt)
                .vpnTextStyle(.body, color: .vpnTextSecondary)
                .multilineTextAlignment(.center)

            Button {
                if let url = URL(string: "mailto:support@vpndan.com") {
                    UIApplication.shared.open(url)
                }
            } label: {
                HStack(spacing: VPNSpacing.sm) {
                    Image(systemName: "envelope.fill")
                        .font(.system(size: 14))
                    Text(L10n.HelpCenter.contactSupport)
                        .vpnTextStyle(.buttonText, color: .white)
                }
                .frame(maxWidth: .infinity)
                .frame(height: 52)
                .background(Color.vpnPrimaryGradient)
                .clipShape(RoundedRectangle(cornerRadius: VPNRadius.button))
            }
        }
        .padding(.top, VPNSpacing.md)
    }
}

// MARK: - Help Content

extension HelpCategory {
    static let all: [HelpCategory] = [
        HelpCategory(
            icon: "bolt.fill",
            title: L10n.HelpCenter.catGettingStarted,
            articles: [
                HelpArticle(question: L10n.HelpCenter.helpConnectQ, answer: L10n.HelpCenter.helpConnectA),
                HelpArticle(question: L10n.HelpCenter.helpChooseServerQ, answer: L10n.HelpCenter.helpChooseServerA),
                HelpArticle(question: L10n.HelpCenter.helpAccountQ, answer: L10n.HelpCenter.helpAccountA),
            ]
        ),
        HelpCategory(
            icon: "network",
            title: L10n.HelpCenter.catConnection,
            articles: [
                HelpArticle(question: L10n.HelpCenter.helpSlowQ, answer: L10n.HelpCenter.helpSlowA),
                HelpArticle(question: L10n.HelpCenter.helpLatencyQ, answer: L10n.HelpCenter.helpLatencyA),
                HelpArticle(question: L10n.HelpCenter.helpBypassQ, answer: L10n.HelpCenter.helpBypassA),
                HelpArticle(question: L10n.HelpCenter.helpDisconnectQ, answer: L10n.HelpCenter.helpDisconnectA),
            ]
        ),
        HelpCategory(
            icon: "lock.shield.fill",
            title: L10n.HelpCenter.catPrivacy,
            articles: [
                HelpArticle(question: L10n.HelpCenter.helpLogsQ, answer: L10n.HelpCenter.helpLogsA),
                HelpArticle(question: L10n.HelpCenter.helpProtocolQ, answer: L10n.HelpCenter.helpProtocolA),
                HelpArticle(question: L10n.HelpCenter.helpEncryptedQ, answer: L10n.HelpCenter.helpEncryptedA),
            ]
        ),
        HelpCategory(
            icon: "person.fill",
            title: L10n.HelpCenter.catAccount,
            articles: [
                HelpArticle(question: L10n.HelpCenter.helpPasswordQ, answer: L10n.HelpCenter.helpPasswordA),
                HelpArticle(question: L10n.HelpCenter.helpMultiDeviceQ, answer: L10n.HelpCenter.helpMultiDeviceA),
                HelpArticle(question: L10n.HelpCenter.helpDeleteQ, answer: L10n.HelpCenter.helpDeleteA),
            ]
        ),
    ]
}

// MARK: - Preview

#Preview {
    HelpCenterView()
}
