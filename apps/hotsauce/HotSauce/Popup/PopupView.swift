import SwiftUI
import AppKit

/// hotsauce.pxd 디자인을 좌표 그대로 재현한 팝업.
/// 좌표·크기 숫자는 전부 pxd 레이어에서 추출한 디자인 유닛 값이다.
struct PopupView: View {
    @ObservedObject var engine: MetricsEngine
    var onOpenSettings: () -> Void = {}
    var onLockChanged: (Bool) -> Void = { _ in }
    @State private var isLocked = false
    /// 설정 토글과 같은 키. 끄면 배너 블록(141.5유닛)이 빠지고 팝업이 짧아진다.
    @AppStorage("showSiteBanner") private var showSiteBanner = true

    /// 배너를 끄면 푸터 구분선·푸터가 배너 블록만큼 위로 올라온다.
    private var footerShift: CGFloat { showSiteBanner ? 0 : -DS.bannerBlockHeight }

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

            if showSiteBanner { siteBanner }
            footer

            // 자물쇠: 헤더 우상단. 잠그면 포커스를 잃어도 팝업이 안 닫힌다.
            // 그림과 탭 영역을 분리한다 — footer(설정·활성보기)와 똑같은 검증된 패턴.
            // (contentShape 를 placedCenter=offset 뒤에 붙이면 탭 영역이 좌상단 원위치에
            //  남아 클릭이 안 먹던 버그를 이 방식으로 피한다.)
            Image(systemName: isLocked ? "lock.fill" : "lock.open")
                .font(.system(size: DS.u(26)))
                .foregroundColor(DS.text)
                .placedCenter(845, 41.4, w: 34, h: 34)
            Color.clear
                .contentShape(Rectangle())
                .placedCenter(845, 41.4, w: 60, h: 60)
                .onTapGesture {
                    isLocked.toggle()
                    onLockChanged(isLocked)
                }

