//
//  ImageView.swift
//  Philter
//
//  Created by Philip Price on 9/17/16.
//  Copyright © 2016 Nateemma. All rights reserved.
//
import UIKit
import Neon


// View that contains an image with a label underneath

class ImageContainerView: UIView {
    
    var theme = ThemeManager.currentTheme()
    
    var imageView : UIImageView = UIImageView()
    var label : UILabel = UILabel()
    
    convenience init() {
        self.init(frame: CGRect.zero)
        
        self.backgroundColor = theme.backgroundColor
        self.layer.cornerRadius = 4.0
        self.layer.borderWidth = 1.0
        self.layer.borderColor = theme.borderColor.cgColor
        self.clipsToBounds = true
        
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        self.addSubview(imageView)
        
        label.textAlignment = .center
        label.textColor = theme.textColor
        //label.font = UIFont.systemFont(ofSize: 12.0)
        label.font = UIFont.systemFont(ofSize: 10.0, weight: UIFont.Weight.thin)
        self.addSubview(label)
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        imageView.anchorAndFillEdge(.top, xPad: 0, yPad: 0, otherSize: self.height * 0.7)
        label.alignAndFill(align: .underCentered, relativeTo: imageView, padding: 0)
    }
    

}

