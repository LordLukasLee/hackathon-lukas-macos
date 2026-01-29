import SwiftUI

/// Centralized design tokens for consistent UI following Apple HIG
enum Theme {
    // MARK: - Spacing Scale (4pt base)
    enum Spacing {
        static let xs: CGFloat = 4
        static let sm: CGFloat = 8
        static let md: CGFloat = 12
        static let lg: CGFloat = 16
        static let xl: CGFloat = 32      // Was 24 - increased for more visual separation
        static let xxl: CGFloat = 48     // Was 32 - increased for major spacing
        static let section: CGFloat = 40 // Between major sections
    }

    // MARK: - Corner Radius
    enum Radius {
        /// Small elements: buttons, badges, chips
        static let sm: CGFloat = 6
        /// Medium elements: input fields, small cards
        static let md: CGFloat = 8
        /// Large elements: cards, panels, modals
        static let lg: CGFloat = 12
    }

    // MARK: - Platform Colors
    enum Platform {
        static let instagram = Color.pink
        static let linkedin = Color.blue
        static let twitter = Color.cyan
    }

    // MARK: - Animation
    enum Animation {
        static let quick = SwiftUI.Animation.easeInOut(duration: 0.15)
        static let standard = SwiftUI.Animation.easeInOut(duration: 0.2)
        static let smooth = SwiftUI.Animation.easeOut(duration: 0.4)
    }

    // MARK: - Shadow
    enum Shadow {
        static let subtle: (color: Color, radius: CGFloat, y: CGFloat) = (.black.opacity(0.08), 8, 4)
        static let hover: (color: Color, radius: CGFloat, y: CGFloat) = (.black.opacity(0.15), 12, 6)
        static let card: (color: Color, radius: CGFloat, y: CGFloat) = (.black.opacity(0.06), 6, 3)
    }

    // MARK: - Step Colors (for visual hierarchy)
    enum StepColors {
        static let step1 = Color.blue       // Company selection
        static let step2 = Color.orange     // Ideas/Topic
        static let step3 = Color.purple     // Generate
    }
}
