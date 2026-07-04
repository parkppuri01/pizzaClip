import SwiftUI
import AppKit

/// hotsauce.pxd 디자인을 좌표 그대로 재현한 팝업.
/// 좌표·크기 숫자는 전부 pxd 레이어에서 추출한 디자인 유닛 값이다.
struct PopupView: View {
    @ObservedObject var engine: MetricsEngine
    var onOpenSettings: () -> Void = {}

    var body: some View {
        let snap = engine.snapshot
        ZStack(alignment: .topLeading) {
            // 캔버스 크기 고정용 바닥판
            DS.background
                .frame(width: DS.popupSize.width, height: DS.popupSize.height)

            header
            dividers

            cpuSection(snap.cpu)
            memorySection(snap.memory)
            diskSection(snap.disk)
            batterySection(snap.battery)
            networkSection(snap.network)

            footer
        }
        .frame(width: DS.popupSize.width, height: DS.popupSize.height)
        .clipShape(RoundedRectangle(cornerRadius: DS.u(DS.cornerRadius), style: .continuous))
    }

    // MARK: - 헤더

    private var header: some View {
        Group {
            Image(nsImage: Assets.image("title_icon"))
                .resizable()
                .scaledToFit()
                .placedCenter(52, 41.4, w: 64, h: 64)
            Text(L("Hot sauce  -  System Monitor", "Hot sauce  -  시스템 모니터"))
                .font(DS.font(DS.headerFontSize))
                .foregroundColor(DS.text)
                .placedLeft(87, centerY: 41.4, rowHeight: 40)
        }
    }

    private var dividers: some View {
        Group {
            Rectangle().fill(DS.divider)
                .placedCenter(450, 85, w: 900, h: 1.5)
            Rectangle().fill(DS.divider)
                .placedCenter(450, 914.5, w: 900, h: 1.5)
        }
    }

    // MARK: - 섹션 공통 부품

    private func sectionIcon(_ name: String, x: CGFloat, y: CGFloat, size: CGFloat) -> some View {
        Image(nsImage: Assets.image(name))
            .resizable()
            .scaledToFit()
            .placedCenter(x, y, w: size, h: size)
    }

    private func sectionTitle(_ text: String, left: CGFloat, centerY: CGFloat) -> some View {
        Text(text)
            .font(DS.font(DS.titleFontSize))
            .foregroundColor(DS.text)
            .placedLeft(left, centerY: centerY)
    }

    private func statText(_ text: String, left: CGFloat, centerY: CGFloat) -> some View {
        Text(text)
            .font(DS.statFont)  // 최소 가독 크기 고정 (팝업 축소와 무관)
            .foregroundColor(DS.text)
            .placedLeft(left, centerY: centerY, rowHeight: 22)
    }

    private func gauge(fraction: Double, left: CGFloat, centerY: CGFloat) -> some View {
        GaugeBar(fraction: fraction)
            .placedCenter(left + 217, centerY, w: 434, h: 25)
    }

    private func face(_ state: LoadState, x: CGFloat, y: CGFloat) -> some View {
        Image(nsImage: Assets.image(state.faceAssetName))
            .resizable()
            .scaledToFit()
            .placedCenter(x, y, w: 61, h: 61)
    }

    // MARK: - CPU

    private func cpuSection(_ cpu: CPUSnapshot) -> some View {
        Group {
            sectionIcon("cpu_icon", x: 126, y: 184, size: 96)
            sectionTitle("CPU", left: 238.5, centerY: 141.5)
            gauge(fraction: cpu.totalPercent / 100, left: 238, centerY: 183.5)
            statText(L("System", "시스템") + " : " + Fmt.percent1(cpu.systemPercent),
                     left: 238, centerY: 226.2)
            statText(L("User", "사용자") + " : " + Fmt.percent1(cpu.userPercent),
                     left: 409.5, centerY: 226.2)
            statText(L("Idle", "대기") + " : " + Fmt.percent1(cpu.idlePercent),
                     left: 580.5, centerY: 226.2)
            face(cpu.state, x: 789.4, y: 183.6)
        }
    }

    // MARK: - 메모리

    private func memorySection(_ memory: MemorySnapshot) -> some View {
        Group {
            sectionIcon("memory_icon", x: 125.8, y: 339.6, size: 76)
            sectionTitle(L("Memory", "메모리"), left: 238.5, centerY: 297.5)
            gauge(fraction: memory.usedFraction, left: 238.5, centerY: 339.5)
            statText(L("Pressure", "압력") + " : " + Fmt.percent1(memory.pressurePercent),
                     left: 238, centerY: 381.2)
            statText(L("Used", "사용 메모리") + " : " + Fmt.memoryGB(memory.usedBytes),
                     left: 385, centerY: 381.2)
            statText(L("Cached", "캐쉬") + " : " + Fmt.memoryGB(memory.cachedBytes),
                     left: 577.5, centerY: 381.2)
            statText(L("Swap", "스왑") + " : " + Fmt.swapMB(memory.swapUsedBytes),
                     left: 238, centerY: 406.8)
            face(memory.state, x: 789.4, y: 339.5)
        }
    }

