//
//  FilterGalleryViewController.swift
//  FilterCam
//
//  Created by Philip Price on 10/24/16.
//  Copyright © 2016 Nateemma. All rights reserved.
//

import UIKit
import GPUImage
import Neon
import AVFoundation
import MediaPlayer
import AudioToolbox

import GoogleMobileAds
import Kingfisher




// delegate method to let the launching ViewController know that this one has finished
protocol FilterGalleryViewControllerDelegate: class {
    func filterGalleryCompleted()
}


private var filterList: [String] = []
private var filterCount: Int = 0

// This is the View Controller for displaying and organising filters into categories

class FilterGalleryViewController: UIViewController {
    
    // delegate for handling events
    weak var delegate: FilterGalleryViewControllerDelegate?
    
    
    // Banner View (title)
    var bannerView: UIView! = UIView()
    var backButton:UIButton! = UIButton()
    var titleLabel:UILabel! = UILabel()
    
    
    // Advertisements View
    var adView: GADBannerView! = GADBannerView()
    
    // Category Selection View
    var categorySelectionView: CategorySelectionView!
    var currCategoryIndex = -1
    var currCategory:FilterManager.CategoryType = .quickSelect
    
    // Filter Galleries (one per category).
    var filterGalleryView : [FilterGalleryView] = []
    
    
    var filterManager:FilterManager = FilterManager.sharedInstance
    
    
    var isLandscape : Bool = false
    var showAds : Bool = true
    var screenSize : CGRect = CGRect.zero
    var displayWidth : CGFloat = 0.0
    var displayHeight : CGFloat = 0.0
    
    let bannerHeight : CGFloat = 64.0
    let buttonSize : CGFloat = 48.0
    let statusBarOffset : CGFloat = 12.0
    
    
    
    
    convenience init(){
        self.init(nibName:nil, bundle:nil)
        doInit()
    }
    
    
    
    
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // get display dimensions
        displayHeight = view.height
        displayWidth = view.width
        
        
        // get orientation
        //isLandscape = UIDevice.current.orientation.isLandscape // doesn't always work properly, especially in simulator
        isLandscape = (displayWidth > displayHeight)
        
        // initialisation workaroundm, set category to "none" during setup
        //filterManager.setCurrentCategory(.none)
        
        doInit()
        
        doLayout()
        
