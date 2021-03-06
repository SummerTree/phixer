//
//  SampleGalleryViewController.swift
//  phixer
//
//  Created by Philip Price on 10/24/16.
//  Copyright © 2016 Nateemma. All rights reserved.
//

import UIKit
import CoreImage
import Neon
import AVFoundation
import MediaPlayer
import AudioToolbox

import GoogleMobileAds

import Photos



private var filterList: [String] = []
private var filterCount: Int = 0

// This is the View Controller for displaying the available Sample images and setting the one to be used elsewhere

class SampleGalleryViewController: CoordinatedController, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
    
    // Advertisements View
    var adView: GADBannerView! = GADBannerView()
    
    // View containing previews, buttons etc.Advertisements
    var infoView: UIView! = UIView()
    var acceptButton:UIButton! = UIButton()
    var cancelButton:UIButton! = UIButton()
    var helpLabel:UILabel! = UILabel()
    var currentLabel:UILabel! = UILabel()
    var selectedLabel:UILabel! = UILabel()
    var photosLabel:UILabel! = UILabel()
    var currentSampleImage:UIImageView! = UIImageView()
    var selectedSampleImage:UIImageView! = UIImageView()
    var photosLinkImage:UIImageView! = UIImageView()
    
    // views used to manage layout of subviews
    let buttonContainerView: UIView! = UIView()
    let imageContainerView: UIView! = UIView()
    
    //let currentView:ImageContainerView = ImageContainerView()
    //let selectedView:ImageContainerView = ImageContainerView()
    //let photosView:ImageContainerView = ImageContainerView()
    let currentView:UIView = UIView()
    let selectedView:UIView = UIView()
    let photosView:UIView = UIView()
    
    // the gallery of Sample options
    var sampleGalleryView : SampleGalleryView! = SampleGalleryView()
    
    let imagePicker = UIImagePickerController()
    
    var selectedSampleImageName: String = ""
    var currentSampleImageName: String = ""
    
    var imageSize:CGSize = CGSize.zero
    
    var displayWidth : CGFloat = 0.0
    var displayHeight : CGFloat = 0.0
    
    
    
    
    /////////////////////////////
    // MARK: - Override Base Class functions
    /////////////////////////////
    
    // return the display title for this Controller
    override public func getTitle() -> String {
        return "Sample Image Gallery"
    }
    
    // return the name of the help file associated with this Controller (without extension)
    override public func getHelpKey() -> String {
        return "SampleGallery"
    }
    
    /////////////////////////////
    // INIT
    /////////////////////////////
    

    
    convenience init(){
        self.init(nibName:nil, bundle:nil)
        doInit()
    }
    

    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // common setup
        self.prepController()

      // get display dimensions
        displayHeight = view.height
        displayWidth = view.width
        
        
        doInit()
        
        doLayout()
        
        // start Ads
        if (UISettings.showAds){
            Admob.startAds(view:adView, viewController:self)
        }
        
    }
    
    
    
    static var initDone:Bool = false
    
    func doInit(){
        
        if (!SampleGalleryViewController.initDone){
            SampleGalleryViewController.initDone = true
            
        }
    }
    
    
    
    func suspend(){
        
    }
    
    
    func doLayout(){
        
        currentSampleImageName = ImageManager.getCurrentSampleImageName()
        selectedSampleImageName = currentSampleImageName
        
        displayHeight = view.height
        displayWidth = view.width
        log.verbose("h:\(displayHeight) w:\(displayWidth)")
        
        //UISettings.showAds = (UISettings.isLandscape == true) ? false : true // don't show in landscape mode (too cluttered)
        UISettings.showAds = false // this screen looks bad with ads included...
        
        
        view.backgroundColor = theme.backgroundColor // default seems to be white
        
        
        
        //set up dimensions
        
        if (UISettings.showAds){
            adView.frame.size.height = UISettings.panelHeight
            adView.frame.size.width = displayWidth
            adView.layer.cornerRadius = 0.0
            adView.layer.borderWidth = 1.0
            adView.layer.borderColor = theme.borderColor.cgColor
        }
        
        infoView.frame.size.height = 3.5 * UISettings.panelHeight
        infoView.frame.size.width = displayWidth
        layoutInfoView()
        view.addSubview(infoView)
        
        if (UISettings.showAds){
            sampleGalleryView.frame.size.height = displayHeight - UISettings.topBarHeight - adView.frame.size.height - infoView.frame.size.height
        } else {
            sampleGalleryView.frame.size.height = displayHeight - UISettings.topBarHeight - infoView.frame.size.height
        }
        sampleGalleryView.frame.size.width = displayWidth
        //sampleGalleryView.backgroundColor = theme.backgroundColor
        
        
        
        sampleGalleryView.delegate = self
        view.addSubview(sampleGalleryView)
        
        
        // Note: need to add subviews before modifying constraints
        if (UISettings.showAds){
            adView.isHidden = false
            view.addSubview(adView)
        } else {
            log.debug("Not showing Ads in landscape mode")
            adView.isHidden = true
        }
        
        
        // layout constraints

        
        if (UISettings.showAds){
            adView.anchorAndFillEdge(.top, xPad: 0, yPad: UISettings.topBarHeight, otherSize: adView.frame.size.height)
            infoView.align(.underCentered, relativeTo: adView, padding: 0, width: displayWidth, height: infoView.frame.size.height)
        } else {
            infoView.anchorAndFillEdge(.top, xPad: 0, yPad: UISettings.topBarHeight, otherSize: infoView.frame.size.height)
        }
        
        sampleGalleryView.align(.underCentered, relativeTo: infoView, padding: 0, width: displayWidth, height: sampleGalleryView.frame.size.height)
        
        log.verbose("H: banner:\(UISettings.panelHeight) , ad:\(adView.frame.size.height), info:\(infoView.frame.size.height), gallery:\(sampleGalleryView.frame.size.height)")
        
        // add delegates to sub-views (for callbacks)
        //bannerView.delegate = self
        
        sampleGalleryView.delegate = self
        
    }
        
    
    
    // layout the info view, which contains previews of the current and proposed selections, link to photos and accept/cancel buttons
    func layoutInfoView(){
        
        // Accept/Cancel Buttons
        for button in [acceptButton, cancelButton] {
            button?.frame.size.height = UISettings.panelHeight - 8
            button?.frame.size.width = 3.0 * (button?.frame.size.height)!
            button?.backgroundColor = theme.buttonColor
            button?.setTitleColor(theme.titleTextColor, for: .normal)
            button?.titleLabel!.font = UIFont.systemFont(ofSize: 20.0, weight: UIFont.Weight.thin)
            button?.contentHorizontalAlignment = UIControl.ContentHorizontalAlignment.center
        }
        acceptButton.setTitle("Accept", for: .normal)
        cancelButton.setTitle("Cancel", for: .normal)
        
        buttonContainerView.addSubview(acceptButton)
        buttonContainerView.addSubview(cancelButton)
        
        buttonContainerView.frame.size.width = displayWidth
        buttonContainerView.frame.size.height = acceptButton.frame.size.height + 4
        
        
        // helpLabel, currentLabel, selectedLabel
        
        for label in [helpLabel, currentLabel, selectedLabel, photosLabel]{
            label?.frame.size.width = displayWidth / 3.0
            label?.frame.size.height = 32.0
            label?.backgroundColor = theme.backgroundColor
            label?.textColor = theme.textColor
            label?.font = UIFont.systemFont(ofSize: 14, weight: UIFont.Weight.thin)
            label?.textAlignment = .center
        }
        helpLabel.text = "Select an image from below or a photo"
        helpLabel.font = UIFont.systemFont(ofSize: 18, weight: UIFont.Weight.thin)
        
        currentLabel.text = "Current:"
        selectedLabel.text = "Selected:"
        photosLabel.text = "Photos:"
        
        // currentSampleImage
        // selectedSampleImage
        // photosLinkImage
        imageSize = CGSize(width:96, height:96)
        for image in [currentSampleImage, selectedSampleImage, photosLinkImage]{
            image?.frame.size = imageSize
            image?.backgroundColor = theme.backgroundColor
            image?.layer.cornerRadius = 0.0
            image?.layer.borderWidth = 1.0
            image?.layer.borderColor = theme.titleTextColor.cgColor
            image?.clipsToBounds = true
            image?.contentMode = .scaleAspectFill
        }
        currentSampleImage.image = UIImage(ciImage:ImageManager.getCurrentSampleImage(size: imageSize)!)
        selectedSampleImage.image = UIImage(ciImage:ImageManager.getSampleImage(name: selectedSampleImageName, size: imageSize)!)
        loadPhotoThumbnail(view:photosLinkImage)
        
        // bundle the images and their labels into container Views
        let viewSize = CGSize(width:(imageSize.width+2), height:(imageSize.height+currentLabel.frame.size.height + 2))
        
        currentView.frame.size = viewSize
        currentView.addSubview(currentSampleImage)
        currentView.addSubview(currentLabel)
        currentSampleImage.anchorAndFillEdge(.bottom, xPad: 0, yPad: 0, otherSize: imageSize.height)
        currentLabel.anchorAndFillEdge(.top, xPad: 0, yPad: 0, otherSize: currentLabel.frame.size.height)
        selectedSampleImage.anchorAndFillEdge(.bottom, xPad: 0, yPad: 0, otherSize: imageSize.height)
        //currentLabel.alignAndFill(.aboveCentered, relativeTo: currentSampleImage, padding: 0)
        
        selectedView.frame.size = viewSize
        selectedView.addSubview(selectedSampleImage)
        selectedView.addSubview(selectedLabel)
        selectedSampleImage.anchorAndFillEdge(.bottom, xPad: 0, yPad: 0, otherSize: imageSize.height)
        selectedLabel.anchorAndFillEdge(.top, xPad: 0, yPad: 0, otherSize: selectedLabel.frame.size.height)
        //selectedLabel.alignAndFill(.aboveCentered, relativeTo: selectedSampleImage, padding: 0)
        
        photosView.frame.size = viewSize
        photosView.addSubview(photosLinkImage)
        photosView.addSubview(photosLabel)
        photosLinkImage.anchorAndFillEdge(.bottom, xPad: 0, yPad: 0, otherSize: imageSize.height)
        photosLabel.anchorAndFillEdge(.top, xPad: 0, yPad: 0, otherSize: photosLabel.frame.size.height)
        //photosLabel.alignAndFill(.aboveCentered, relativeTo: photosLinkImage, padding: 0)
        
        imageContainerView.frame.size.height = currentView.frame.size.height
        imageContainerView.frame.size.width = infoView.frame.size.width
        
        // add the subviews to infoView
        infoView.addSubview(helpLabel)
        
        imageContainerView.addSubview(currentView)
        imageContainerView.addSubview(selectedView)
        imageContainerView.addSubview(photosView)
        infoView.addSubview(imageContainerView)
        
        infoView.addSubview(buttonContainerView)
        
        
        // layout the constraints
        
        infoView.addSubview(buttonContainerView)
        
        
        helpLabel.anchorAndFillEdge(.top, xPad: 2.0, yPad: 2.0, otherSize: helpLabel.frame.size.height)
        
        imageContainerView.groupInCenter(group: .horizontal, views: [currentView, selectedView, photosView], padding: 8, width: currentView.frame.size.width, height: currentView.frame.size.height)
        imageContainerView.align(.underCentered, relativeTo: helpLabel, padding: 1, width: imageContainerView.frame.size.width, height: currentView.frame.size.height)
        
        buttonContainerView.groupInCenter(group: .horizontal, views: [acceptButton, cancelButton], padding: 8, width: acceptButton.frame.size.width, height: acceptButton.frame.size.height)
        buttonContainerView.anchorAndFillEdge(.bottom, xPad: 2.0, yPad: 2.0, otherSize: buttonContainerView.frame.size.height)
        
        
        // add touch handlers
        acceptButton.addTarget(self, action: #selector(self.acceptDidPress), for: .touchUpInside)
        cancelButton.addTarget(self, action: #selector(self.cancelDidPress), for: .touchUpInside)
        let photosTap = UITapGestureRecognizer(target: self, action: #selector(photosLinkDidPress))
        photosLinkImage.addGestureRecognizer(photosTap)
        photosLinkImage.isUserInteractionEnabled = true
        
    }
        
    
    func exitScreen(){
        suspend()
        self.dismiss()
        return
    }
    
    func loadPhotoThumbnail(view: UIImageView){
        
        let fetchOptions = PHFetchOptions()
        fetchOptions.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: true)]
        
        let fetchResult = PHAsset.fetchAssets(with: .image, options: fetchOptions)
        
        let last = fetchResult.lastObject
        
        if let lastAsset = last {
            let options = PHImageRequestOptions()
            options.version = .current
            
            PHImageManager.default().requestImage(
                for: lastAsset,
                targetSize: view.bounds.size,
                contentMode: .aspectFit,
                options: options,
                resultHandler: { image, _ in
                    DispatchQueue.main.async {
                        view.image = image!
                    }
            }
            )
        }
    }
    
    
    func updateSelectedImage(){
        DispatchQueue.main.async(execute: { () -> Void in
            self.selectedSampleImage.image = UIImage(ciImage:ImageManager.getSampleImage(name: self.selectedSampleImageName, size: self.imageSize)!)
        })
    }
    
    /////////////////////////////
    // MARK: - Touch Handler(s)
    /////////////////////////////
    
    @objc func backDidPress(){
        log.verbose("Back pressed")
        exitScreen()
    }
    
    
    @objc func acceptDidPress(){
        log.verbose("Accept pressed. Sample: \(selectedSampleImageName)")
        ImageManager.setCurrentSampleImageName(selectedSampleImageName)
        exitScreen()
    }
    
    @objc func cancelDidPress(){
        log.verbose("Cancel pressed")
        exitScreen()
    }
    
    @objc func photosLinkDidPress(){
        log.verbose("Photos pressed")
        DispatchQueue.main.async(execute: { () -> Void in
            // launch an ImagePicker
            self.imagePicker.allowsEditing = false
            self.imagePicker.sourceType = .photoLibrary
            self.imagePicker.modalPresentationStyle = .popover // required after ios12
            self.imagePicker.delegate = self
            self.present(self.imagePicker, animated: true, completion: nil)
        })
    }
    
    
    
    //////////////////////////////////////////
    // MARK: - ImagePicker handling
    //////////////////////////////////////////
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        if let asset = info[UIImagePickerController.InfoKey.phAsset] as? PHAsset {
            let assetResources = PHAssetResource.assetResources(for: asset)
            
            let name = assetResources.first!.originalFilename
            let id = assetResources.first!.assetLocalIdentifier
            
            log.verbose("Picked image:\(name) id:\(id)")
            self.selectedSampleImageName = id
            self.updateSelectedImage()
        } else {
            log.error("Error accessing image data")
        }
        picker.dismiss(animated: true)
        
    }

    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        log.verbose("Image Picker cancelled")
        picker.dismiss(animated: true)
    }
    
 }


//////////////////////////////////////////
// MARK: - Delegate methods for sub-views
//////////////////////////////////////////





extension SampleGalleryViewController: SampleGalleryViewDelegate {
    internal func imageSelected(name: String) {
        DispatchQueue.main.async(execute: { () -> Void in
            log.debug("Sample image selected: \(name)")
            self.selectedSampleImageName = name
            self.updateSelectedImage()
        })
    }
}



