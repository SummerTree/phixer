//
//  FilterControlsView.swift
//  Philter
//
//  Created by Philip Price on 9/16/16.
//  Copyright © 2016 Nateemma. All rights reserved.
//

import UIKit
import Neon


// Class responsible for laying out the Filter Information View
// This is a container class for display the overlay that provides information about the current Filter view

// Interface required of controlling View
protocol FilterControlsViewDelegate: class {
    func categoryPressed()
    func filterPressed()
    func filterParametersPressed()
}




class FilterControlsView: UIView {
    
    
    var theme = ThemeManager.currentTheme()
    

    public enum ControlState{
        case hidden
        case shown
        case disabled
    }
    
    
    // display items
    var categoryButton: SquareButton! = SquareButton()
    var filterButton: SquareButton! = SquareButton()
    var parametersButton: SquareButton! = SquareButton()
    
    var categoryState:ControlState = .hidden
    var filterState:ControlState = .hidden
    var parametersState:ControlState = .hidden

    
    var initDone: Bool = false
   
    var filterManager = FilterManager.sharedInstance
    
    // delegate for handling events
    weak var delegate: FilterControlsViewDelegate?

    
    
    convenience init(){
        self.init(frame: CGRect.zero)
    }
    
    
    func initViews(){
        
        if (!initDone){
            // set the colors etc.

            self.backgroundColor = theme.backgroundColor
            
            //if (UISettings.buttonSide>self.frame.size.height){ UISettings.buttonSide = self.frame.size.height - 4 }
            let side = fmin(self.frame.size.height, self.frame.size.width) - 8
            
            categoryButton = SquareButton(bsize: side)
            categoryButton.setTintable(false)
            filterButton = SquareButton(bsize: side)
            filterButton.setTintable(false)
            parametersButton = SquareButton(bsize: side)
           
            // show the sub views
            self.addSubview(categoryButton)
            self.addSubview(filterButton)
            self.addSubview(parametersButton)
            
            update()
            
            
            // register for change notifications (don't do this before the views are set up)
            //filterManager.setFilterChangeNotification(callback: filterChanged())
            
            initDone = true
        }
    }

    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        // get orientation
        //UISettings.isLandscape = ((UIApplication.shared.statusBarOrientation == .landscapeLeft) || (UIApplication.shared.statusBarOrientation == .landscapeRight))

        if !initDone {
            initViews()
        }
        
        
        if (UISettings.isLandscape){
            // top-to-bottom layout
            //self.groupAndFill(.vertical, views: [categoryButton, filterButton, parametersButton], padding: 2)
            categoryButton.anchorToEdge(.top, padding: 2, width: UISettings.buttonSide, height: UISettings.buttonSide)
            parametersButton.anchorToEdge(.bottom, padding: 2, width: UISettings.buttonSide, height: UISettings.buttonSide)
            filterButton.anchorInCenter(width: UISettings.buttonSide, height: UISettings.buttonSide)
        } else {
            // left-to-right layout
            //self.groupAndFill(.horizontal, views: [categoryButton, filterButton, parametersButton], padding: 2)
            categoryButton.anchorToEdge(.left, padding: 2, width: UISettings.buttonSide, height: UISettings.buttonSide)
            parametersButton.anchorToEdge(.right, padding: 2, width: UISettings.buttonSide, height: UISettings.buttonSide)
            filterButton.anchorInCenter(width: UISettings.buttonSide, height: UISettings.buttonSide)
        }
        
        // TODO: update current values
        update()
        
        // register handler for the filter and parameters button
        categoryButton.addTarget(self, action: #selector(self.categoryDidPress), for: .touchUpInside)
        filterButton.addTarget(self, action: #selector(self.filterDidPress), for: .touchUpInside)
        parametersButton.addTarget(self, action: #selector(self.filterParametersDidPress), for: .touchUpInside)
      
    }
    
    
    
    func update(){
        
        //TOFIX: get rid of borders?
        
        // set icons based on control state for each button
        switch (categoryState){
        case .hidden:
            categoryButton.setImageAsset("ic_category_show")
            //categoryButton.setImageAsset("ic_category")
            categoryButton.layer.borderColor = UIColor.clear.cgColor
            categoryButton.alpha = 1.0
            break
        case .shown:
            categoryButton.setImageAsset("ic_category_hide")
            //categoryButton.setImageAsset("ic_category")
            categoryButton.layer.cornerRadius = 4.0
            categoryButton.layer.borderWidth = 1.0
            categoryButton.layer.borderColor = theme.titleTextColor.cgColor
            categoryButton.alpha = 1.0
            break
        case .disabled:
            categoryButton.setImageAsset("ic_category")
            categoryButton.layer.borderColor = UIColor.clear.cgColor
            categoryButton.alpha = 0.5
            break
        }
        
        switch (filterState){
        case .hidden:
            //filterButton.setImageAsset("ic_filters")
            filterButton.setImageAsset("ic_filters_show")
            filterButton.layer.borderColor = UIColor.clear.cgColor
            filterButton.alpha = 1.0
            break
        case .shown:
            //filterButton.setImageAsset("ic_filters")
            filterButton.setImageAsset("ic_filters_hide")
            filterButton.layer.cornerRadius = 4.0
            filterButton.layer.borderWidth = 1.0
            filterButton.layer.borderColor = theme.borderColor.cgColor
            filterButton.alpha = 1.0
            break
        case .disabled:
            filterButton.setImageAsset("ic_filters")
            filterButton.layer.borderColor = UIColor.clear.cgColor
            filterButton.alpha = 0.5
            break
        }
        
        switch (parametersState){
        case .hidden:
            //parametersButton.setImageAsset("ic_sliders")
            parametersButton.setImageAsset("ic_sliders_show")
            parametersButton.layer.borderColor = UIColor.clear.cgColor
            parametersButton.alpha = 1.0
            break
        case .shown:
            //parametersButton.setImageAsset("ic_sliders")
            parametersButton.setImageAsset("ic_sliders_hide")
            parametersButton.layer.cornerRadius = 4.0
            parametersButton.layer.borderWidth = 1.0
            parametersButton.layer.borderColor = theme.borderColor.cgColor
            parametersButton.alpha = 1.0
            break
        case .disabled:
            parametersButton.setImageAsset("ic_sliders")
            parametersButton.layer.borderColor = UIColor.clear.cgColor
            parametersButton.button.alpha = 0.5
            log.debug("Parameter button disabled")
            break
        }
        
    }
    
    
    // MARK: - Public Accessors
    
    open func setCategoryControlState(_ state:ControlState){
        if (categoryState != state){
            categoryState = state
                update()
            }
        }
        
        open func setFilterControlState(_ state:ControlState){
            if (filterState != state){
                filterState = state
                update()
            }
        }
        
        open func setParametersControlState(_ state:ControlState){
            if (parametersState != state){
                parametersState = state
                update()
            }
        }
    
    
    ///////////////////////////////////
    //MARK: - Callbacks
    ///////////////////////////////////
    
    func filterChanged(){
        log.debug("filter changed")
        update()
    }

    ///////////////////////////////////
    //MARK: - touch handlers
    ///////////////////////////////////
    
    @objc func categoryDidPress() {
        
        delegate?.categoryPressed()
    }
    
    @objc func filterDidPress() {
        delegate?.filterPressed()
    }
    
    @objc func filterParametersDidPress() {
        delegate?.filterParametersPressed()
    }
    
}