    // MARK: - 저장 용량

    private func diskSection(_ disk: DiskSnapshot) -> some View {
        Group {
            sectionIcon("disk_icon", x: 126, y: 493.7, size: 90)
            sectionTitle(L("Storage", "저장 용량"), left: 239.5, centerY: 449.5)
            gauge(fraction: disk.usedFraction, left: 240, centerY: 489.5)
            statText(L("Disk Used", "디스크 사용량") + " : "
                     + Fmt.diskGB(disk.usedBytes) + " / " + Fmt.diskGB(disk.totalBytes),
                     left: 241, centerY: 532.8)
            face(disk.state, x: 789.4, y: 490.2)
        }
    }

    // MARK: - 배터리

    private func batterySection(_ battery: BatterySnapshot) -> some View {
        // 충전 중이면 왼쪽 아이콘을 플러그(bat2_icon)로 교체.
        // 에셋이 없으면 기존 배터리 아이콘으로 안전 폴백(빈 아이콘 방지).
        let batteryIcon = (battery.isCharging && Assets.exists("bat2_icon"))
            ? "bat2_icon" : "bat_icon"
        return Group {
            sectionIcon(batteryIcon, x: 123, y: 648.5, size: 90)
            sectionTitle(L("Battery", "배터리"), left: 239.5, centerY: 606.5)
            gauge(fraction: battery.isPresent ? Double(battery.levelPercent) / 100 : 0,
                  left: 239.5, centerY: 648.5)
            statText(L("Charge", "배터리 잔량") + " : "
                     + (battery.isPresent ? "\(battery.levelPercent)%" : "—"),
                     left: 241.5, centerY: 689.8)
            statText(L("Temp", "온도") + " : "
                     + (battery.temperatureCelsius.map { String(format: "%.1f℃", $0) } ?? "—"),
                     left: 425.5, centerY: 689.8)
            statText(L("Cycles", "사이클") + " : "
                     + (battery.cycleCount.map(String.init) ?? "—"),
                     left: 601.5, centerY: 689.8)
            face(battery.state, x: 791.8, y: 648.2)
        }
    }

    // MARK: - 네트워크

    private func networkSection(_ network: NetworkSnapshot) -> some View {
        Group {
            sectionIcon("wifi_icon", x: 126, y: 803.2, size: 96)
            sectionTitle(L("Network", "네트워크"), left: 241, centerY: 762.5)
            statText(L("Local IP", "로컬 IP") + " : " + (network.localIP ?? "—"),
                     left: 242, centerY: 802.8)
            statText(L("Signal", "신호상태") + " : " + Fmt.signalDots(network.signalBars),
                     left: 530, centerY: 802.8)
            statText(L("Upload", "업로드") + " : " + Fmt.speed(network.uploadBytesPerSec),
                     left: 241, centerY: 831.2)
            statText(L("Download", "다운로드") + " : " + Fmt.speed(network.downloadBytesPerSec),
                     left: 533.5, centerY: 831.2)
            face(network.state, x: 791.8, y: 802.8)
        }
    }

    // MARK: - 푸터

    private var footer: some View {
        Group {
            // 활성 상태 보기 (Activity Monitor 열기)
            Group {
                Image(nsImage: Assets.image("activeit_icon"))
                    .resizable()
                    .scaledToFit()
                    .placedCenter(126, 958, w: 62, h: 62)
                Text(L("Activity Monitor", "활성 상태 보기"))
                    .font(DS.font(DS.titleFontSize))
                    .foregroundColor(DS.text)
                    .placedLeft(232.5, centerY: 958)
            }
            Color.clear
                .contentShape(Rectangle())
                .placedCenter(230, 958, w: 290, h: 70)
                .onTapGesture { openActivityMonitor() }

            // 설정
            Image(nsImage: Assets.image("setting_icon"))
                .resizable()
                .scaledToFit()
                .placedCenter(791.8, 957.8, w: 61.5, h: 61.5)
            Color.clear
                .contentShape(Rectangle())
                .placedCenter(791.8, 957.8, w: 80, h: 70)
                .onTapGesture { onOpenSettings() }
        }
    }

    private func openActivityMonitor() {
        let url = URL(fileURLWithPath: "/System/Applications/Utilities/Activity Monitor.app")
        NSWorkspace.shared.openApplication(at: url, configuration: .init())
    }
}

/// 디자인의 게이지 바: 밝은 테두리 알약 트랙 + 빨간 채움.
struct GaugeBar: View {
    var fraction: Double

    var body: some View {
        GeometryReader { geo in
            let inset = DS.u(2.5)
            let innerHeight = geo.size.height - inset * 2
            let maxWidth = geo.size.width - inset * 2
            let clamped = max(0, min(1, fraction))
            let width = clamped < 0.005 ? 0 : max(innerHeight, maxWidth * clamped)

            ZStack(alignment: .leading) {
                Capsule()
                    .stroke(DS.gaugeBorder, lineWidth: DS.u(2))
                if width > 0 {
                    Capsule()
                        .fill(DS.gaugeFill)
                        .frame(width: width, height: innerHeight)
                        .offset(x: inset)
                }
            }
        }
    }
}
