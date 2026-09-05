import SwiftUI

/// 이스터에그 오버레이: 시스템이 위험(빨강 얼굴 4개 이상)일 때 핫소스 병이 팝업
/// 바닥에서 위로 튀어올랐다가 중력으로 떨어지는 폭죽 효과. `trigger`(UUID)를 바꾸면
/// 새 폭발이 시작된다. pizzaClip `PizzaBurst` / PicKle `PickleBurst` 이식판으로,
/// 낱장 병 PNG(`menubar_1`)를 `Assets.image` 로 로드해 파티클로 그린다.
struct HotSauceBurst: View {
    let trigger: UUID?

    @State private var startedAt: Date = .distantPast
    @State private var particles: [Particle] = []
    /// 폭발이 진행 중일 때만 true. per-frame TimelineView 를 게이팅해 병이 다 떨어지면
    /// 틱을 멈춰 CPU 를 0 으로 되돌린다. (PickleBurst 의 절전 패턴)
    @State private var isBursting = false

    /// 파티클 하나의 수명. 페이드 아웃 없이 끝까지 보여주려면 **가장 늦게 떨어지는
    /// 병이 화면 밖으로 완전히 빠져나갈 때까지** 살아 있어야 한다.
    ///   최악: vySpeed 680 · size 46 → h(t) = 680t − 250t² 가 −23(반지름)이 되는
    ///        t ≈ 2.75초. 여기에 여유를 둬 3.0.
    /// ⚠️ 이 값을 줄이면 세게 쏜 병이 공중에서 뚝 사라진다(예전 2.4초가 그랬고,
    ///    그걸 마지막 0.35초 페이드 아웃으로 가리고 있었다).
    /// ⚠️ 늘릴 때는 MetricsEngine.burstHoldDuration 도 함께 키울 것 —
    ///    refresh 가 burstID 를 지워 애니메이션이 중간에 끊긴다.
    private let duration: TimeInterval = 3.0
    private let gravity: CGFloat = 500   // px/s² — ~520pt 팝업 높이에 맞춰 튜닝

    /// 파티클별 최대 발사 지연. 전체 폭발은 duration + maxDelay 에 끝난다.
    /// makeParticles() 의 delay 시드와 아래 teardown 타이머가 어긋나지 않게 단일 소스.
    private static let maxDelay: TimeInterval = 0.32

    struct Particle: Identifiable {
        let id = UUID()
        let x0Norm: CGFloat       // 0…1 of width
        let vySpeed: CGFloat      // upward initial speed (px/s)
        let vx: CGFloat           // sideways drift (px/s)
        let angle0: CGFloat       // initial rotation (rad)
        let omega: CGFloat        // angular velocity (rad/s)
        let delay: TimeInterval   // stagger so particles don't all launch on frame 0
        let size: CGFloat         // image side length (pt)
    }

    var body: some View {
        GeometryReader { geo in
            // 폭발 중일 때만 per-frame TimelineView 를 마운트. `.animation` 은 화면에
            // 있는 내내 60–120fps 로 다시 그려서, 계속 켜두면 팝업이 열려 있는 동안
            // 폭발이 없어도 CPU 를 태운다. 평상시엔 틱 없는 Color.clear 만 보여준다.
            if isBursting {
                TimelineView(.animation) { context in
                    let elapsed = context.date.timeIntervalSince(startedAt)
                    ZStack(alignment: .topLeading) {
                        Color.clear
                        ForEach(particles) { p in
                            particleView(p, elapsed: elapsed, size: geo.size)
                        }
                    }
                    .frame(width: geo.size.width, height: geo.size.height)
                }
            } else {
                Color.clear
            }
        }
        .allowsHitTesting(false)
        // `.task(id:)` 는 첫 마운트 + trigger 변경 때마다 실행된다.
        .task(id: trigger) {
            guard trigger != nil else { return }
            startedAt = Date()
            particles = HotSauceBurst.makeParticles()
            isBursting = true
            // 마지막 병이 다 떨어지면 애니메이션을 내려 TimelineView 를 언마운트한다.
            // 도중에 취소되면(팝업 닫힘/새 폭발이 상태를 가져감) 건드리지 않고 종료.
            do {
                try await Task.sleep(nanoseconds: UInt64((duration + Self.maxDelay) * 1_000_000_000))
            } catch {
                return
            }
            isBursting = false
            particles = []
        }
    }

    @ViewBuilder
    private func particleView(_ p: Particle, elapsed: TimeInterval, size: CGSize) -> some View {
        let t = elapsed - p.delay
        if t >= 0, t <= duration, size.width > 0, size.height > 0 {
            let tt = CGFloat(t)
            let h = p.vySpeed * tt - 0.5 * gravity * tt * tt
            let x = p.x0Norm * size.width + p.vx * tt
            let y = size.height - h
            let angle = p.angle0 + p.omega * tt
            // 등장 페이드 인만 남긴다. 사라질 때 페이드 아웃을 걸면 병이 아직
            // 화면 안에 있는데 흐려져서 "떨어지다 증발"하는 것처럼 보인다.
            // duration 을 화면 이탈 시간까지 늘렸으므로(위 주석), 병은 흐려지지 않고
            // 팝업 아래로 빠져나가면서 자연스럽게 사라진다.
            let opacity: Double = t < 0.12 ? Double(t / 0.12) : 1

            Image(nsImage: Assets.image("menubar_1"))
                .resizable()
                .interpolation(.high)
                .aspectRatio(contentMode: .fit)
                .frame(width: p.size, height: p.size)
                .rotationEffect(.radians(Double(angle)))
                .position(x: x, y: y)
                .opacity(opacity)
        }
    }

    private static func makeParticles() -> [Particle] {
        (0..<40).map { i in
            // 6개마다 하나(≈7개)는 더 세게 쏴서 더 높이 튀게 — 활기 부여.
            let highFlyer = i % 6 == 0
            let vy = highFlyer ? CGFloat.random(in: 560...680)
                               : CGFloat.random(in: 320...500)
            return Particle(
                x0Norm: CGFloat.random(in: 0.08...0.92),
                vySpeed: vy,
                vx: CGFloat.random(in: -60...60),
                angle0: CGFloat.random(in: 0...(2 * .pi)),
                omega: CGFloat.random(in: -4...4),
                delay: TimeInterval.random(in: 0...maxDelay),
                size: CGFloat.random(in: 26...46)
            )
        }
    }
}
