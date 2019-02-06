//
//  GradientSlider.swift
//  GradientSlider
//
//  Created by Jonathan Hull on 8/5/15.
//  Copyright © 2015 Jonathan Hull. All rights reserved.
//

import UIKit

@IBDesignable class GradientSlider: UIControl {
    
    var theme = ThemeManager.currentTheme()
    

    static var defaultThickness:CGFloat = 2.0
    static var defaultThumbSize:CGFloat = 28.0
    
    //MARK: Properties
    @IBInspectable var hasRainbow:Bool  = false {didSet{updateTrackColors()}}//Uses saturation & lightness from minColor
    @IBInspectable var minColor:UIColor = UIColor.blue {didSet{updateTrackColors()}}
    @IBInspectable var maxColor:UIColor = UIColor.orange {didSet{updateTrackColors()}}
    
    @IBInspectable var value: CGFloat {
        get{return _value}
        //set{setValue(value:newValue, animated:true)}
        set{setValue(newValue, animated:true)}
    }
    
    func setValue(_ value:CGFloat, animated:Bool = true) {
        _value = max(min(value,self.maximumValue),self.minimumValue)
        updateThumbPosition(animated: animated)
    }
    
    
    @IBInspectable var minimumValue: CGFloat = 0.0 // default 0.0. the current value may change if outside new min value
    @IBInspectable var maximumValue: CGFloat = 1.0 // default 1.0. the current value may change if outside new max value
    
    @IBInspectable var minimumValueImage: UIImage? = nil { // default is nil. image that appears to left of control (e.g. speaker off)
        didSet{
            if let img = minimumValueImage {
                let imgLayer = _minTrackImageLayer ?? {
                    let l = CALayer()
                    l.anchorPoint = CGPoint(x:0.0, y:0.5)
                    self.layer.addSublayer(l)
                    return l
                }()
                imgLayer.contents = img.cgImage
                imgLayer.bounds = CGRect(x:0, y:0, width:img.size.width, height:img.size.height)
                _minTrackImageLayer = imgLayer
                    
            }else{
                _minTrackImageLayer?.removeFromSuperlayer()
                _minTrackImageLayer = nil
            }
            self.layer.needsLayout()
        }
    }
    @IBInspectable var maximumValueImage: UIImage? = nil { // default is nil. image that appears to right of control (e.g. speaker max)
        didSet{
            if let img = maximumValueImage {
                let imgLayer = _maxTrackImageLayer ?? {
                    let l = CALayer()
                    l.anchorPoint = CGPoint(x:1.0, y:0.5)
                    self.layer.addSublayer(l)
                    return l
                    }()
                imgLayer.contents = img.cgImage
                imgLayer.bounds = CGRect(x:0, y:0, width:img.size.width, height:img.size.height)
                _maxTrackImageLayer = imgLayer
                
            }else{
                _maxTrackImageLayer?.removeFromSuperlayer()
                _maxTrackImageLayer = nil
            }
            self.layer.needsLayout()
        }
    }
    
    var continuous: Bool = true // if set, value change events are generated any time the value changes due to dragging. default = YES
    
    var actionBlock:(GradientSlider,CGFloat)->() = {slider,newValue in }
    
    @IBInspectable var thickness:CGFloat = defaultThickness {
        didSet{
            _trackLayer.cornerRadius = thickness / 2.0
            self.layer.setNeedsLayout()
        }
    }
    
    var trackBorderColor:UIColor? {
        set{
            _trackLayer.borderColor = newValue?.cgColor
        }
        get{
            if let color = _trackLayer.borderColor {
                return UIColor(cgColor: color)
            }
            return nil
        }
    }
    
    var trackBorderWidth:CGFloat {
        set{
            _trackLayer.borderWidth = newValue
        }
        get{
            return _trackLayer.borderWidth
        }
    }
    
    var thumbSize:CGFloat = defaultThumbSize {
        didSet{
            _thumbLayer.cornerRadius = thumbSize / 2.0
            _thumbLayer.bounds = CGRect(x:0, y:0, width:thumbSize, height:thumbSize)
            self.invalidateIntrinsicContentSize()
        }
    }
    
    @IBInspectable var thumbIcon:UIImage? = nil {
        didSet{
            _thumbIconLayer.contents = thumbIcon?.cgImage
        }
    }
    
