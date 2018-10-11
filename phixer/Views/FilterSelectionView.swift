//
//  FilterSelectionView.swift
//  phixer
//
//  Created by Philip Price on 10/18/16.
//  Copyright © 2016 Nateemma. All rights reserved.
//

import Foundation
import CoreImage

// A view that implements an iCarousel scrolling list for showing filters



// Interface required of controlling View
protocol FilterSelectionViewDelegate: class {
    func filterSelected(_ key:String)
}


class FilterSelectionView: UIView, iCarouselDelegate, iCarouselDataSource{
    
    fileprivate var initDone:Bool = false
    fileprivate var filterCarousel:iCarousel? = iCarousel()
    fileprivate var filterManager: FilterManager? = FilterManager.sharedInstance
    fileprivate var filterNameList: [String] = []
    fileprivate var filterViewList: [RenderContainerView] = []
    fileprivate var filterCategory:String = FilterManager.defaultCategory
    fileprivate var filterLabel:UILabel = UILabel()
    fileprivate var carouselHeight:CGFloat = 80.0
    fileprivate var camera: CameraCaptureHelper? = nil
    fileprivate var currFilter: FilterDescriptor? = nil
    
    fileprivate var inputSource: InputSource = .sample
    fileprivate var sourceInput:CIImage? = nil
    
    fileprivate var blendImageFull:UIImage? = nil
    fileprivate var blend:CIImage? = nil
    
    fileprivate var sampleImageFull:UIImage? = nil
    fileprivate var sampleImageSmall:UIImage? = nil
    
    
    fileprivate var previewInput: CIImage? = nil
    
    fileprivate var currIndex:Int = -1
    //fileprivate var cameraPreviewInput: CIImage? = nil
    //fileprivate var previewURL: URL? = nil
    
    // delegate for handling events
    weak var delegate: FilterSelectionViewDelegate?
    
    ///////////////////////////////////
    //MARK: - Public accessors
    ///////////////////////////////////
    
    // enum describing th inpiut source for previewing filters
    public enum InputSource {
        case camera
        case sample
        case photo
    }
    
    
    func setInputSource(_ source: InputSource){
        inputSource = source
        switch (inputSource){
        case .camera:
            sourceInput = ImageManager.getCurrentSampleInput() // start with sample input, switch to camera later
            camera?.start()
        case .sample:
            camera?.stop()
            sourceInput = ImageManager.getCurrentSampleInput()
        case .photo:
            camera?.stop()
            sourceInput = ImageManager.getCurrentEditInput()
        }
    }
    
    fileprivate func getInputSource()->CIImage?{
        switch (inputSource){
        case .camera:
            return sourceInput // updated in callback
        case .sample:
            sourceInput = ImageManager.getCurrentSampleInput()
        case .photo:
            sourceInput = ImageManager.getCurrentEditInput()
        }
        return sourceInput
    }
    
    func setFilterCategory(_ category:String){
        
        if ((category != filterCategory) || (currIndex<0)){
            
            log.debug("Filter category set to: \(category)")
            
            filterCategory = category
            //filterNameList = (filterManager?.getFilterList(category))!
            filterNameList = (filterManager?.getShownFilterList(category))!
            //filterNameList.sort(by: { (value1: String, value2: String) -> Bool in return value1 < value2 }) // sort ascending
            log.verbose("(\(category)) Found: \(filterNameList.count) filters")
            
            // need to clear everything from carousel, so just create a new one...
            filterCarousel?.removeFromSuperview()
            filterCarousel = iCarousel()
            filterCarousel?.frame = self.frame
            self.addSubview(filterCarousel!)
            
            filterCarousel?.dataSource = self
            filterCarousel?.delegate = self
            
            // Pre-allocate views for the filters, makes it much easier and we can update in the background if needed
            filterViewList = []
            
            var descriptor: FilterDescriptor?
            if (filterNameList.count > 0){
                for i in (0...filterNameList.count-1) {
                    descriptor = filterManager?.getFilterDescriptor(key:filterNameList[i])
                    if (descriptor != nil){
                        if !((filterManager?.isHidden(key: filterNameList[i]))!){
                            filterViewList.append(createFilterContainerView((descriptor)!))
                        } else {
                            log.debug("Not showing filter: \(String(describing: descriptor?.key))")
                        }
                    } else {
                        log.error("NIL Descriptor for:\(filterNameList[i])")
                    }
                }
                
                updateVisibleItems()
                
                filterCarousel?.setNeedsLayout()
            } else { // no filters in this category (not an error)
                filterCarousel?.removeFromSuperview()
            }
        } else {
            //log.verbose("Ignored \(category)->\(filterCategory) change")
        }
    }
    
