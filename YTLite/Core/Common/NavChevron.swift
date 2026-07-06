import UIKit

/// The single factory for navigation chevrons. Every screen builds its
/// back/minimize button here — and `RotatingNavigationController` replaces
/// the system back button on push — so the glyph and edge inset are
/// identical on every screen and iOS version.
enum NavChevron {
    enum Kind {
        case back
        case minimize
    }

    static func barButton(
        kind: Kind,
        target: Any?,
        action: Selector
    ) -> UIBarButtonItem {
        UIBarButtonItem(
            image: image(kind: kind),
            style: .plain,
            target: target,
            action: action
        )
    }

    static func image(kind: Kind) -> UIImage? {
        if #available(iOS 13.0, *) {
            let name = kind == .back ? "chevron.left" : "chevron.down"
            return ThemeManager.navChevron(systemName: name)
        }
        return drawnChevron(kind: kind)
    }

    // MARK: - Pre-iOS 13 fallback (no SF Symbols)

    private static func drawnChevron(kind: Kind) -> UIImage {
        let size: CGSize
        let points: [CGPoint]
        switch kind {
        case .back:
            size = CGSize(width: 13, height: 22)
            points = [
                CGPoint(x: 11, y: 2),
                CGPoint(x: 2, y: 11),
                CGPoint(x: 11, y: 20)
            ]
        case .minimize:
            size = CGSize(width: 22, height: 13)
            points = [
                CGPoint(x: 2, y: 2),
                CGPoint(x: 11, y: 11),
                CGPoint(x: 20, y: 2)
            ]
        }
        let image = UIGraphicsImageRenderer(size: size).image { _ in
            let path = UIBezierPath()
            path.move(to: points[0])
            points.dropFirst().forEach { path.addLine(to: $0) }
            path.lineWidth = 3
            path.lineCapStyle = .round
            path.lineJoinStyle = .round
            UIColor.black.setStroke()
            path.stroke()
        }
        // Template so the navigation bar tint colors it per theme.
        return image.withRenderingMode(.alwaysTemplate)
    }
}
