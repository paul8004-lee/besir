import Foundation
import CoreGraphics
import ImageIO
import UniformTypeIdentifiers

// besir 앱 아이콘(1024px)을 그린다.
//   실행: swiftc -O -o /tmp/mkicon Tools/MakeAppIcon.swift && /tmp/mkicon Resources/Assets.xcassets/AppIcon.appiconset/AppIcon-1024.png
//
// ⚠️ 좌표·굵기는 Shared/Theme.swift의 BesirMark와 **반드시 같아야 한다**.
//    한쪽만 고치면 앱 안 로고와 홈 화면 아이콘이 서로 달라 보인다(실제로 그런 적이 있음).

let canvas: CGFloat = 1024
let box: CGFloat = 104          // 마크 좌표계
// 마크는 좌표계 안에서 이미 사방 4만큼 여백을 갖는다(바깥 점 끝이 48). 그래서 아이콘 여백은 조금만.
let inset: CGFloat = 0.90
let scale = canvas / box * inset
let offset = (canvas - box * scale) / 2

// --- BesirMark와 공유하는 수치 ---
let ringRadius: CGFloat = 24     // 방울 중심이 놓인 원
let nodeRadius: CGFloat = 10
let dotRadius: CGFloat = 6
let dotOffset: CGFloat = 18      // 방울 중심에서 바깥 점까지
let linkWidth: CGFloat = 7
let center = CGPoint(x: 52, y: 52)

func node(_ i: Int) -> CGPoint {
    let a = (-90 + 72 * Double(i)) * .pi / 180
    return CGPoint(x: center.x + ringRadius * CGFloat(cos(a)), y: center.y + ringRadius * CGFloat(sin(a)))
}
func dot(_ i: Int) -> CGPoint {
    let a = (-90 + 72 * Double(i)) * .pi / 180
    let r = ringRadius + dotOffset
    return CGPoint(x: center.x + r * CGFloat(cos(a)), y: center.y + r * CGFloat(sin(a)))
}
/// 두 방울 사이를 잇는 곡선의 제어점 — 중점을 중심 쪽으로 22% 당긴다.
func control(_ i: Int) -> CGPoint {
    let a = node(i), b = node((i + 1) % 5)
    let m = CGPoint(x: (a.x + b.x) / 2, y: (a.y + b.y) / 2)
    let pull: CGFloat = 0.22
    return CGPoint(x: m.x + (center.x - m.x) * pull, y: m.y + (center.y - m.y) * pull)
}

func rgb(_ hex: UInt32) -> CGColor {
    CGColor(srgbRed: CGFloat((hex >> 16) & 0xFF)/255, green: CGFloat((hex >> 8) & 0xFF)/255,
            blue: CGFloat(hex & 0xFF)/255, alpha: 1)
}
let ground = rgb(0xFCFCFB), sage = rgb(0x4A6B5A), brass = rgb(0xA8763F)

let cs = CGColorSpace(name: CGColorSpace.sRGB)!
guard let ctx = CGContext(data: nil, width: Int(canvas), height: Int(canvas), bitsPerComponent: 8,
                          bytesPerRow: 0, space: cs,
                          bitmapInfo: CGImageAlphaInfo.noneSkipLast.rawValue) else { fatalError("ctx") }
ctx.translateBy(x: 0, y: canvas); ctx.scaleBy(x: 1, y: -1)   // SVG처럼 y가 아래로
ctx.setFillColor(ground); ctx.fill(CGRect(x: 0, y: 0, width: canvas, height: canvas))
ctx.translateBy(x: offset, y: offset); ctx.scaleBy(x: scale, y: scale)

let link = CGMutablePath()
link.move(to: node(0))
for i in 0..<5 { link.addQuadCurve(to: node((i + 1) % 5), control: control(i)) }
link.closeSubpath()
ctx.addPath(link)
ctx.setStrokeColor(sage); ctx.setLineWidth(linkWidth); ctx.setLineJoin(.round); ctx.strokePath()

ctx.setFillColor(sage)
for i in 0..<5 {
    let c = node(i)
    ctx.fillEllipse(in: CGRect(x: c.x - nodeRadius, y: c.y - nodeRadius,
                               width: nodeRadius * 2, height: nodeRadius * 2))
}
ctx.setFillColor(brass)
for i in 0..<5 {
    let c = dot(i)
    ctx.fillEllipse(in: CGRect(x: c.x - dotRadius, y: c.y - dotRadius,
                               width: dotRadius * 2, height: dotRadius * 2))
}

guard let img = ctx.makeImage() else { fatalError("image") }
let out = URL(fileURLWithPath: CommandLine.arguments[1])
guard let dest = CGImageDestinationCreateWithURL(out as CFURL, UTType.png.identifier as CFString, 1, nil)
else { fatalError("dest") }
CGImageDestinationAddImage(dest, img, nil)
CGImageDestinationFinalize(dest)
print("wrote \(out.path)")
