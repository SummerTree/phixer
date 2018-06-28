//
//  FilterParametersView.swift
//  FilterCam
//
//  Created by Philip Price on 10/6/16.
//  Copyright © 2016 Nateemma. All rights reserved.
//

import Foundation
import UIKit
import Neon


// Class responsible for laying out the Parameters associated with a filter

// Interface required of controlling View
protocol FilterParametersViewDelegate: class {
    func settingsChanged()
}


class FilterParametersView: UIView {
    
    //var isLandscape : Bool = false
    
    var currFilterDesc: FilterDescriptorInterface? = nil
    
    var initDone: Bool = false
    
    let sliderHeight: Float = 32.0
    
    let showButtons:Bool = false

    // display items
    
    var titleLabel:UILabel! = UILabel()
    var titleView: UIView! = UIView()
    var parameterView: UIView! = UIView()
    var scrollView: UIScrollView? = nil
    
    //var acceptButton: UIButton! = UIButton()
    //var cancelButton: UIButton! = UIButton()
    //var buttonContainerView: UIView! = UIView()
    
    var sliders: [UIView] = []
    
    var viewList:[UIView] = []
    
    // Colours
    let titleBackgroundColor:UIColor = UIColor.flatMint
    let titleTextColor:UIColor = UIColor.black
    let buttonBackgroundColor:UIColor = UIColor.flatSkyBlueDark
    let buttonTextColor:UIColor = UIColor.white
    let viewBackgroundColor:UIColor = UIColor.black
    let sliderTextColor:UIColor = UIColor.white
    
    
    // delegate for handling events
    weak var delegate: FilterParametersViewDelegate?
    
    
    
    convenience init(){
        self.init(frame: CGRect.zero)
    }
    
    
    fileprivate func initButton(_ button: UIButton){
        button.backgroundColor = buttonBackgroundColor
        button.titleLabel?.textColor = buttonTextColor
        button.titleLabel?.font = UIFont.systemFont(ofSize: 16)
        button.titleLabel?.textAlignment = .center
        button.frame.size.height = CGFloat(sliderHeight - 4.0)
    }
   

    
    fileprivate func initViews(){
        
        //if (!initDone && (currFilterDesc != nil)){
        if (currFilterDesc != nil){
            
            //self.backgroundColor = UIColor.flatGray()
            self.backgroundColor = viewBackgroundColor
            self.alpha = 0.9
            
            viewList = []
            
           
            //self.frame.size.width = self.frame.size.width - 16.0
            // height: title + sliders + buttons (or not)
            var f1, f2: CGFloat
            if (showButtons){
                f1 = 1.25*CGFloat((currFilterDesc?.numParameters)!) + 1.75
            } else {
                f1 = 1.25*CGFloat((currFilterDesc?.numParameters)!) + 1.25
            }
            f2 = CGFloat(sliderHeight)
            self.frame.size.height = f1 * f2
            layoutButtons()
            
            if (scrollView == nil) {
                var frame = self.frame
                frame.size.height = frame.size.height - titleView.frame.size.height
                scrollView = UIScrollView(frame: frame)
            }
            
            initDone = true
        }
    }
    
    
    fileprivate func layoutTitle(){
        
        guard (currFilterDesc != nil) else{
            return
        }
        
        titleLabel.frame.size.width = self.frame.size.width/3.0
        titleLabel.frame.size.height = CGFloat(sliderHeight*0.75)
        titleLabel.textColor = titleTextColor
        titleLabel.font = UIFont.systemFont(ofSize: 18)
        titleLabel.text = currFilterDesc?.title
        titleLabel.textAlignment = .center
        
        titleView.frame.size.width = self.frame.size.width - 16.0
        titleView.frame.size.height = CGFloat(sliderHeight*0.8)
        titleView.backgroundColor = titleBackgroundColor
        titleView.addSubview(titleLabel)
        
        //TODO: add left/right buttons to move between filters (and the interface to tell the view controller
        
        self.addSubview(titleView)

        //titleLabel.anchorInCenter(CGFloat(self.frame.size.width-8.0), height: CGFloat(sliderHeight))
        titleLabel.fillSuperview()
        
        log.verbose("Filter Title: \(String(describing: currFilterDesc?.title)) h:\(titleLabel.frame.size.height) w:\(titleLabel.frame.size.width)")
    }
  
    
    fileprivate func layoutButtons(){
        
        guard (currFilterDesc != nil) else{
            return
        }
        
        // TODO: "Reset" button
/*** Removed buttons for now
        initButton(acceptButton)
        acceptButton.setTitle("Accept", for: .normal)
        
        initButton(cancelButton)
        cancelButton.setTitle("Cancel", for: .normal)
        
        
        buttonContainerView.addSubview(acceptButton)
        buttonContainerView.addSubview(cancelButton)
        
        buttonContainerView.frame.size.width = self.frame.size.width
        buttonContainerView.frame.size.height = CGFloat(sliderHeight)
        
        self.addSubview(buttonContainerView)
        
        let pad = self.frame.size.width / 9
        buttonContainerView.groupAndFill(.horizontal, views: [acceptButton, cancelButton], padding: pad)

        
        // register handlers for the buttons
        acceptButton.addTarget(self, action: #selector(self.acceptDidPress), for: .touchUpInside)
        cancelButton.addTarget(self, action: #selector(self.cancelDidPress), for: .touchUpInside)
***/
    }
    