    func update(){
        updateVisibleItems()
    }
    
    func getCurrentSelection()->String{
        guard ((filterNameList.count>0) && (currIndex<filterNameList.count) && (currIndex>=0)) else {
            return ""
        }
        
        return filterNameList[currIndex]
    }
    
    
    private func createFilterContainerView(_ descriptor: FilterDescriptor) -> RenderContainerView{
        let view:RenderContainerView = RenderContainerView()
        view.frame.size = CGSize(width:carouselHeight, height:carouselHeight)
        view.label.text = descriptor.key
        
        //TODO: start rendering in an asynch queue
        
        return view
    }
    
    ///////////////////////////////////
    //MARK: - UIView required functions
    ///////////////////////////////////
    convenience init(){
        self.init(frame: CGRect.zero)
        
        initDone = false
        
        carouselHeight = fmax((self.frame.size.height * 0.8), 80.0) // doesn't seem to work at less than 80 (empirical)
        //carouselHeight = self.frame.size.height * 0.82
        
        
        // register for change notifications (don't do this before the views are set up)
        //filterManager?.setCategoryChangeNotification(callback: categoryChanged())
        
    }
    
    
    
    deinit {
        suspend()
    }
    
    
    
    func layoutViews(){
        
        if (!self.initDone){
            initDone = true
            //DispatchQueue.main.async(execute: { () -> Void in
            self.camera = CameraCaptureHelper(cameraPosition: .back)
            camera?.delegate = self
            
            // load the blend and sample images (assuming they cannot change while this view is displayed)
            self.blendImageFull  = UIImage(ciImage:ImageManager.getCurrentBlendImage()!)
            if (self.blendImageFull != nil){
                self.blend = CIImage(image:self.blendImageFull!)
            }
            
            self.sourceInput = getInputSource()
            
            if (self.sourceInput==nil){
                log.error("ERR: Sample input not created")
            }
            
            //})
        }
        
        
        filterLabel.text = ""
        filterLabel.textAlignment = .center
        //filterLabel.textColor = UIColor.white
        filterLabel.textColor = UIColor.lightGray
        filterLabel.font = UIFont.boldSystemFont(ofSize: 16.0)
        filterLabel.frame.size.height = carouselHeight * 0.18
        filterLabel.frame.size.width = self.frame.size.width
        self.addSubview(filterLabel)
        
        filterCarousel?.frame = self.frame
        self.addSubview(filterCarousel!)
        //filterCarousel?.fillSuperview()
        filterCarousel?.dataSource = self
        filterCarousel?.delegate = self
        
        //filterCarousel?.type = .rotary
        filterCarousel?.type = .linear
        
        //self.groupAndFill(.vertical, views: [filterLabel, filterCarousel], padding: 4.0)
        filterLabel.anchorAndFillEdge(.top, xPad: 0, yPad: 0, otherSize: filterLabel.frame.size.height)
        filterCarousel?.align(.underCentered, relativeTo: filterLabel, padding: 0, width: (filterCarousel?.frame.size.width)!, height: (filterCarousel?.frame.size.height)!)
        
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        layoutViews()
        
        //updateVisibleItems()
        
        // don't do anything until filter list has been assigned
    }
    
    
    ///////////////////////////////////
    //MARK: - iCarousel reequired functions
    ///////////////////////////////////
    
    // TODO: pre-load images for initial display
    
    // number of items in list
    func numberOfItems(in carousel: iCarousel) -> Int {
        log.verbose("\(filterNameList.count) items")
        return filterNameList.count
    }
    
    
    // returns view for item at specific index
    func carousel(_ carousel: iCarousel, viewForItemAt index: Int, reusing view: UIView?) -> UIView {
        
        if ((index < filterViewList.count) && (index>=0)){
            
            if (sourceInput != nil){
                filterCategory = (filterManager?.getCurrentCategory())!
                currFilter = filterManager?.getFilterDescriptor(key:filterNameList[index])
                
                if (currFilter != nil){
                    self.filterViewList[index].renderView?.image = currFilter!.apply(image:self.previewInput, image2:self.blend)
                    return filterViewList[index]
                }
            } else {
                log.error("ERR: No input available")
            }
        }
        return UIView()
    }
    