        // start Ads
        if (showAds){
            Admob.startAds(view:adView, viewController:self)
        }
        
        
        // set up initial Category
        currCategory = filterManager.getCurrentCategory()
        selectCategory(currCategory)
        categorySelectionView.setFilterCategory(currCategory)
        
        
    }
    
    
    
    static var initDone:Bool = false
    
    
    
    func doInit(){
        
        if (!FilterGalleryViewController.initDone){
            FilterGalleryViewController.initDone = true
            
            //ImageCache.default.clearMemoryCache() // for testing
            //ImageCache.default.clearDiskCache() // for testing
            
            // create an array of FilterGalleryViews and assign a category to each one
            filterGalleryView = []
            for _ in 0...FilterManager.maxIndex {
                filterGalleryView.append(FilterGalleryView())
            }
        }
    }
    
    
    
    func suspend(){
        for filterView in filterGalleryView{
            filterView.suspend()
        }
    }
    
    
    func doLayout(){
        
        displayHeight = view.height
        displayWidth = view.width
        log.verbose("h:\(displayHeight) w:\(displayWidth)")
        
        showAds = (isLandscape == true) ? false : true // don't show in landscape mode (too cluttered)
        //showAds = false // debug
        
        
        view.backgroundColor = UIColor.black // default seems to be white
        
        
        
        //top-to-bottom layout scheme
        
        bannerView.frame.size.height = bannerHeight * 0.75
        bannerView.frame.size.width = displayWidth
        bannerView.backgroundColor = UIColor.black
        
        
        layoutBanner()
        
        if (showAds){
            adView.frame.size.height = bannerHeight
            adView.frame.size.width = displayWidth
        }
        
        
        // setup Galleries
        for filterView in filterGalleryView{
            if (showAds){
                filterView.frame.size.height = displayHeight - 3.75 * bannerHeight
            } else {
                filterView.frame.size.height = displayHeight - 2.75 * bannerHeight
            }
            filterView.frame.size.width = displayWidth
            filterView.backgroundColor = UIColor.black
            filterView.isHidden = true
            filterView.delegate = self
            view.addSubview(filterView) // do this before categorySelectionView is assigned
        }
        
        
        // Note: need to add subviews before modifying constraints
        view.addSubview(bannerView)
        if (showAds){
            adView.isHidden = false
            view.addSubview(adView)
        } else {
            log.debug("Not showing Ads in landscape mode")
            adView.isHidden = true
        }
        
        
        categorySelectionView = CategorySelectionView()
        
        categorySelectionView.frame.size.height = 2.0 * bannerHeight
        categorySelectionView.frame.size.width = displayWidth
        categorySelectionView.backgroundColor = UIColor.black
        view.addSubview(categorySelectionView)
        
        // layout constraints
        bannerView.anchorAndFillEdge(.top, xPad: 0, yPad: statusBarOffset/2.0, otherSize: bannerView.frame.size.height)
        for filterView in filterGalleryView{
            filterView.anchorAndFillEdge(.bottom, xPad: 0, yPad: 0, otherSize: filterView.frame.size.height)
        }
        
        if (showAds){
            adView.align(.underCentered, relativeTo: bannerView, padding: 0, width: displayWidth, height: adView.frame.size.height)
            categorySelectionView.align(.underCentered, relativeTo: adView, padding: 0, width: displayWidth, height: categorySelectionView.frame.size.height)
        } else {
            categorySelectionView.align(.underCentered, relativeTo: bannerView, padding: 0, width: displayWidth, height: categorySelectionView.frame.size.height)
        }
        
        
        // add delegates to sub-views (for callbacks)
        //bannerView.delegate = self
        
        categorySelectionView.delegate = self
        for gallery in filterGalleryView{
            gallery.delegate = self
        }
        
    }
    
    func layoutBanner(){
        bannerView.addSubview(backButton)
        bannerView.addSubview(titleLabel)
        
        backButton.frame.size.height = bannerView.frame.size.height - 8
        backButton.frame.size.width = 2.0 * backButton.frame.size.height
        backButton.setTitle("< Back", for: .normal)
        backButton.backgroundColor = UIColor.flatMint()
        backButton.setTitleColor(UIColor.white, for: .normal)
        backButton.titleLabel!.font = UIFont.boldSystemFont(ofSize: 20.0)
        backButton.contentHorizontalAlignment = UIControlContentHorizontalAlignment.center
        
        titleLabel.frame.size.height = backButton.frame.size.height
        titleLabel.frame.size.width = displayWidth - backButton.frame.size.width
        titleLabel.text = "Filter Gallery"
        titleLabel.backgroundColor = UIColor.black
        titleLabel.textColor = UIColor.white
        titleLabel.font = UIFont.boldSystemFont(ofSize: 18.0)
        titleLabel.textAlignment = .center
        
        
        backButton.anchorInCorner(.bottomLeft, xPad: 4, yPad: 4, width: backButton.frame.size.width, height: backButton.frame.size.height)
        titleLabel.align(.toTheRightCentered, relativeTo: backButton, padding: 0, width: titleLabel.frame.size.width, height: titleLabel.frame.size.height)
        
        backButton.addTarget(self, action: #selector(self.backDidPress), for: .touchUpInside)
        
    }
    
    
    fileprivate func isValidIndex(_ index:Int)->Bool{
        return ((index>=0) && (index<filterGalleryView.count)) ? true : false
    }
    
    fileprivate func selectCategory(_ category:FilterManager.CategoryType){
        let index = category.getIndex()
        
        guard (isValidIndex(index)) else {
            log.warning("Invalid index:\(index) category:\(category.rawValue)")
            return
        }
        
        if (index != currCategoryIndex){
            log.debug("Category Selected: \(category) (\(currCategoryIndex)->\(index))")
            if (isValidIndex(currCategoryIndex)) { filterGalleryView[currCategoryIndex].isHidden = true }
            filterGalleryView[index].setCategory(FilterManager.getCategoryFromIndex(index))
            currCategory = category
            currCategoryIndex = index
            filterGalleryView[index].isHidden = false
        } else {
            if (isValidIndex(currCategoryIndex)) { filterGalleryView[currCategoryIndex].isHidden = false } // re-display just in case (e.g. could be a rotation)
            log.debug("Ignoring category change \(currCategoryIndex)->\(index)")
        }
    }
    
    
    fileprivate func updateCategoryDisplay(_ category:FilterManager.CategoryType){
        let index = category.getIndex()
        if (isValidIndex(index)){
            filterGalleryView[index].update()
        }
    }
    
    
    /*
     override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
     if UIDevice.current.orientation.isLandscape {
     log.verbose("Preparing for transition to Landscape")
     } else {
     log.verbose("Preparing for transition to Portrait")
     }
     }
     */
    
    override func didRotate(from fromInterfaceOrientation: UIInterfaceOrientation) {
        if UIDevice.current.orientation.isLandscape{
            log.verbose("### Detected change to: Landscape")
            isLandscape = true
        } else {
            log.verbose("### Detected change to: Portrait")
            isLandscape = false
            
        }
        //TODO: animate and maybe handle before rotation finishes
        self.removeSubviews()
        self.doLayout()
        
    }
    
    func removeSubviews(){
        for view in self.view.subviews {
            view.removeFromSuperview()
        }
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    
    
    
    /////////////////////////////
    // MARK: - Touch Handler(s)
    /////////////////////////////
    
    func backDidPress(){
        log.verbose("Back pressed")
        //_ = self.navigationController?.popViewController(animated: true)
        guard navigationController?.popViewController(animated: true) != nil else { //modal
            //log.debug("Not a navigation Controller")
            suspend()
            dismiss(animated: true, completion:  { self.delegate?.filterGalleryCompleted() })
            return
        }
    }
    
    
}


//////////////////////////////////////////
// MARK: - Delegate methods for sub-views
//////////////////////////////////////////

extension FilterGalleryViewController: CategorySelectionViewDelegate {
    func categorySelected(_ category:FilterManager.CategoryType){
        selectCategory(category)
    }
    
}





extension FilterGalleryViewController: FilterGalleryViewDelegate {
    func filterSelected(_ descriptor:FilterDescriptorInterface?){
        suspend()
        filterManager.setSelectedFilter(key: (descriptor?.key)!)
        let filterDetailsViewController = FilterDetailsViewController()
        filterDetailsViewController.delegate = self
        filterDetailsViewController.filterKey = (descriptor?.key)!
        self.present(filterDetailsViewController, animated: false, completion: nil)
    }
    
    func requestUpdate(category:FilterManager.CategoryType){
        log.debug("Update requested for category: \(category.rawValue)")
    }
}



extension FilterGalleryViewController: FilterDetailsViewControllerDelegate {
    func onCompletion(key:String){
        //DispatchQueue.main.asyncAfter(deadline: .now() + 0.005, execute: {() -> Void in
        //DispatchQueue.main.async(execute: {() -> Void in
        log.verbose("FilterDetailsView completed")
        self.updateCategoryDisplay(self.currCategory)
        //})
    }
}