    fileprivate var gsliders: [GradientSlider?] = [nil, nil, nil, nil]

    fileprivate func layoutSliders(){
        
        guard (currFilterDesc != nil) else{
            return
        }
        
        var sliderConfig: ParameterSettings
        var slider: UISlider?
        var label: UILabel
        var sliderView: UIView
        var currColor: UIColor = UIColor.blue
        
        log.verbose("Laying out sliders...")
        sliders = []
        if ((currFilterDesc?.numParameters)! > 0){
            for i in 1 ... (currFilterDesc?.numParameters)!{
                
                if (currFilterDesc! is PresetDescriptor) {
                    // Preset Descriptor use the Lightroom/Photoshop scale
                    let preset:PresetDescriptor = currFilterDesc as! PresetDescriptor
                    sliderConfig = (preset.inputConfiguration[i-1])
                } else {
                    sliderConfig = (currFilterDesc?.parameterConfiguration[i-1])!
                }
                
                log.verbose("...(\(sliderConfig.title), \(sliderConfig.minimumValue), \(sliderConfig.maximumValue), \(sliderConfig.initialValue))")
                
                sliderView = UIView()
                sliderView.frame.size.width = self.frame.size.width
                sliderView.frame.size.height = CGFloat(sliderHeight*1.25)
                
                label = UILabel()
                label.text = sliderConfig.title
                label.frame.size.width = self.frame.size.width/3.0
                label.frame.size.height = CGFloat(sliderHeight/2.0)
                label.textAlignment = .center
                label.textColor = sliderTextColor
                label.font = UIFont.systemFont(ofSize: 14.0)
                sliderView.addSubview(label)
                
                if (!sliderConfig.isRGB){
                    slider = UISlider()
                    slider?.minimumValue = sliderConfig.minimumValue
                    slider?.maximumValue = sliderConfig.maximumValue
                    var value = currFilterDesc?.getParameter(i)
                    if (value == parameterNotSet){ value = sliderConfig.initialValue }
                    slider?.value = value!
                    log.verbose("value: \(value!)")
                    slider?.tag = i // let slider know the parameter order
                    slider?.isHidden = false
                    slider?.setNeedsUpdateConstraints()
                    slider?.frame.size.width = self.frame.size.width
                    slider?.frame.size.height = CGFloat(sliderHeight*0.75)
                    
                    attachSliderAction(slider!)
                    sliderView.addSubview(slider!)
                    //TODO: add bounds, current value
                    
                    sliderView.groupAndFill(.vertical, views: [label, slider!], padding: 2.0)
                } else {
                    // RGB Slider, need to deal with colors
                    log.debug("Gradient Slider requested")
                    gsliders[i] = GradientSlider()
                    gsliders[i]?.hasRainbow = true
                    //gsliders[i]?.setValue(value: 0.5) // middle colour
                    gsliders[i]?.setValue(hueFromColor(self.currFilterDesc?.getColorParameter(i))) // default for class
                    gsliders[i]?.tag = i // let slider know the parameter order
                    gsliders[i]?.isHidden = false
                    gsliders[i]?.setNeedsUpdateConstraints()
                    gsliders[i]?.frame.size.width = self.frame.size.width
                    gsliders[i]?.frame.size.height = CGFloat(sliderHeight*0.75)
                    
                    //TODO: figure out current saturation & brightness
                    let currSat = CGFloat(1.0)
                    let currBright = CGFloat(1.0)
                    
                    gsliders[i]?.setGradientForHueWithSaturation(currSat,brightness:currBright)
                    gsliders[i]?.actionBlock = { slider, value in
                        
                        //First disable animations so we get instantaneous updates
                        CATransaction.begin()
                        CATransaction.setValue(true, forKey: kCATransactionDisableActions)
                        
                        //Update the thumb color to match the new value
                        currColor = UIColor(hue: value, saturation: currSat, brightness: currBright, alpha: 1.0)
                        self.gsliders[i]?.thumbColor = currColor
                        
                        CATransaction.commit()
                        self.currFilterDesc?.setColorParameter(i, color: currColor)
                    }
                    //attachColorSliderAction(gsliders[i]!)
                    sliderView.addSubview(gsliders[i]!)
                    sliderView.groupAndFill(.vertical, views: [label, gsliders[i]!], padding: 1.0)
                }
                
                sliders.append(sliderView)
                parameterView.addSubview(sliderView)
            }
        }
        
        scrollView?.addSubview(parameterView)
        self.addSubview(scrollView!)

    }
    
    
    