    // set custom options
    func carousel(_ carousel: iCarousel, valueFor option: iCarouselOption, withDefault value: CGFloat) -> CGFloat {
        
        // spacing between items
        if (option == iCarouselOption.spacing){
            //return value * 1.1
            return value
        } else if (option == iCarouselOption.wrap){
            return 1.0
        }
        
        // default
        return value
    }
    
    
    /* // don't use this as it will cause too many updates
     // called whenever an item passes to/through the center spot
     func carouselCurrentItemIndexDidChange(_ carousel: iCarousel) {
     let index = carousel.currentItemIndex
     log.debug("Selected: \(filterNameList[index])")
     }
     */
    
    // called when an item is selected manually (i.e. touched).
    func carousel(_ carousel: iCarousel, didSelectItemAt index: Int) {
        updateSelection(carousel, index: index)
    }
    
    // called when user stops scrolling through list
    func carouselDidEndScrollingAnimation(_ carousel: iCarousel) {
        let index = carousel.currentItemIndex
        
        updateSelection(carousel, index: index)
    }
    
    // utility function to check that an index is (still) valid.
    // Needed because the underlying filter list can can change asynchronously from the iCarousel background processing
    func isValidIndex(_ index:Int)->Bool{
        return ((index>=0) && (index < filterNameList.count) && (filterNameList.count>0))
        //return ((index>=0) && (index < filterViewList.count) && (filterViewList.count>0))
    }
    
    fileprivate func updateSelection(_ carousel: iCarousel, index: Int){
        
        // Note that the Filter Category can change in the middle of an update, so be careful with indexes
        
        /***
         guard (index != currIndex) else {
         //log.debug("Index did not change (\(currIndex)->\(index))")
         return
         }
         ***/
        
        guard (isValidIndex(index)) else {
            log.debug("Invalid index: \(index)")
            return
        }
        
        log.debug("Selected: \(filterNameList[index])")
        filterCategory = (filterManager?.getCurrentCategory())!
        currFilter = filterManager?.getFilterDescriptor(key:filterNameList[index])
        filterLabel.text = currFilter?.title
        
        // updates label colors of selected item, reset old selection
        if ((currIndex != index) && isValidIndex(index) && isValidIndex(currIndex)){
            let oldView = filterViewList[currIndex]
            oldView.label.textColor = UIColor.white
        }
        
        let newView = filterViewList[index]
        newView.label.textColor = UIColor.flatLime
        
        //filterManager?.setCurrentFilterKey(filterNameList[index])
        
        
        // call delegate function to act on selection
        if (index != currIndex) {
            delegate?.filterSelected(filterNameList[index])
        }
        
        
        // update current index
        currIndex = index
    }
    
    // suspend all Metal-related processing
    open func suspend(){
        camera?.stop()
        //filterNameList = []
        //currIndex = -1
    }
    
    
    private func updateVisibleItems(){
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            var index:Int
            var descriptor:FilterDescriptor?
            
            
            
            log.verbose("Updating...")
            for i in (self.filterCarousel?.indexesForVisibleItems)! {
                if (self.camera != nil){
                    index = i as! Int
                    if (self.isValidIndex(index)){ // filterNameList can change asynchronously
                        descriptor = (self.filterManager?.getFilterDescriptor(key:self.filterNameList[index]))
                        
                        if (descriptor != nil){
                            self.filterViewList[index].renderView?.image = descriptor?.apply(image:self.sourceInput)
                        }
                    }
                }
            }
            //self.filterCarousel?.setNeedsLayout()
        }
        
    }
    
    
    
    ///////////////////////////////////
    //MARK: - Callbacks
    ///////////////////////////////////
    
    
    func categoryChanged(){
        log.debug("category changed")
        setFilterCategory((filterManager?.getCurrentCategory())!)
    }
    
}


extension FilterSelectionView: CameraCaptureHelperDelegate {
    func newCameraImage(_ cameraCaptureHelper: CameraCaptureHelper, image: CIImage){
        //DispatchQueue.main.async(execute: { () -> Void in
        self.sourceInput = image
        self.update()
        //})
    }
}

