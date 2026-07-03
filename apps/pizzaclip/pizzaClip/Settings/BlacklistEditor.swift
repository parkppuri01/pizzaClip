import SwiftUI
import AppKit
import UniformTypeIdentifiers

/// 개인정보 탭의 "기록하지 않을 앱" 편집기.
///
/// 저장 형식은 기존과 동일하게 쉼표로 구분된 **번들 식별자 문자열**이다
/// (ClipboardMonitor 가 이 형식을 읽음). 다만 사용자에게는 번들 ID 대신
/// **앱 아이콘 + 이름**으로 보여주고, "앱 추가…" 버튼으로 /Applications 에서
/// 앱을 골라 추가하게 해 비개발자도 쉽게 다루도록 한다.
struct BlacklistEditor: View {
    @Binding var csv: String

    private var ids: [String] {
        csv.split(separator: ",")
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            if ids.isEmpty {
                Text(L("No apps added yet.", "아직 추가한 앱이 없어요."))
                    .font(.callout)
                    .foregroundStyle(.secondary)
                    .padding(.vertical, 4)
            } else {
                ForEach(ids, id: \.self) { id in
                    HStack(spacing: 10) {
                        appIcon(for: id)
                            .resizable()
                            .frame(width: 24, height: 24)
                        VStack(alignment: .leading, spacing: 1) {
                            Text(appName(for: id))
                                .font(.body)
                            Text(id)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                                .lineLimit(1)
                                .truncationMode(.middle)
                        }
                        Spacer()
                        Button {
                            remove(id)
                        } label: {
                            Image(systemName: "minus.circle.fill")
                                .foregroundStyle(.secondary)
                        }
                        .buttonStyle(.plain)
                        .help(L("Remove", "제거"))
                    }
                    .padding(.vertical, 2)
                }
            }

            Divider().opacity(0.4)

            Button(action: addApp) {
                Label(L("Add app…", "앱 추가…"), systemImage: "plus")
            }
            .padding(.top, 2)
        }
    }

    // MARK: - Bundle ID → 사람이 읽을 이름/아이콘

    private func appURL(for id: String) -> URL? {
        NSWorkspace.shared.urlForApplication(withBundleIdentifier: id)
    }

    private func appName(for id: String) -> String {
        guard let url = appURL(for: id) else { return id }   // 설치 안 됐으면 ID 그대로
        let name = FileManager.default.displayName(atPath: url.path)
        return name.hasSuffix(".app") ? String(name.dropLast(4)) : name
    }

    private func appIcon(for id: String) -> Image {
        if let url = appURL(for: id) {
            return Image(nsImage: NSWorkspace.shared.icon(forFile: url.path))
        }
        return Image(systemName: "app.dashed")
    }

    // MARK: - 추가 / 제거

    private func remove(_ id: String) {
        csv = ids.filter { $0 != id }.joined(separator: ",")
    }

    private func addApp() {
        let panel = NSOpenPanel()
        panel.canChooseFiles = true
        panel.canChooseDirectories = false
        panel.allowsMultipleSelection = false
        panel.allowedContentTypes = [.application]
        panel.directoryURL = URL(fileURLWithPath: "/Applications")
        panel.prompt = L("Add", "추가")
        panel.message = L("Choose an app whose clipboard should never be recorded.",
                          "클립보드를 기록하지 않을 앱을 선택하세요.")
        guard panel.runModal() == .OK,
              let url = panel.url,
              let bundleID = Bundle(url: url)?.bundleIdentifier else { return }
        var list = ids
        if !list.contains(bundleID) { list.append(bundleID) }
        csv = list.joined(separator: ",")
    }
}
