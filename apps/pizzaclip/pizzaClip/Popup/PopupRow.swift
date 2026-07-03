import SwiftUI
import AppKit

private let relativeDateFormatter: RelativeDateTimeFormatter = {
    let f = RelativeDateTimeFormatter()
    f.unitsStyle = .abbreviated
    // 상대 시간("2분 전" vs "2m ago")도 앱 언어 설정을 따르게 한다.
    f.locale = AppLocale.current
    return f
}()

struct PopupRow: View {
    let item: Item
    let selected: Bool
    let slot: Int?

    var body: some View {
        HStack(spacing: 10) {
            leadingGlyph
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 13))
                    .lineLimit(1)
                    .truncationMode(.tail)
                Text(subtitle).font(.system(size: 11)).foregroundColor(AppColors.secondaryLabel).lineLimit(1)
            }
            Spacer()
            if item.pinned {
                Image(systemName: "pin.fill").font(.system(size: 11)).foregroundColor(AppColors.amber)
            }
            if let slot = slot {
                Text("\(slot)")
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundColor(AppColors.amber)
                    .frame(width: 18, height: 18)
                    .overlay(
                        RoundedRectangle(cornerRadius: 5)
                            .stroke(AppColors.amber.opacity(0.6), lineWidth: 1)
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

    @ViewBuilder
    private var leadingGlyph: some View {
        if item.type == "image", let png = item.thumbPng, let nsImage = NSImage(data: png) {
            Image(nsImage: nsImage)
                .resizable()
                .aspectRatio(contentMode: .fill)
                .frame(width: 40, height: 40)
                .clipShape(RoundedRectangle(cornerRadius: 4))
                .overlay(
                    RoundedRectangle(cornerRadius: 4)
                        .stroke(AppColors.separator, lineWidth: 0.5)
                )
        } else {
            Image(systemName: iconName)
                .frame(width: 40, height: 40)
                .foregroundColor(AppColors.secondaryLabel)
        }
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
        case "image":
            // Finder-copied images store the original file path in `text`;
            // show only the file name (full path is too long to read in the
            // row anyway, and is preserved on the pasteboard at paste time).
            // Pure clipboard / screenshot captures (no source path) show a
            // generic label so the user can tell them apart at a glance.
            if let path = item.text, !path.isEmpty {
                return (path as NSString).lastPathComponent
            }
            return L("Capture Image", "캡처 이미지")
        case "file":
            return ((item.text ?? "") as NSString).lastPathComponent
        default:
            return (item.text ?? "").replacingOccurrences(of: "\n", with: " ")
        }
    }
    private var subtitle: String {
        let d = Date(timeIntervalSince1970: Double(item.createdAt) / 1000)
        return relativeDateFormatter.localizedString(for: d, relativeTo: Date())
    }
}
