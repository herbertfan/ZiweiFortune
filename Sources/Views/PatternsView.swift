import SwiftUI

struct PatternsView: View {
    let chart: ZiweiChart

    var body: some View {
        VStack(spacing: 0) {
            if chart.patterns.isEmpty {
                VStack(spacing: 16) {
                    Image(systemName: "star.slash")
                        .font(.system(size: 50))
                        .foregroundColor(.secondary)
                    Text(L("no_patterns"))
                        .font(.headline)
                        .foregroundColor(.secondary)
                    Text(L("no_patterns_desc"))
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Color(.textBackgroundColor))
            } else {
                ScrollView {
                    LazyVStack(spacing: 12) {
                        ForEach(chart.patterns) { pattern in
                            PatternCard(pattern: pattern)
                        }
                    }
                    .padding()
                }
                .background(Color(.textBackgroundColor))
            }
        }
    }
}

struct PatternCard: View {
    let pattern: Pattern

    var levelColor: Color {
        switch pattern.level {
        case .supreme: return .purple
        case .high: return .blue
        case .medium: return .green
        case .special: return .orange
        }
    }

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            VStack(spacing: 4) {
                Text(pattern.level.localizedName)
                    .font(.system(size: 11, weight: .bold))
                    .foregroundColor(.white)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(levelColor)
                    .cornerRadius(4)
            }

            VStack(alignment: .leading, spacing: 6) {
                Text(pattern.displayName)
                    .font(.system(size: 16, weight: .bold))
                Text(pattern.description)
                    .font(.system(size: 13))
                    .foregroundColor(.secondary)
                    .lineSpacing(2)
            }

            Spacer()
        }
        .padding()
        .background(Color.white)
        .cornerRadius(8)
        .shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: 1)
    }
}
