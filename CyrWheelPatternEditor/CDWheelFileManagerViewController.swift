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
    
    @IBAction func btnDownloadClicked(_ sender: NSButton) {
        
        
    }
    
    
}

extension CDWheelFileManagerViewController : NSOutlineViewDelegate, NSOutlineViewDataSource {
    
 
    func outlineView(_ outlineView: NSOutlineView, numberOfChildrenOfItem item: Any?) -> Int {
//        if let connectedWheel = self.connectedWheel {
////            return connectedWheel.customSequences
//        }
        return 0;
    }
    
    func outlineView(_ outlineView: NSOutlineView, child index: Int, ofItem item: Any?) -> Any {
        return ""
    }
    
    func outlineView(_ outlineView: NSOutlineView, isItemExpandable item: Any) -> Bool {
        return false
    }

}