    // get the hue value (0.0-1.0) from a Color type
    fileprivate func hueFromColor(_ color:UIColor?)->CGFloat{
        
        var h:CGFloat = 0.0
        var s:CGFloat = 0.0
        var l:CGFloat = 0.0
        var a:CGFloat = 1.0
        var c: UIColor
        
        if (color == nil){
            c = UIColor.blue
        } else {
            c = color!
        }
        
        c.getHue(&h, saturation: &s, brightness: &l, alpha: &a)
        return h
    }
    
    
    // Attaches an action handler based on the slider index
    fileprivate func attachSliderAction(_ slider:UISlider){
        /*
        let index = slider.tag
        switch (index){
        case 1:
            slider.addTarget(self, action: #selector(self.slider1ValueDidChange), for: .valueChanged)
            break
        case 2:
            slider.addTarget(self, action: #selector(self.slider2ValueDidChange), for: .valueChanged)
            break
        case 3:
            slider.addTarget(self, action: #selector(self.slider3ValueDidChange), for: .valueChanged)
           break
        case 4:
            slider.addTarget(self, action: #selector(self.slider4ValueDidChange), for: .valueChanged)
            break
        case 5:
            slider.addTarget(self, action: #selector(self.slider5ValueDidChange), for: .valueChanged)
            break
        default:
            log.error("Invalid slider index: \(index)")
            break
        }
 */
        slider.addTarget(self, action: #selector(self.sliderValueDidChange), for: .valueChanged)
        
        // shared callback for when user ends changing any slider (intended as an update trigger, don't need the value)
        slider.addTarget(self, action: #selector(self.slidersDidEndChange), for: .touchUpInside)
    }
    
    
    
    // Attaches an action handler based on the slider index
    fileprivate func attachColorSliderAction(_ gslider:GradientSlider){
        /***
        let index = gslider.tag
        switch (index){
        case 1:
            gslider.addTarget(self, action: #selector(self.colorSlider1ValueDidChange), for: .valueChanged)
            break
        case 2:
            gslider.addTarget(self, action: #selector(self.colorSlider2ValueDidChange), for: .valueChanged)
            break
        case 3:
            gslider.addTarget(self, action: #selector(self.colorSlider3ValueDidChange), for: .valueChanged)
            break
        case 4:
            gslider.addTarget(self, action: #selector(self.colorSlider4ValueDidChange), for: .valueChanged)
            break
        default:
            log.error("Invalid slider index: \(index)")
            break
        }
        ***/
        
        gslider.addTarget(self, action: #selector(self.colorSliderValueDidChange), for: .valueChanged)
       
        // shared callback for when user ends changing any slider (intended as an update trigger, don't need the value)
        gslider.addTarget(self, action: #selector(self.gslidersDidEndChange), for: .touchUpInside)
    }
    
    
    fileprivate func finishLayout(){
        // add the views to the list in the order of display

        // Place the tile at the top, buttons at the bottom and sliders distributed in between
        titleView.anchorAndFillEdge(.top, xPad: 2.0, yPad: 2.0, otherSize: titleView.frame.size.height)
/*** removed buttons for now
        if (showButtons){
            buttonContainerView.anchorAndFillEdge(.bottom, xPad: 2.0, yPad: 2.0, otherSize: buttonContainerView.frame.size.height)
        }
 ***/
        if ((currFilterDesc?.numParameters)! > 0){
            //self.groupInCenter(.vertical, views: sliders, padding: 1.0, width: sliders[0].frame.size.width, height: sliders[0].frame.size.height)
            let n:CGFloat = CGFloat((currFilterDesc?.numParameters)!)
            //let h:CGFloat =  (self.frame.size.height - titleView.frame.size.height) / n
            let h:CGFloat =  CGFloat(sliderHeight) * n
            //self.groupInCenter(.vertical, views: sliders, padding: 1.0, width: sliders[0].frame.size.width, height: h)

            //self.groupAndAlign(.vertical, andAlign: .underCentered, views: sliders, relativeTo: titleView, padding: 1.0, width: sliders[0].frame.size.width, height: h)}
            parameterView.frame.size.width = titleView.frame.size.width
            parameterView.frame.size.height = h
            //parameterView.groupInCenter(.vertical, views: sliders, padding: 1.0, width: parameterView.frame.size.width, height: h)
            parameterView.groupAndFill(.vertical, views: sliders, padding: 1.0)
            scrollView?.contentSize = parameterView.frame.size
            scrollView?.alignAndFill(.underCentered, relativeTo: titleView, padding: 0, offset: 0)
        }

    }
    
    
    fileprivate func clearSubviews(){
        for v in parameterView.subviews{
            v.removeFromSuperview()
        }
        if (scrollView != nil){
            for v in (scrollView?.subviews)!{
                v.removeFromSuperview()
            }
        }
        for v in self.subviews{
            v.removeFromSuperview()
        }
    }
    
    
    fileprivate func layoutUI(){
        clearSubviews()
        self.isHidden = false
        initViews()
        layoutTitle()
        layoutSliders()
        if (showButtons){ layoutButtons() }
        finishLayout()
    }
    
    
    override func layoutSubviews() {
        super.layoutSubviews()
        // don't do anything until filter is set
    }
    
    
    open func dismiss(){
        UIView.animate(withDuration: 0.5, animations: {
            self.alpha = 0 }) { _ in
            self.clearSubviews()
            self.isHidden = true
            //self.removeFromSuperview()
        }
    }
    
    open func setFilter(_ descriptor:FilterDescriptorInterface?){
        
        // if no filter then clear sub-views and hide view, otherwise re-build based on the filter descriptor
        if (descriptor == nil)  {
            clearSubviews()
            self.isHidden = false
        } else {
            
            currFilterDesc = descriptor

            let filter = currFilterDesc?.filter
            if (filter != nil){
                log.debug("filter: \(String(describing: currFilterDesc?.key)) address:\(Utilities.addressOf(filter!)) ()")
            }
            let filterGroup = currFilterDesc?.filterGroup
            if (filterGroup != nil){
                log.debug("filter: \(String(describing: currFilterDesc?.key)) address:\(Utilities.addressOf(filterGroup!))")
            }

            currFilterDesc?.stashParameters() // save initial values in case the user cancels

            
            layoutUI()
        }
    }
    
    func updateFilterTargets(){
        if (currFilterDesc?.filter != nil){
            let targets = currFilterDesc?.filter?.targets
            for (target, index) in targets! {
                currFilterDesc?.filter?.transmitPreviousImage(to: target, atIndex: index)
            }
        } else if (currFilterDesc?.filterGroup != nil){
            let targets = currFilterDesc?.filterGroup?.targets
            for (target, index) in targets! {
                currFilterDesc?.filterGroup?.transmitPreviousImage(to: target, atIndex: index)
            }
        }

    }
    
    //MARK: - touch handlers
    
    func acceptDidPress() {
        
        // value is set as sliders are moved, so no need to do anything except clean up and return
        dismiss()
    }
    
    func cancelDidPress(){
        // restore saved parameters
        currFilterDesc?.restoreParameters()
        dismiss()
    }
    
    
    @objc func sliderValueDidChange(_ sender:UISlider!){
        currFilterDesc?.setParameter(sender.tag, value: sender.value)
        //updateFilterTargets()
    }
    
    
    func slider1ValueDidChange(_ sender:UISlider!){
        currFilterDesc?.setParameter(1, value: sender.value)
        updateFilterTargets()
    }
    
    func slider2ValueDidChange(_ sender:UISlider!){ currFilterDesc?.setParameter(2, value: sender.value) }
    
    func slider3ValueDidChange(_ sender:UISlider!){ currFilterDesc?.setParameter(3, value: sender.value) }
    
    func slider4ValueDidChange(_ sender:UISlider!){ currFilterDesc?.setParameter(4, value: sender.value) }
    
    func slider5ValueDidChange(_ sender:UISlider!){ currFilterDesc?.setParameter(5, value: sender.value) }
    
    func colorSlider1ValueDidChange(_ sender:GradientSlider!){ currFilterDesc?.setColorParameter(1, color: (gsliders[0]?.getSelectedColor())!) }
    
    func colorSlider2ValueDidChange(_ sender:GradientSlider!){ currFilterDesc?.setColorParameter(2, color: (gsliders[1]?.getSelectedColor())!) }
    
    func colorSlider3ValueDidChange(_ sender:GradientSlider!){ currFilterDesc?.setColorParameter(3, color: (gsliders[2]?.getSelectedColor())!) }
    
    func colorSlider4ValueDidChange(_ sender:GradientSlider!){ currFilterDesc?.setColorParameter(4, color: (gsliders[3]?.getSelectedColor())!) }
    
    @objc func colorSliderValueDidChange(_ sender:GradientSlider!){
        let index = sender.tag
        currFilterDesc?.setColorParameter(index, color: (gsliders[index-1]?.getSelectedColor())!)
    }
    
    @objc func slidersDidEndChange(_ sender:UISlider!){
        log.verbose("Settings changed for slider \(sender.tag)")
        delegate?.settingsChanged()
    }
    
    @objc func gslidersDidEndChange(_ sender:GradientSlider!){
        log.verbose("Settings changed for slider \(sender.tag)")
        delegate?.settingsChanged()
    }
    

}
