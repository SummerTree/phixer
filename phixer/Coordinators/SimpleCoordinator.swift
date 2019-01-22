//
//  SimpleCoordinator.swift
//  phixer
//
//  Created by Philip Price on 1/14/19.
//  Copyright © 2019 Nateemma. All rights reserved.
//

import Foundation
import UIKit
import Firebase
import GoogleMobileAds

// class that implements the simple case of a single Controller. The ID can be passed to the constructor

class SimpleCoordinator: Coordinator {
   
    
    // set the ID of the main controller
    func setMainController(_ controller: ControllerIdentifier) {
        self.mainControllerId = controller
    }
    
    /////////////////////////////
    // MARK:  Delegate Functions
    /////////////////////////////
    
    
    // move to the next item, whatever that is (can be nothing)
    override func nextItemRequest() {
        
        // get next filter and send it to the main controller
        let key = Coordinator.filterManager?.getNextFilterKey()
        self.mainController?.selectFilter(key: key!)
    }
    
    
    
    // move to the previous item, whatever that is (can be nothing)
    override func previousItemRequest() {
        
        // get prev filter and send it to the main controller
        let key = Coordinator.filterManager?.getPreviousFilterKey()
        self.mainController?.selectFilter(key: key!)
    }

    
    override func selectFilterNotification (key: String) {
        // filter selected, pass it on to the parent controller
        log.debug("Passing up to parent - key: \(key)")
        self.coordinator?.selectFilterNotification(key: key)
        
        // exit this coordinator
        // TODO: tell mainController first???
        self.completionNotification(id: self.mainControllerId, activate: .none)
    }

    override func themeUpdatedNotification() {
        // pass up to the parent
        log.verbose("Passing up to parent")
        self.coordinator?.themeUpdatedNotification()
    }
    
    override func startRequest(completion: @escaping ()->()){
        // Logging nicety, show that controller has changed:
        print ("\n========== \(String(describing: type(of: self))): \(self.mainControllerId.rawValue) ==========\n")
        
        // reset controller/coordinator vars
        self.completionHandler = completion
        self.subCoordinators = [:]
        self.mainController = nil
        self.subControllers = [:]
        self.validControllers = [self.mainControllerId, .help]
        
         self.activateRequest(id: self.mainControllerId)
        
        self.coordinatorMap [ControllerIdentifier.help] = CoordinatorIdentifier.help

    }


}