    var thumbColor:UIColor {
        get {
            if let color = _thumbIconLayer.backgroundColor {
                return UIColor(cgColor: color)
            }
            return theme.titleTextColor
        }
        set {
            _thumbIconLayer.backgroundColor = newValue.cgColor
            thumbIcon = nil
        }
    }
    
    //MARK: - Convienience Colors
    
    func setGradientForHueWithSaturation(_ saturation:CGFloat,brightness:CGFloat){
        minColor = UIColor(hue: 0.0, saturation: saturation, brightness: brightness, alpha: 1.0)
        hasRainbow = true
    }
    
    func setGradientForSaturationWithHue(_ hue:CGFloat,brightness:CGFloat){
        hasRainbow = false
        minColor = UIColor(hue: hue, saturation: 0.0, brightness: brightness, alpha: 1.0)
        maxColor = UIColor(hue: hue, saturation: 1.0, brightness: brightness, alpha: 1.0)
    }
    
    func setGradientForBrightnessWithHue(_ hue:CGFloat,saturation:CGFloat){
        hasRainbow = false
        minColor = theme.backgroundColor
        maxColor = UIColor(hue: hue, saturation: saturation, brightness: 1.0, alpha: 1.0)
    }
    
    func setGradientForRedWithGreen(_ green:CGFloat,blue:CGFloat){
        hasRainbow = false
        minColor = UIColor(red: 0.0, green: green, blue: blue, alpha: 1.0)
        maxColor = UIColor(red: 1.0, green: green, blue: blue, alpha: 1.0)
    }
    
    func setGradientForGreenWithRed(_ red:CGFloat,blue:CGFloat){
        hasRainbow = false
        minColor = UIColor(red: red, green: 0.0, blue: blue, alpha: 1.0)
        maxColor = UIColor(red: red, green: 1.0, blue: blue, alpha: 1.0)
    }
    
    func setGradientForBlueWithRed(_ red:CGFloat,green:CGFloat){
        hasRainbow = false
        minColor = UIColor(red: red, green: green, blue: 0.0, alpha: 1.0)
        maxColor = UIColor(red: red, green: green, blue: 1.0, alpha: 1.0)
    }
    
    func setGradientForGrayscale(){
        hasRainbow = false
        minColor = UIColor.black
        maxColor = UIColor.white
    }
    
    
    //MARK: - Private Properties
    
    fileprivate var _value:CGFloat = 0.0 // default 0.0. this value will be pinned to min/max
    
    fileprivate lazy var _thumbLayer:CALayer = {
        let thumb = CALayer()
        thumb.cornerRadius = GradientSlider.defaultThumbSize/2.0
        thumb.bounds = CGRect(x:0, y:0, width:GradientSlider.defaultThumbSize, height:GradientSlider.defaultThumbSize)
        thumb.backgroundColor = theme.titleTextColor.cgColor
        thumb.shadowColor = theme.backgroundColor.cgColor
        thumb.shadowOffset = CGSize(width:0.0, height:2.5)
        thumb.shadowRadius = 2.0
        thumb.shadowOpacity = 0.25
        thumb.borderColor = theme.borderColor.withAlphaComponent(0.15).cgColor
        thumb.borderWidth = 0.5
        return thumb
    }()
    
    fileprivate lazy var _trackLayer:CAGradientLayer = {
        let track = CAGradientLayer()
        track.cornerRadius = GradientSlider.defaultThickness / 2.0
        track.startPoint = CGPoint(x:0.0, y:0.5)
        track.endPoint = CGPoint(x:1.0, y:0.5)
        track.locations = [0.0,1.0]
        track.colors = [UIColor.blue.cgColor,UIColor.orange.cgColor]
        track.borderColor = theme.borderColor.cgColor
        return track
    }()
    
    fileprivate var _minTrackImageLayer:CALayer? = nil
    fileprivate var _maxTrackImageLayer:CALayer? = nil
    
    fileprivate lazy var _thumbIconLayer:CALayer = {
        let size = GradientSlider.defaultThumbSize - 4
        let iconLayer = CALayer()
        iconLayer.cornerRadius = size/2.0
        iconLayer.bounds = CGRect(x:0, y:0, width:size, height:size)
        iconLayer.backgroundColor = theme.borderColor.cgColor
        return iconLayer
    }()
    
