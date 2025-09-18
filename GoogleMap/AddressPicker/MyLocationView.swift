//
//  MyLocationView.swift
//  GoogleMap
//
//  Created by KONAMI on 2025/9/18.
//
import UIKit

class MyLocationView: UIView {
    private let triangleLayer = CAShapeLayer()
    private let circleLayer = CALayer()
    private let whiteCircleLayer = CALayer()
    private let gradientLayer = CAGradientLayer()
    
    private let whiteRatio: CGFloat = 22 / 46
    private let innerMinRatio: CGFloat = 12 / 46
    private let innerMaxRatio: CGFloat = 16 / 46
    private let triangleRectRatio: CGFloat = 20 / 46
    
    private let mainColor = UIColor(red: 0.04, green: 0.87, blue: 0.78, alpha: 1)
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setup()
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
    }
    
    override func didMoveToWindow() {
        super.didMoveToWindow()
        guard window != nil else { return }
        startCircleAnimation()
    }
    
    private func setup() {
        layer.addSublayer(gradientLayer)
        layer.addSublayer(triangleLayer)
        layer.addSublayer(whiteCircleLayer)
        layer.addSublayer(circleLayer)
       
        gradientLayer.colors = [mainColor.withAlphaComponent(0.8).cgColor,
                                mainColor.withAlphaComponent(0).cgColor]
        gradientLayer.masksToBounds = true
        gradientLayer.locations = [0, 0.8]
        gradientLayer.type = .radial
        gradientLayer.startPoint = CGPoint(x: 0.5, y: 0.5)
        gradientLayer.endPoint = CGPoint(x: 1, y: 1)
        
        whiteCircleLayer.backgroundColor = UIColor.white.cgColor
        
        circleLayer.backgroundColor = mainColor.cgColor
        triangleLayer.fillColor = mainColor.cgColor
    }
    
    override func layoutSubviews() {
        let gradientSize = bounds.width
        gradientLayer.frame = CGRect(x: 0, y: 0, width: gradientSize, height:  gradientSize)
        gradientLayer.position = CGPoint(x: bounds.width / 2, y: bounds.height / 2)
        gradientLayer.cornerRadius =  gradientSize / 2
        
        let whiteRadius = bounds.width * whiteRatio
        whiteCircleLayer.bounds = CGRect(x: 0, y: 0, width: whiteRadius, height: whiteRadius)
        whiteCircleLayer.cornerRadius = whiteRadius / 2
        whiteCircleLayer.position = CGPoint(x: bounds.width / 2, y: bounds.height / 2)
        whiteCircleLayer.shadowRadius = bounds.width / 2
        
        let radius = bounds.width * innerMinRatio
        circleLayer.bounds = CGRect(x: 0, y: 0, width: radius, height: radius)
        circleLayer.cornerRadius = radius / 2
        circleLayer.position = CGPoint(x: bounds.width / 2, y: bounds.height / 2)
        
        let triangleRectSide = bounds.width * triangleRectRatio
        triangleLayer.path = roundedTrianglePath(side: triangleRectSide, cornerRadius: 4).cgPath
        triangleLayer.position = CGPoint(x: bounds.width / 2 - triangleRectSide / 2, y: triangleRectSide / 8)
    }
    
    private func startCircleAnimation() {
        let anim = CABasicAnimation(keyPath: "transform.scale")
        anim.fromValue = 1
        anim.toValue   = innerMaxRatio / innerMinRatio
        anim.duration  = 1.0
        anim.autoreverses = true
        anim.repeatCount  = .infinity
        circleLayer.add(anim, forKey: "pulse")
    }
    
    func roundedTrianglePath(side: CGFloat, cornerRadius r: CGFloat = 1) -> UIBezierPath {
        let h = side * sqrt(3) / 2
        let p1 = CGPoint(x: side / 2, y: 0)
        let p2 = CGPoint(x: side,     y: h)
        let p3 = CGPoint(x: 0,        y: h)
        
        let points = [p1, p2, p3]
        let path = UIBezierPath()

        for i in 0..<3 {
            let prev = points[(i + 2) % 3]
            let curr = points[i]
            let next = points[(i + 1) % 3]

            let v1 = CGVector(dx: prev.x - curr.x, dy: prev.y - curr.y)
            let v2 = CGVector(dx: next.x - curr.x, dy: next.y - curr.y)

            let n1 = normalize(v1)
            let n2 = normalize(v2)


            let angle = acos(dot(n1, n2) * -1)
            let offset = r / sin(angle / 2)

            let cut1 = CGPoint(x: curr.x + n1.dx * offset,
                               y: curr.y + n1.dy * offset)
            let cut2 = CGPoint(x: curr.x + n2.dx * offset,
                               y: curr.y + n2.dy * offset)

            if i == 0 {
                path.move(to: cut1)
            } else {
                path.addLine(to: cut1)
            }
            path.addQuadCurve(to: cut2, controlPoint: curr)
        }

        path.close()
        return path
    }

    private func normalize(_ v: CGVector) -> CGVector {
        let len = sqrt(v.dx*v.dx + v.dy*v.dy)
        return CGVector(dx: v.dx/len, dy: v.dy/len)
    }
    private func dot(_ a: CGVector, _ b: CGVector) -> CGFloat {
        return a.dx*b.dx + a.dy*b.dy
    }

}
