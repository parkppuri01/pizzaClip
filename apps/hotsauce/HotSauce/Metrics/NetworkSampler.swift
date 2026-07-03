import Foundation
import CoreWLAN
import Darwin

/// getifaddrs 누적 바이트 차분으로 송수신 속도, CoreWLAN 으로 Wi-Fi 신호를 읽는다.
final class NetworkSampler {
    /// 인터페이스별 직전 카운터. ifi_obytes/ifi_ibytes 는 32비트라 4GiB 마다
    /// 한 바퀴 돌기(wrap) 때문에, 인터페이스 단위로 UInt32 랩 안전 차분을 해야
    /// 속도가 천문학적 수치로 튀지 않는다.
    private var previousCounters: [String: (sent: UInt32, received: UInt32)] = [:]
    private var previousTime: Date?

    func sample() -> NetworkSnapshot {
        var snapshot = NetworkSnapshot()

        var currentCounters: [String: (sent: UInt32, received: UInt32)] = [:]
        var addressList: UnsafeMutablePointer<ifaddrs>?

        if getifaddrs(&addressList) == 0, let first = addressList {
            defer { freeifaddrs(addressList) }
            var cursor: UnsafeMutablePointer<ifaddrs>? = first
            while let current = cursor {
                defer { cursor = current.pointee.ifa_next }
                let name = String(cString: current.pointee.ifa_name)
                let flags = Int32(current.pointee.ifa_flags)
                let isUp = (flags & IFF_UP) != 0
                let isLoopback = (flags & IFF_LOOPBACK) != 0
                guard isUp, !isLoopback else { continue }
                // 가상 인터페이스 제외 (런캣의 vpn/tun 필터와 같은 취지)
                if name.hasPrefix("utun") || name.hasPrefix("awdl") || name.hasPrefix("llw")
                    || name.hasPrefix("bridge") || name.hasPrefix("gif") || name.hasPrefix("stf") {
                    continue
                }
                guard let address = current.pointee.ifa_addr else { continue }

                if address.pointee.sa_family == UInt8(AF_LINK) {
                    if let data = current.pointee.ifa_data?.assumingMemoryBound(to: if_data.self) {
                        currentCounters[name] = (data.pointee.ifi_obytes, data.pointee.ifi_ibytes)
                    }
                } else if address.pointee.sa_family == UInt8(AF_INET) {
                    // 실제 IPv4 주소가 있으면 연결된 것으로 본다. en0(주 인터페이스) 우선.
                    var host = [CChar](repeating: 0, count: Int(NI_MAXHOST))
                    if getnameinfo(address, socklen_t(address.pointee.sa_len),
                                   &host, socklen_t(host.count), nil, 0, NI_NUMERICHOST) == 0 {
                        let ip = String(cString: host)
                        if snapshot.localIP == nil || name == "en0" {
                            snapshot.localIP = ip
                        }
                        snapshot.isConnected = true
                    }
                }
            }
        }

        // 속도 = 인터페이스별 (현재 - 직전) 랩 안전 차분의 합 / 경과 시간.
        // 직전 샘플에 없던(새로 생긴) 인터페이스는 이번 회차에서 제외되고,
        // 사라진 인터페이스의 누적치는 자연스럽게 버려진다.
        let now = Date()
        if let before = previousTime {
            let elapsed = now.timeIntervalSince(before)
            if elapsed > 0 {
                var sentDelta: UInt64 = 0
                var receivedDelta: UInt64 = 0
                for (name, counters) in currentCounters {
                    guard let previous = previousCounters[name] else { continue }
                    sentDelta &+= UInt64(counters.sent &- previous.sent)
                    receivedDelta &+= UInt64(counters.received &- previous.received)
                }
                snapshot.uploadBytesPerSec = Double(sentDelta) / elapsed
                snapshot.downloadBytesPerSec = Double(receivedDelta) / elapsed
            }
        }
        previousCounters = currentCounters
        previousTime = now

        snapshot.signalBars = signalBars(isConnected: snapshot.isConnected)
        return snapshot
    }

    /// Wi-Fi RSSI → 0~5 칸. Wi-Fi 가 아니라 유선으로 연결돼 있으면 5칸.
    private func signalBars(isConnected: Bool) -> Int {
        guard isConnected else { return 0 }
        if let interface = CWWiFiClient.shared().interface(),
           interface.powerOn(),
           interface.ssid() != nil || interface.rssiValue() != 0 {
            let rssi = interface.rssiValue()
            switch rssi {
            case (-55)...: return 5
            case (-65)...: return 4
            case (-72)...: return 3
            case (-80)...: return 2
            default: return 1
            }
        }
        // Wi-Fi 미사용(유선 등)인데 연결은 되어 있음 → 최대 신호로 표시
        return 5
    }
}