    //MARK: - Init
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        commonSetup()
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        
        minColor = aDecoder.decodeObject(forKey: "minColor") as? UIColor ?? UIColor.lightGray
        maxColor = aDecoder.decodeObject(forKey: "maxColor") as? UIColor ?? UIColor.darkGray
        
        value = aDecoder.decodeObject(forKey: "value") as? CGFloat ?? 0.0
        minimumValue = aDecoder.decodeObject(forKey: "minimumValue") as? CGFloat ?? 0.0
        maximumValue = aDecoder.decodeObject(forKey: "maximumValue") as? CGFloat ?? 1.0

        minimumValueImage = aDecoder.decodeObject(forKey: "minimumValueImage") as? UIImage
        maximumValueImage = aDecoder.decodeObject(forKey: "maximumValueImage") as? UIImage
        
        thickness = aDecoder.decodeObject(forKey: "thickness") as? CGFloat ?? 2.0
        
        thumbIcon = aDecoder.decodeObject(forKey: "thumbIcon") as? UIImage
        
        commonSetup()
    }
    

    override func encode(with aCoder:NSCoder) {
        super.encode(with:aCoder)
        
        aCoder.encode(minColor, forKey: "minColor")
        aCoder.encode(maxColor, forKey: "maxColor")
        
        aCoder.encode(value, forKey: "value")
        aCoder.encode(minimumValue, forKey: "minimumValue")
        aCoder.encode(maximumValue, forKey: "maximumValue")
        
        aCoder.encode(minimumValueImage, forKey: "minimumValueImage")
        aCoder.encode(maximumValueImage, forKey: "maximumValueImage")
        
        aCoder.encode(thickness, forKey: "thickness")
        
        aCoder.encode(thumbIcon, forKey: "thumbIcon")
        
    }
    
    fileprivate func commonSetup() {
        self.layer.delegate = self
        self.layer.addSublayer(_trackLayer)
        self.layer.addSublayer(_thumbLayer)
        _thumbLayer.addSublayer(_thumbIconLayer)
    }
    
    //MARK: - Layout
    
    /*** Swift 2
    override func intrinsicContentSize()->CGSize {
        return CGSize(width: UIViewNoIntrinsicMetric, height: thumbSize)
    }
    ***/
    
    override open var intrinsicContentSize: CGSize {
        return CGSize(width: UIView.noIntrinsicMetric, height: thumbSize)
    }
    
    /*** Swift 2
    override func alignmentRectInsets() -> UIEdgeInsets {
        return UIEdgeInsetsMake(4.0, 2.0, 4.0, 2.0)
    }
     ***/
    
    override open var alignmentRectInsets: UIEdgeInsets {
        return UIEdgeInsets(top: 4.0, left: 2.0, bottom: 4.0, right: 2.0)
    }
    
    override func layoutSublayers(of layer: CALayer) {
//        super.layoutSublayersOfLayer(layer)
        
        if layer != self.layer {return}
        
        var w = self.bounds.width
        let h = self.bounds.height
        var left:CGFloat = 2.0
        
        if let minImgLayer = _minTrackImageLayer {
            minImgLayer.position = CGPoint(x:0.0, y:h/2.0)
            left = minImgLayer.bounds.width + 13.0
        }
        w -= left
        
        if let maxImgLayer = _maxTrackImageLayer {
            maxImgLayer.position = CGPoint(x:self.bounds.width, y:h/2.0)
            w -= (maxImgLayer.bounds.width + 13.0)
        }else{
            w -= 2.0
        }
        
        _trackLayer.bounds = CGRect(x:0, y:0, width:w, height:thickness)
        _trackLayer.position = CGPoint(x:w/2.0 + left, y:h/2.0)
        
        let halfSize = thumbSize/2.0
        var layerSize = thumbSize - 4.0
        if let icon = thumbIcon {
            layerSize = min(max(icon.size.height,icon.size.width),layerSize)
            _thumbIconLayer.cornerRadius = 0.0
            _thumbIconLayer.backgroundColor = UIColor.clear.cgColor
        }else{
            _thumbIconLayer.cornerRadius = layerSize/2.0
        }
        _thumbIconLayer.position = CGPoint(x:halfSize, y:halfSize)
        _thumbIconLayer.bounds = CGRect(x:0, y:0, width:layerSize, height:layerSize)
        
        
        updateThumbPosition(animated: false)
    }
    
    
    
    //MARK: - Touch Tracking
    

    override func beginTracking(_ touch: UITouch, with event: UIEvent?) -> Bool {
        let pt = touch.location(in: self)
        
        let center = _thumbLayer.position
        let diameter = max(thumbSize,44.0)
        let r = CGRect(x:center.x - diameter/2.0, y:center.y - diameter/2.0, width:diameter, height:diameter)
        if r.contains(pt){
            sendActions(for: UIControl.Event.touchDown)
            return true
        }
        return false
    }
    
    override func continueTracking(_ touch: UITouch, with event: UIEvent?) -> Bool {
        let pt = touch.location(in: self)
        let newValue = valueForLocation(pt)
        //setValue(value:newValue, animated: false)
        setValue(newValue, animated: false)
        if(continuous){
            sendActions(for: UIControl.Event.valueChanged)
            actionBlock(self,newValue)
        }
        return true
    }
    
    override func endTracking(_ touch: UITouch?, with event: UIEvent?) {
        if let pt = touch?.location(in: self){
            let newValue = valueForLocation(pt)
            //setValue(value:newValue, animated: false)
            setValue(newValue, animated: false)
        }
        actionBlock(self,_value)
        sendActions(for: [UIControl.Event.valueChanged, UIControl.Event.touchUpInside])

    }
    
    //MARK: - Private Functions
    
    fileprivate func updateThumbPosition(animated animate:Bool){
        let diff = maximumValue - minimumValue
        let perc = CGFloat((value - minimumValue) / diff)
        
        let halfHeight = self.bounds.height / 2.0
        let trackWidth = _trackLayer.bounds.width - thumbSize
        let left = _trackLayer.position.x - trackWidth/2.0
        
        if !animate{
            CATransaction.begin() //Move the thumb position without animations
            CATransaction.setValue(true, forKey: kCATransactionDisableActions)
            _thumbLayer.position = CGPoint(x:left + (trackWidth * perc), y:halfHeight)
            CATransaction.commit()
        }else{
            _thumbLayer.position = CGPoint(x:left + (trackWidth * perc), y:halfHeight)
        }
    }
    
    fileprivate func valueForLocation(_ point:CGPoint)->CGFloat {
        
        var left = self.bounds.origin.x
        var w = self.bounds.width
        if let minImgLayer = _minTrackImageLayer {
            let amt = minImgLayer.bounds.width + 13.0
            w -= amt
            left += amt
        }else{
            w -= 2.0
            left += 2.0
        }
        
        if let maxImgLayer = _maxTrackImageLayer {
            w -= (maxImgLayer.bounds.width + 13.0)
        }else{
            w -= 2.0
        }
        
        let diff = CGFloat(self.maximumValue - self.minimumValue)
        
        let perc = max(min((point.x - left) / w ,1.0), 0.0)
        
        return (perc * diff) + CGFloat(self.minimumValue)
    }
    
    fileprivate func updateTrackColors() {
        if !hasRainbow {
            _trackLayer.colors = [minColor.cgColor,maxColor.cgColor]
            _trackLayer.locations = [0.0,1.0]
            return
        }
        //Otherwise make a rainbow with the saturation & lightness of the min color
        var h:CGFloat = 0.0
        var s:CGFloat = 0.0
        var l:CGFloat = 0.0
        var a:CGFloat = 1.0
        
        minColor.getHue(&h, saturation: &s, brightness: &l, alpha: &a)
        
        //TOFIX: Colors start at hue of 0.0, not the minColor
        let cnt = 40
        let step:CGFloat = 1.0 / CGFloat(cnt)
        let locations:[CGFloat] = (0...cnt).map({ i in return (step * CGFloat(i))})
        _trackLayer.colors = locations.map({return UIColor(hue: $0, saturation: s, brightness: l, alpha: a).cgColor})
        _trackLayer.locations = locations as [NSNumber]?
    }
    
    //MARK: - retrieve selection
    
    open func getSelectedColor()->UIColor{
        var h:CGFloat = 0.0
        var s:CGFloat = 0.0
        var l:CGFloat = 0.0
        var a:CGFloat = 1.0
        
        minColor.getHue(&h, saturation: &s, brightness: &l, alpha: &a)
        log.debug("Hue: \(_value)")
        return UIColor(hue: _value, saturation: s, brightness: l, alpha: a)
    }
}