            // 이스터에그 폭발 오버레이 (맨 위 레이어, 클릭 방해 안 함)
            HotSauceBurst(trigger: engine.burstID)
                .frame(width: DS.popupSize.width, height: DS.popupSize.height)
                .allowsHitTesting(false)
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
                .placedCenter(50, 41.4, w: 48, h: 48)   // 사용자 요청으로 축소 (64→48)
            Text(L("Hot sauce  -  System Monitor", "Hot sauce  -  시스템 모니터"))
                .font(DS.headerFont)                     // PicKle 히스토리 타이틀과 동일 (SF 13pt semibold)
                .foregroundColor(DS.text)
                .placedLeft(80, centerY: 41.4, rowHeight: 40)
        }
    }

    private var dividers: some View {
        Group {
            Rectangle().fill(DS.divider)
                .placedCenter(450, 85, w: 900, h: 1.5)
            Rectangle().fill(DS.divider)
                .placedCenter(450, 1056 + footerShift, w: 900, h: 1.5)   // 배너 아래 · 푸터 위
        }
    }

    // MARK: - 섹션 공통 부품

    private func sectionIcon(_ name: String, x: CGFloat, y: CGFloat, size: CGFloat) -> some View {
        Image(nsImage: Assets.image(name))
            .resizable()
            .scaledToFit()
            .placedCenter(x, y, w: size, h: size)
    }

    private func sectionTitle(_ text: String, left: CGFloat, centerY: CGFloat,
                              percent: Double? = nil) -> some View {
        // percent 가 있으면 제목 옆에 현재 수치를 붙인다. 예: "CPU  43%"
        let title = percent.map { text + "  " + String(format: "%.0f%%", $0) } ?? text
        return Text(title)
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
            sectionIcon("cpu_icon", x: 126, y: 184, size: 62)
            sectionTitle("CPU", left: 238.5, centerY: 141.5, percent: cpu.totalPercent)
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
            sectionIcon("memory_icon", x: 126, y: 339.6, size: 62)
            sectionTitle(L("Memory", "메모리"), left: 238.5, centerY: 297.5,
                         percent: memory.usedFraction * 100)
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
            sectionIcon("disk_icon", x: 126, y: 493.7, size: 62)
            sectionTitle(L("Storage", "저장 용량"), left: 239.5, centerY: 449.5,
                         percent: disk.usedFraction * 100)
            gauge(fraction: disk.usedFraction, left: 240, centerY: 489.5)
            statText(L("Disk Used", "디스크 사용량") + " : "
                     + Fmt.diskGB(disk.usedBytes) + " / " + Fmt.diskGB(disk.totalBytes),
                     left: 241, centerY: 532.8)
            face(disk.state, x: 789.4, y: 490.2)
        }
    }

    // MARK: - 배터리

    private func batterySection(_ battery: BatterySnapshot) -> some View {
        // 충전기가 꽂혀 있으면(ExternalConnected) 왼쪽 아이콘을 플러그(bat2_icon)로 교체.
        // IsCharging은 macOS 최적화충전으로 꽂혀 있어도 자주 false라, 꽂힘 여부로 판단.
        // 에셋이 없으면 기존 배터리 아이콘으로 안전 폴백(빈 아이콘 방지).
        let batteryIcon = (battery.externalConnected && Assets.exists("bat_icon_charge"))
            ? "bat_icon_charge" : "bat_icon"
        return Group {
            sectionIcon(batteryIcon, x: 126, y: 648.5, size: 62)
            sectionTitle(L("Battery", "배터리"), left: 239.5, centerY: 606.5,
                         percent: battery.isPresent ? Double(battery.levelPercent) : nil)
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
            sectionIcon("wifi_icon", x: 126, y: 803.2, size: 62)
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

    // MARK: - 사이트 배너

    /// 네트워크 섹션과 푸터 구분선 사이의 프로모 배너. 누르면 pizza-clip.com 이 열린다.
    /// 배경이 팝업과 같은 차콜이라 테두리 없이 자연스럽게 얹힌다.
    ///
    /// **894.9×148.6 은 임의값이 아니라 아이콘 열에서 역산한 값이다.**
    /// 원본 site_banner.png(3000×498)를 측정하면 양 끝 아이콘이 정확히 206×206px,
    /// 중심이 각각 x=407.5 / x=2635.5 다. 이 두 아이콘이 팝업의 기존 두 아이콘 열
    /// (왼쪽 섹션 아이콘 x=126 · 오른쪽 얼굴 x=789.4~791.8)에 얹히도록 스케일을 맞췄다:
    ///
    ///   스케일 = (790.6 − 126) / (2635.5 − 407.5) = 0.298294 유닛/px
    ///   → 배너 3000×498 → 894.9×148.6, 왼쪽 끝 4.45 (중심 451.9)
    ///   → 배너 아이콘 206px → 61.45 유닛 (섹션 62 · 얼굴 61 사이)
    ///   → 왼쪽 아이콘 중심 126.0 · 오른쪽 아이콘 중심 790.6 에 안착
    ///
    /// ⚠️ 배너 그림을 교체하면 아이콘 픽셀 위치가 달라지므로 이 계산을 다시 해야 한다.
    private var siteBanner: some View {
        Group {
            Image(nsImage: Assets.image("site_banner"))
                .resizable()
                .scaledToFit()
                .placedCenter(451.9, 962, w: 894.9, h: 148.6)
            // 그림과 탭 영역 분리 — 자물쇠·푸터와 같은 검증된 패턴
            // (contentShape 를 placedCenter 뒤에 붙이면 탭 영역이 좌상단에 남는다)
            Color.clear
                .contentShape(Rectangle())
                .placedCenter(451.9, 962, w: 894.9, h: 148.6)
                .onTapGesture { openSite() }
        }
    }

    // MARK: - 푸터

    // 푸터 띠: 구분선 1056 ~ 캔버스 바닥 1176 = 120 유닛.
    // (원래 85.5 유닛이라 아이콘 위아래 여백이 12 밖에 없어 답답했다 → 29 로 넓힘)
    // 배너를 끄면 띠 120 은 그대로 두고 전체가 footerShift 만큼 위로 올라온다.
    private var footer: some View {
        Group {
            // 활성 상태 보기 (Activity Monitor 열기)
            Group {
                Image(nsImage: Assets.image("activeit_icon"))
                    .resizable()
                    .scaledToFit()
                    .placedCenter(126, 1116 + footerShift, w: 62, h: 62)
                Text(L("Activity Monitor", "활성 상태 보기"))
                    .font(DS.font(DS.titleFontSize))
                    .foregroundColor(DS.text)
                    .placedLeft(232.5, centerY: 1116 + footerShift)
            }
            Color.clear
                .contentShape(Rectangle())
                .placedCenter(230, 1116 + footerShift, w: 290, h: 80)
                .onTapGesture { openActivityMonitor() }

            // 설정
            Image(nsImage: Assets.image("setting_icon"))
                .resizable()
                .scaledToFit()
                .placedCenter(791.8, 1115.8 + footerShift, w: 61.5, h: 61.5)
            Color.clear
                .contentShape(Rectangle())
                .placedCenter(791.8, 1115.8 + footerShift, w: 80, h: 80)
                .onTapGesture { onOpenSettings() }
        }
    }

    private func openActivityMonitor() {
        let url = URL(fileURLWithPath: "/System/Applications/Utilities/Activity Monitor.app")
        NSWorkspace.shared.openApplication(at: url, configuration: .init())
    }

    /// 배너 → 제품 사이트. 언어 분기는 사이트 미들웨어가 접속 국가로 알아서 하므로
    /// 앱에서 /en/ 을 따로 붙이지 않는다(붙여도 되돌려 보내진다).
    private func openSite() {
        guard let url = URL(string: "https://pizza-clip.com/") else { return }
        NSWorkspace.shared.open(url)
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
