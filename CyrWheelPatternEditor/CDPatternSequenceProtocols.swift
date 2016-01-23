//
//  CDPatternSequenceProtocols.swift
//  CyrWheelPatternEditor
//
//  Created by Corbin Dunn on 1/19/16 .
//  Copyright © 2016 Corbin Dunn. All rights reserved.
//

import Foundation

//protocol CDPatternSimulatorDocumentPresenter {
//    var simulatorDocument: CDPatternSimulatorDocument! { get set }
//}

protocol CDPatternSequencePresenter {
    var patternSequence: CDPatternSequence! { get set }
}

protocol CDPatternSequenceProvider {
    var patternSequence: CDPatternSequence! { get }
    var patternSelectionIndexes: NSIndexSet { get set } // For bindings and manipulation; there should only be one in the hierarchy..
    var managedObjectContext: NSManagedObjectContext { get }
}


extension NSViewController {
    
    var parentWindowController: NSWindowController? {
        get {
            return self.view.window?.windowController
        }
    }
    
    
    var patternSequenceProvider: CDPatternSequenceProvider? {
        get {
            if let wc = self.parentWindowController {
                return wc as? CDPatternSequenceProvider
            } else {
                return nil
            }
        }
    }
    
}