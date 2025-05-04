//
//  Triangle.swift
//  Perspective
//
//  Original credits to https://rethunk.medium.com/perspective-transform-from-quadrilateral-to-quadrilateral-in-swift-using-simd-for-matrix-operations-15dc3f090860
//  Modified by Yanan Li on 2025/5/4.
//

import Foundation
import simd

/// Three points nominally defining a triangle, but possibly colinear.
struct Triangle {
    var point1: simd_float2
    var point2: simd_float2
    var point3: simd_float2
    
    /// | p1.x    p2.x      p3.x |
    /// | p1.y    p2.y      p3.y |
    /// |   1       1            1    |
    var matrix: float3x3 {
        float3x3(
            simd_float3(point1.x, point1.y, 1),
            simd_float3(point2.x, point2.y, 1),
            simd_float3(point3.x, point3.y, 1)
        )
    }
    
    init(_ point1: simd_float2, _ point2: simd_float2, _ point3: simd_float2) {
        self.point1 = point1
        self.point2 = point2
        self.point3 = point3
    }
    
    init(_ vector1: simd_float3, _ vector2: simd_float3, _ vector3: simd_float3) {
        point1 = simd_float2(vector1.x / vector1.z, vector1.y / vector1.z)
        point2 = simd_float2(vector2.x / vector2.z, vector2.y / vector2.z)
        point3 = simd_float2(vector3.x / vector3.z, vector3.y / vector3.z)
    }
    
    /// Three points are colinear if their determinant is zero. We assume close to colinear might as well be colinear.
    ///    | x1  x2  x3 |
    /// det | y1  y2  y3 |  = 0     -->    abs( det(M) )  < tolerance ?
    ///    |1 1  1 |
    func colinear(tolerance: Float = 0.01) -> Bool {
        abs(matrix.determinant) < tolerance
    }

    @available(*, deprecated, renamed: "matrix")
    func toMatrix() -> float3x3 {
        matrix
    }
    
    /// Finds the affine transform (translation, rotation, scale, ...) from one triangle to another.
    func affineTransform(to another: Triangle) -> float3x3? {
        // following example from https://stackoverflow.com/questions/18844000/transfer-coordinates-from-one-triangle-to-another-triangle
        // M * A = B
        // M = B * Inv(A)
        
        let A = self.matrix
        let invA = A.inverse
        
        if invA.determinant.isNaN {
            return nil
        }
        
        let B = another.matrix
        let M = B * invA
        
        return M
    }
}
