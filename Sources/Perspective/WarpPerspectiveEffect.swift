//
//  WarpPerspectiveEffect.swift
//  Perspective
//
//  Created by Yanan Li on 2025/5/4.
//

import SwiftUI
import simd

extension View {
    /// Applies a perspective correction effect to the view based on four source points.
    ///
    /// Use this modifier to correct perspective distortion in a rectangular region by mapping
    /// four normalized corner points (in the range 0...1) to the corners of the view.
    ///
    /// - Parameters:
    ///   - topLeftPoint: A normalized coordinate of the top-left corner of the source view.
    ///   - bottomLeftPoint: A normalized coordinate of the bottom-left corner of the source view.
    ///   - bottomRightPoint: A normalized coordinate of the bottom-right corner of the source view.
    ///   - topRightPoint: A normalized coordinate of the top-right corner of the source view.
    ///   - isEnabled: Whether the effect is enabled or not.
    ///
    /// - Returns: A view with the distortion effect applied.
    nonisolated public func warpPerspectiveEffect(
        topLeftPoint: CGPoint,
        bottomLeftPoint: CGPoint,
        bottomRightPoint: CGPoint,
        topRightPoint: CGPoint,
        isEnabled: Bool = true
    ) -> some View {
        modifier(
            _WarpPerspectiveEffectViewModifier(
                topLeftPoint: topLeftPoint,
                bottomLeftPoint: bottomLeftPoint,
                bottomRightPoint: bottomRightPoint,
                topRightPoint: topRightPoint,
                isEnabled: isEnabled
            )
        )
    }
}

public struct _WarpPerspectiveEffectViewModifier: ViewModifier {
    var topLeftPoint: CGPoint
    var bottomLeftPoint: CGPoint
    var bottomRightPoint: CGPoint
    var topRightPoint: CGPoint
    var isEnabled: Bool
    
    public func body(content: Content) -> some View {
        content
            .visualEffect { content, proxy in
                let warpPerspective = warpPerspective(size: proxy.size)
                return content
                    .distortionEffect(
                        Shader(
                            function: ShaderLibrary.bundle(.module).warpPerspective,
                            arguments: [
                                .float3(
                                    warpPerspective[0, 0], warpPerspective[0, 1], warpPerspective[0, 2]
                                ),
                                .float3(
                                    warpPerspective[1, 0], warpPerspective[1, 1], warpPerspective[1, 2]
                                ),
                                .float3(
                                    warpPerspective[2, 0], warpPerspective[2, 1], warpPerspective[2, 2]
                                ),
                                .float2(proxy.size)
                            ]
                        ),
                        maxSampleOffset: .zero,
                        isEnabled: isEnabled
                    )
            }
    }
    
    nonisolated private func warpPerspective(size: CGSize) -> simd_float3x3 {
        let source = Quadrilateral(
            CGPoint(x: topLeftPoint.x      * size.width,
                    y: topLeftPoint.y      * size.height),
            CGPoint(x: bottomLeftPoint.x   * size.width,
                    y: bottomLeftPoint.y   * size.height),
            CGPoint(x: bottomRightPoint.x  * size.width,
                    y: bottomRightPoint.y  * size.height),
            CGPoint(x: topRightPoint.x     * size.width,
                    y: topRightPoint.y     * size.height),
        )
        let destination = Quadrilateral(
            CGPoint(x: 0,          y: 0),
            CGPoint(x: 0,          y: size.height),
            CGPoint(x: size.width, y: size.height),
            CGPoint(x: size.width, y: 0),
        )
        
        let perspectMatrix = source.perspectiveTransform(to: destination)
        return perspectMatrix.inverse
    }
}
