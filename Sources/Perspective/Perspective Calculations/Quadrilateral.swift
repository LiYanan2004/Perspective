//
//  Quadrilateral.swift
//  Perspective
//
//  Original credits to https://rethunk.medium.com/perspective-transform-from-quadrilateral-to-quadrilateral-in-swift-using-simd-for-matrix-operations-15dc3f090860
//  Modified by Yanan Li on 2025/5/4.
//

import Foundation
import simd
import OSLog

struct Quadrilateral {
    /// 1x3 vector for point1
    var v00: simd_float3
    
    /// 1x3 vector for point2
    var v10: simd_float3
    
    /// 1x3 vector for point3
    var v11: simd_float3
    
    /// 1x3 vector for point4
    var v01: simd_float3
    
    /// | p1.x   p2.x   p3.x   p4.x  |
    /// | p1.y   p2.y   p3.y   p4.y  |
    /// |     1        1        1        1   |
    var matrix: float4x3 {
        float4x3(v00, v10, v11, v01)
    }
    
    /// Initialize Quadrilateral using Eberly's terminology.
    init(v00: simd_float3, v10: simd_float3, v11: simd_float3, v01: simd_float3) {
        self.v00 = v00
        self.v10 = v10
        self.v11 = v11
        self.v01 = v01
    }
    
    /// Initialize Quadrilateral with 2D points 1, 2, 3, 4 assigned to v00, v10, v11, v01
    init(_ point1: simd_float2, _ point2: simd_float2, _ point3: simd_float2, _ point4: simd_float2) {
        self.v00 = simd_float3(point1.x, point1.y, 1)
        self.v10 = simd_float3(point2.x, point2.y, 1)
        self.v11 = simd_float3(point3.x, point3.y, 1)
        self.v01 = simd_float3(point4.x, point4.y, 1)
    }
    
    /// Initialize Quadrilateral with 2D points 1, 2, 3, 4 assigned to v00, v10, v11, v01
    init(_ point1: CGPoint, _ point2: CGPoint, _ point3: CGPoint, _ point4: CGPoint) {
        self.v00 = simd_float3(Float(point1.x), Float(point1.y), 1.0)
        self.v10 = simd_float3(Float(point2.x), Float(point2.y), 1.0)
        self.v11 = simd_float3(Float(point3.x), Float(point3.y), 1.0)
        self.v01 = simd_float3(Float(point4.x), Float(point4.y), 1.0)
    }
    
    func perspectiveTransform(to another: Quadrilateral) -> float3x3 {
        // points of canonical quadrilateral used to calculate affine transform
        let canon = Triangle(simd_float2(0,0), simd_float2(1,0), simd_float2(0,1))
        
        // affine transform from canonical quadrilateral to p using points 00, 10, 01 but not 11
        let ptri = Triangle(self.v00, self.v10, self.v01)
        
        guard let Ap = canon.affineTransform(to: ptri) else {
            logger.error("Could not get affine transform for quadrilateral p. Fallback to identity.")
            return matrix_identity_float3x3
        }
        
        // affine transform from canonical quadrilateral to q using points 00, 10, 01 but not 11
        let qtri = Triangle(another.v00, another.v10, another.v01)
        
        guard let Aq = canon.affineTransform(to: qtri) else {
            logger.error("Could not get affine transform for quadrilateral q. Fallback to identity.")
            return matrix_identity_float3x3
        }
        
        let InvAp = Ap.inverse
        
        if InvAp.determinant.isNaN {
            logger.error("Could not get inverse of affine transform for quadrilateral p. Fallback to identity.")
            return matrix_identity_float3x3
        }
        
        let InvAq = Aq.inverse
        
        if InvAq.determinant.isNaN {
            logger.error("Could not get inverse of affine transform for quadrilateral q. Fallback to identity.")
            return matrix_identity_float3x3
        }
        
        // (a,b) is coordinate of p11 in canonical quadrilateral
        // (c,d) is coordinate of q11 in canonical quadrilateral
        let ap11 = InvAp * self.v11           // (x,y,1)
        let aq11 = InvAq * another.v11
        
        let cp11 = simd_float2(ap11.x / ap11.z, ap11.y / ap11.z)     // (x,y) in 2D plane
        let cq11 = simd_float2(aq11.x / aq11.z, aq11.y / aq11.z)
        
        let a = cp11.x
        let b = cp11.y
        let c = cq11.x
        let d = cq11.y
        
        let s = a + b - 1       // p is convex if s > 0
        let t = c + d - 1       // q is convex if t > 0
        
        let pconvex = s > 0
        let qconvex = t > 0
        
        if !pconvex || !qconvex {
            logger.error("""
            p is \(pconvex ? "convex" : "NOT convex"), s = \(s)"
            logger.error("q is \(qconvex ? "convex" : "NOT convex"), t = \(t)
            Fallback to identity.
            """)
            return matrix_identity_float3x3
        }
        
        //fractional linear transformation F from canonical p to canonical q
        
        // F = | bcs                   0    0   |
        //     |   0                 ads    0   |
        //     | b(cs - at)   a(ds - bt)    abt |
        // where
        // s = a + b - 1
        // t = c + d - 1
        
        // initialize float3x3 by columns
        let F = float3x3(
            simd_float3(b * c * s,  0,          b * (c * s - a * t)),
            simd_float3(0,          a * d * s,  a * (d * s - b * t)),
            simd_float3(0,          0,          a * b * t)
        )
        
        //"The 3 × 3 homography matrix H = Aq * F * Inv(Ap)"
        let H = Aq * F * InvAp
        
        //return transform along with ordered quadrilaterals
        return H
    }
}

fileprivate let logger = Logger(subsystem: "Perspective", category: "Quadrilateral")
