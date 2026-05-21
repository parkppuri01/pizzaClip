import SwiftUI

struct PopupRow: View {
    let item: Item
    let selected: Bool
    let slot: Int?

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: iconName)
                .frame(width: 22, height: 22)
                .foregroundColor(AppColors.secondaryLabel)
            VStack(alignment: .leading, spacing: 2) {
                Text(title).font(.system(size: 13)).lineLimit(1)
                Text(subtitle).font(.system(size: 11)).foregroundColor(AppColors.secondaryLabel).lineLimit(1)
            }
            Spacer()
            if item.pinned {
                Image(systemName: "pin.fill").font(.system(size: 11)).foregroundColor(AppColors.accent)
            }
            if let slot = slot {
                Text("\(slot)")
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundColor(AppColors.accent)
                    .frame(width: 18, height: 18)
                    .overlay(
                        RoundedRectangle(cornerRadius: 5)
                            .stroke(AppColors.accent.opacity(0.5), lineWidth: 1)
                    )
            }
        }
        .padding(.vertical, 6).padding(.horizontal, 8)
        .background(
            RoundedRectangle(cornerRadius: Theme.rowRadius)
                .fill(selected ? AppColors.accent.opacity(0.18) : .clear)
        )
        .overlay(
            RoundedRectangle(cornerRadius: Theme.rowRadius)
                .strokeBorder(selected ? AppColors.accent.opacity(0.6) : .clear, lineWidth: 1.5)
        )
    }

    private var iconName: String {
        switch item.type {
        case "text": return "doc.text"
        case "image": return "photo"
        case "file": return "folder"
        default: return "doc"
        }
    }
    private var title: String {
        switch item.type {
        case "image": return "Image"
        case "file": return (item.text as NSString?)?.lastPathComponent ?? ""
        default: return (item.text ?? "").replacingOccurrences(of: "\n", with: " ")
        }
    }
    private var subtitle: String {
        let d = Date(timeIntervalSince1970: Double(item.createdAt) / 1000)
        return RelativeDateTimeFormatter().localizedString(for: d, relativeTo: Date())
    }
}
