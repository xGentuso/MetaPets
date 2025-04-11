import SwiftUI
import Foundation

            let textPosition = CGPoint(
                x: radius + midRadius * Foundation.cos(midAngle.radians),
                y: radius + midRadius * Foundation.sin(midAngle.radians)
            )
            
            let coinPosition = CGPoint(
                x: radius + (midRadius - 25) * Foundation.cos(midAngle.radians),
                y: radius + (midRadius - 25) * Foundation.sin(midAngle.radians)
            ) 