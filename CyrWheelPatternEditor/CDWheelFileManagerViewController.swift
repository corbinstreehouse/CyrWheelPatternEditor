//
//  CDWheelFileManagerViewController.swift
//  CyrWheelPatternEditor
//
//  Created by Corbin Dunn on 2/16/16 .
//  Copyright © 2016 Corbin Dunn. All rights reserved.
//

import Foundation

class CDWheelFileManagerViewController : NSViewController, CDWheelConnectionPresenter {
    
    @IBOutlet weak var _fileOutlineView: NSOutlineView!
    
    dynamic var connectedWheel: CDWheelConnection? {
        didSet {
            _fileOutlineView?.reloadData()
        }
    }
    
    @IBAction func btnDownloadClicked(sender: NSButton) {
        
        
    }
    
    
}

extension CDWheelFileManagerViewController : NSOutlineViewDelegate, NSOutlineViewDataSource {
    
 
    func outlineView(outlineView: NSOutlineView, numberOfChildrenOfItem item: AnyObject?) -> Int {
//        if let connectedWheel = self.connectedWheel {
////            return connectedWheel.customSequences
//        }
        return 0;
    }
    
    func outlineView(outlineView: NSOutlineView, child index: Int, ofItem item: AnyObject?) -> AnyObject {
        return ""
    }
    
    func outlineView(outlineView: NSOutlineView, isItemExpandable item: AnyObject) -> Bool {
        return false
    }

}