//
//  DetailCardContentView.swift
//  Talklets
//
//  Created by Wang Yu on 2/9/16.
//  Copyright © 2016 Yu Wang. All rights reserved.
//

import UIKit

class TriangleView: UIView {
    
    var triangleView: UIView = UIView()
    
    override func layoutSubviews() {
        super.layoutSubviews()
        let triangleHeight: CGFloat = self.bounds.height
        let layerWidth = self.layer.frame.width
        
        triangleView.frame = CGRect(x: 0, y: 0, width: layerWidth, height: triangleHeight)
        triangleView.backgroundColor = .white
        self.addSubview(triangleView)
        
        let bezierPath = UIBezierPath()
        bezierPath.move(to: CGPoint(x:0 , y: triangleHeight))
        bezierPath.addLine(to: CGPoint(x:layerWidth , y: triangleHeight))
        bezierPath.addLine(to: CGPoint(x:layerWidth , y: 0))
        bezierPath.close()
        
        let shapeLayer = CAShapeLayer()
        shapeLayer.path = bezierPath.cgPath
        triangleView.layer.mask = shapeLayer
    }

}
