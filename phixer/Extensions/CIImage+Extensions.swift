//
//  CIImage+Extensions.swift
//  phixer
//
//  Created by Philip Price on 11/3/18.
//  Copyright © 2018 Nateemma. All rights reserved.
//

import Foundation
import CoreGraphics
import CoreImage

extension CIImage {
    
    // use the same context across all instances, as it is expensive to create
    private static var context:CIContext? = nil
    
    // get the current CIContext, creating it if necessary
    private static func getContext() -> CIContext? {
        if (CIImage.context == nil){
            CIImage.context = CIContext(options: [kCIContextUseSoftwareRenderer : false, kCIContextHighQualityDownsample : true ])
        }
        return CIImage.context
    }
    
    // creates a CGImage - useful for cases when the CIImage was not created from a CGImage (or UIImage)
    public func generateCGImage() -> CGImage? {
        let imgRect = CGRect(x: 0, y: 0, width: self.extent.width, height: self.extent.height)
        return CIImage.getContext()?.createCGImage(self, from: imgRect)
    }
    
    // get the associated CGImage, creating it if necessary
    public func getCGImage() -> CGImage? {
        if self.cgImage == nil {
            return self.generateCGImage()
        } else {
            return self.cgImage
        }
    }

    
    // resize a CIImage
    public func resize(size:CGSize) -> CIImage? {
        
        // get the CGImage for this CIImage
        let cgimage = self.getCGImage()
        
        // double-check that CGImage was created
        guard cgimage != nil else {
            log.error("Could not generate CGImage")
            return nil
        }
        
        // resize the CGImage and check result
        let cgimage2 = cgimage?.resize(size)
        guard cgimage2 != nil else {
            log.error("Could not resize CGImage")
            return nil
        }
        
        return CIImage(cgImage: cgimage2!)
    }
    
    // get a portrait Matte Image, if it exists (iOS12 and later)
    func portraitEffectsMatteImage() -> CIImage? {

        // get the CGImage for this CIImage
        var cgimage = self.cgImage
        if cgimage == nil {
            cgimage = self.generateCGImage()
        }
        
        // double-check that CGImage was created
        guard cgimage != nil else {
            log.error("Could not generate CGImage")
            return nil
        }
        
        if #available(iOS 12.0, *) {
            let matteData = self.portraitEffectsMatte
            if matteData != nil {
                return CIImage(portaitEffectsMatte: matteData!)
            } else {
                return nil
            }
        } else {
            // Fallback on earlier versions
            return nil
        }
    }
}
