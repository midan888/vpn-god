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
            .navigationTitle("Help Center")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
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

            TextField("Search help articles...", text: $searchText)
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

            Text("No results found")
                .vpnTextStyle(.sectionHeader)

            Text("Try a different search term or browse the categories below.")
                .vpnTextStyle(.body, color: .vpnTextSecondary)
                .multilineTextAlignment(.center)
        }
        .padding(.vertical, VPNSpacing.xxl)
    }

    // MARK: - Contact Support

    private var contactSupport: some View {
        VStack(spacing: VPNSpacing.sm) {
            Text("Still need help?")
                .vpnTextStyle(.sectionHeader)

            Text("Reach out to us and we'll get back to you as soon as possible.")
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
                    Text("Contact Support")
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
            title: "Getting Started",
            articles: [
                HelpArticle(
                    question: "How do I connect to a VPN server?",
                    answer: "Tap the power button on the home screen to connect to the selected server. You can change servers by tapping \"Change\" on the server card or visiting the Servers tab."
                ),
                HelpArticle(
                    question: "Which server should I choose?",
                    answer: "For the best speed, choose a server close to your physical location — look for the lowest latency (ms) value. For accessing content from a specific region, pick a server in that country."
                ),
                HelpArticle(
                    question: "Do I need to create an account?",
                    answer: "Yes, an account is required to use VPN Dan. Your account lets us manage your VPN connection securely without storing any browsing activity."
                ),
            ]
        ),
        HelpCategory(
            icon: "network",
            title: "Connection",
            articles: [
                HelpArticle(
                    question: "Why is my connection slow?",
                    answer: "Try switching to a server closer to your location for lower latency. Server load can also affect speed — if a server shows high latency, try another one in the same region."
                ),
                HelpArticle(
                    question: "What does the latency number mean?",
                    answer: "Latency (measured in milliseconds) is the time it takes for data to travel between your device and the server. Lower is better — under 50ms is excellent, 50–100ms is good, and over 100ms may feel slower."
                ),
                HelpArticle(
                    question: "What is Bypass VPN (Split Tunneling)?",
                    answer: "Bypass VPN lets certain apps, websites, or IP addresses skip the VPN tunnel and connect directly. This is useful for services that block VPN traffic, like banking apps, or for local network access."
                ),
                HelpArticle(
                    question: "The VPN keeps disconnecting. What should I do?",
                    answer: "Make sure you have a stable internet connection. Try switching to a different server. If the issue persists, sign out and sign back in to refresh your session."
                ),
            ]
        ),
        HelpCategory(
            icon: "lock.shield.fill",
            title: "Privacy & Security",
            articles: [
                HelpArticle(
                    question: "Does VPN Dan log my activity?",
                    answer: "No. VPN Dan does not log your browsing activity, DNS queries, or traffic data. We only store the minimum information needed to maintain your account and connection."
                ),
                HelpArticle(
                    question: "What VPN protocol does VPN Dan use?",
                    answer: "VPN Dan uses WireGuard, a modern VPN protocol known for its speed, simplicity, and strong cryptography. It's faster and more secure than older protocols like OpenVPN or IPSec."
                ),
                HelpArticle(
                    question: "Is my data encrypted?",
                    answer: "Yes. All traffic between your device and the VPN server is encrypted using state-of-the-art cryptography provided by the WireGuard protocol, including ChaCha20 for encryption and Curve25519 for key exchange."
                ),
            ]
        ),
        HelpCategory(
            icon: "person.fill",
            title: "Account",
            articles: [
                HelpArticle(
                    question: "How do I change my password?",
                    answer: "Password changes are not yet available in the app. This feature is coming soon. If you need to reset your password urgently, please contact support."
                ),
                HelpArticle(
                    question: "Can I use my account on multiple devices?",
                    answer: "Currently, VPN Dan supports one active connection per account. Connecting from a new device will disconnect the previous one."
                ),
                HelpArticle(
                    question: "How do I delete my account?",
                    answer: "To delete your account and all associated data, please contact us at support@vpndan.com. We will process your request and confirm once complete."
                ),
            ]
        ),
    ]
}

// MARK: - Preview

#Preview {
    HelpCenterView()
}
