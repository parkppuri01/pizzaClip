import SwiftUI

struct PopupRow: View {
    let item: Item
    let selected: Bool

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: iconName)
                .frame(width: 22, height: 22)
                .foregroundColor(.secondary)
            VStack(alignment: .leading, spacing: 2) {
                Text(title).font(.system(size: 13)).lineLimit(1)
                Text(subtitle).font(.system(size: 11)).foregroundColor(.secondary).lineLimit(1)
            }
            Spacer()
            if item.pinned {
                Image(systemName: "pin.fill").font(.system(size: 11)).foregroundColor(.orange)
            }
        }
        .padding(.vertical, 6).padding(.horizontal, 8)
        .background(selected ? Color.accentColor.opacity(0.18) : .clear)
        .clipShape(RoundedRectangle(cornerRadius: 8))
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
