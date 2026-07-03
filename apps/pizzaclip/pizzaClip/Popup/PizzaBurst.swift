import SwiftUI

/// Easter-egg overlay: confetti-style 🍕 particles launched up from the bottom
/// of the popup, peaking near mid-height, then falling back through the floor
/// under gravity. Triggered by mutating `trigger` (any new UUID = new burst).
///
/// Renders each particle as a real `Text` view positioned with `.position()`
/// and rotated with `.rotationEffect`. Canvas + `gc.draw(text:)` was tried
/// first but emojis sometimes fail to rasterise inside a Canvas draw layer
/// on macOS 13 — plain SwiftUI views avoid that entire failure mode.
struct PizzaBurst: View {
    let trigger: UUID?

    @State private var startedAt: Date = .distantPast
    @State private var particles: [Particle] = []

    private let duration: TimeInterval = 2.4
    private let gravity: CGFloat = 600   // px/s² — tuned for ~480pt popup
    // "폭탄피자" PNG(BombPizza 에셋) 렌더 배율. 1.5(기존)에서 다시 1.5배 키워 2.25.
    private let imageScale: CGFloat = 2.25
    // 전체 모션 속도 배율(1.0 = 기본). vy·g를 함께 키워 튀는 높이는
    // 유지한 채 올라갔다 떨어지는 동작 속도만 조절한다.
    private let speed: CGFloat = 1.0

    struct Particle: Identifiable {
        let id = UUID()
        let x0Norm: CGFloat       // 0…1 of width
        let vySpeed: CGFloat      // upward initial speed (px/s)
        let vx: CGFloat           // sideways drift (px/s)
        let angle0: CGFloat       // initial rotation (rad)
        let omega: CGFloat        // angular velocity (rad/s)
        let delay: TimeInterval   // stagger so particles don't all launch on frame 0
        let size: CGFloat         // base size (px); rendered ×imageScale
    }

    var body: some View {
        GeometryReader { geo in
            TimelineView(.animation) { context in
                let elapsed = context.date.timeIntervalSince(startedAt)
                ZStack(alignment: .topLeading) {
                    // Anchor so GeometryReader-driven ZStack actually expands
                    // to fill the proposed size even when no live particles
                    // are inside it.
                    Color.clear
                    ForEach(particles) { p in
                        particleView(p, elapsed: elapsed, size: geo.size)
                    }
                }
                .frame(width: geo.size.width, height: geo.size.height)
            }
        }
        .allowsHitTesting(false)
        // `.task(id:)` fires on first mount AND on every `trigger` change, so
        // we catch the case where the popup is being mounted from scratch
        // with a non-nil burst ID already set. `.onChange` alone would miss
        // that initial-mount fire and the burst would never play.
        .task(id: trigger) {
            guard trigger != nil else { return }
            startedAt = Date()
            particles = PizzaBurst.makeParticles()
        }
    }

    @ViewBuilder
    private func particleView(_ p: Particle, elapsed: TimeInterval, size: CGSize) -> some View {
        let t = elapsed - p.delay
        if t >= 0, t <= duration, size.width > 0, size.height > 0 {
            let tt = CGFloat(t)
            // speed 배율: vy×speed, g×speed² → 정점 높이는 그대로, 동작만 빨라짐
            let vy = p.vySpeed * speed
            let g = gravity * speed * speed
            let h = vy * tt - 0.5 * g * tt * tt
            let x = p.x0Norm * size.width + p.vx * tt
            let y = size.height - h
            let angle = p.angle0 + p.omega * tt
            let life = duration - p.delay
            let opacity: Double = {
                if t < 0.12 { return Double(t / 0.12) }
                if t > life - 0.35 { return max(0, Double((life - t) / 0.35)) }
                return 1
            }()

            Image("BombPizza")
                .resizable()
                .interpolation(.high)
                .aspectRatio(contentMode: .fit)
                .frame(width: p.size * imageScale, height: p.size * imageScale)
                .rotationEffect(.radians(Double(angle)))
                .position(x: x, y: y)
                .opacity(opacity)
        }
    }

    private static func makeParticles() -> [Particle] {
        (0..<34).map { _ in
            Particle(
                x0Norm: CGFloat.random(in: 0.08...0.92),
                // 튀어오르는 높이 편차는 유지하되 최고점은 살짝 낮춤.
                vySpeed: CGFloat.random(in: 300...560),
                vx: CGFloat.random(in: -70...70),
                angle0: CGFloat.random(in: 0...(2 * .pi)),
                omega: CGFloat.random(in: -4...4),
                delay: TimeInterval.random(in: 0...0.32),
                // 크기 편차는 유지하되 최소값을 올려 너무 작은 조각이 안 보이는 걸 방지.
                size: CGFloat.random(in: 18...34)
            )
        }
    }
}
