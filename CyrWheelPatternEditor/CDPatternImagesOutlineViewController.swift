//
//  CDPatternImagesOutlineViewController.swift
//  CyrWheelPatternEditor
//
//  Created by corbin dunn on 23/01/16.
//  Copyright © 2016 Corbin Dunn. All rights reserved.
//

import Cocoa

extension Array {
    func insertionIndexOf(elem: Element, isOrderedBefore: (Element, Element) -> Bool) -> Int {
        var lo = 0
        var hi = self.count - 1
        while lo <= hi {
            let mid = (lo + hi)/2
            if isOrderedBefore(self[mid], elem) {
                lo = mid + 1
            } else if isOrderedBefore(elem, self[mid]) {
                hi = mid - 1
            } else {
                return mid // found at position mid
            }
        }
        return lo // not found, would be inserted at position lo
    }
}



// For binding the cell object value to and a simple model representing patterns that I can create
//class PatternObjectWrapper : NSObject {
//    sdf
//    
//    var patternType: LEDPatternType = LEDPatternTypeCount
//    dynamic var label: String
//    dynamic var image: NSImage?
//    
//    // used in bindings in CDWheelPlayerDetailViewController
//    dynamic var color: NSColor = NSColor.redColor()
//    dynamic var speed: Double = 0.6
//
//    init(label: String, image: NSImage?) {
//        self.label = label
//        self.image = image
//    }
//}

class HeaderPatternObjectWrapper : CDPatternItemHeaderWrapper {
    init(label: String) {
        super.init(patternType: LEDPatternTypeCount, label: label)
    }
}

class ImagePatternObjectWrapper: CDPatternItemHeaderWrapper {
    var url: NSURL!
    var children: [ImagePatternObjectWrapper]?
    dynamic var isDirectory: Bool = false

    weak var parent: ImagePatternObjectWrapper?
    
    init (label: String, url: NSURL, parent: ImagePatternObjectWrapper?) {
        super.init(patternType: LEDPatternTypeImageReferencedBitmap, label: label)
        self.url = url
        self.parent = parent
        self.isDirectory = false

        do {
            var getter: AnyObject? = false
            try url.getResourceValue(&getter, forKey: NSURLIsDirectoryKey)
            self.isDirectory = getter as! Bool
        } catch {
          
        }
    }
    
    var relativeFilename: String {
        get {
            var result: String!
            var pWalker: ImagePatternObjectWrapper? = self
            while let p = pWalker {
                if result == nil {
                    result = p.label
                } else if p.label != "" {
                    result = p.label + "/" + result
                }
                pWalker = p.parent
            }
            return result
        }
    }
    
    var _cachedImage: NSImage? = nil
    dynamic override var image: NSImage? {
        get {
            if _cachedImage == nil {
                _cachedImage = NSImage(byReferencingURL: self.url);
            }
            return _cachedImage;
        }
    }

}

class CustomSequencePatternObjectWrapper: CDPatternItemHeaderWrapper {
    init (relativeFilename: String) {
        // Pattern type is ignored..
        self.relativeFilename = relativeFilename
        super.init(patternType: LEDPatternTypeCount, label: relativeFilename)
        self.canDelete = true;
    }
    var relativeFilename: String
    
}

class ProgrammedPatternObjectWrapper: CDPatternItemHeaderWrapper {
    
    // always returns a new copy so i can set the delegate
    static func allSortedProgrammedPatternsIgnoring(ignoredPatternTypes: [LEDPatternType]) -> [ProgrammedPatternObjectWrapper] {
        var _allSortedProgrammedPatterns = [ProgrammedPatternObjectWrapper]()
        for rawType in LEDPatternTypeMin.rawValue...LEDPatternTypeCount.rawValue  {
            let patternType = LEDPatternType(rawType)
            if !ignoredPatternTypes.contains(patternType) {
                let patternTypeWrapper = ProgrammedPatternObjectWrapper(patternType: patternType)
                let index = _allSortedProgrammedPatterns.insertionIndexOf(patternTypeWrapper) {
                    return $0.label.localizedStandardCompare($1.label) == NSComparisonResult.OrderedAscending
                }
                
                _allSortedProgrammedPatterns.insert(patternTypeWrapper, atIndex: index)
            }
        }
        return _allSortedProgrammedPatterns
    }
    

}

// TODO: put this somewhere else to share the code better
extension LEDPatternType {
    
    static var nonSelectablePatternTypes: [LEDPatternType] {
        return [LEDPatternTypeCount, LEDPatternTypeImageReferencedBitmap, LEDPatternTypeImageEntireStrip_UNUSED, LEDPatternTypeBitmap]
    }

    static var hiddenPatternTypes: [LEDPatternType] {
        return [LEDPatternTypeCount, LEDPatternTypeImageEntireStrip_UNUSED, LEDPatternTypeBitmap]
    }

}

class CDPatternImagesOutlineViewController: NSViewController, NSOutlineViewDataSource, NSOutlineViewDelegate {

    @IBOutlet weak var _outlineView: NSOutlineView!
    @IBOutlet weak var imgvwPreview: NSImageView!
    
    private let _ignoredPatternTypes: [LEDPatternType] = [LEDPatternTypeCount, LEDPatternTypeImageReferencedBitmap, LEDPatternTypeImageEntireStrip_UNUSED, LEDPatternTypeBitmap]
    internal var _rootChildren: [CDPatternItemHeaderWrapper] = []
    
    private func _loadPatternTypeArray() -> [CDPatternItemHeaderWrapper] {
        return ProgrammedPatternObjectWrapper.allSortedProgrammedPatternsIgnoring(LEDPatternType.nonSelectablePatternTypes)
    }
    
    private func _loadChildrenItems(parentItem: ImagePatternObjectWrapper) {
        if parentItem.children == nil {
            var children: [ImagePatternObjectWrapper] = []
            
            // I store a relative filename name in the label
            let keys = [NSURLIsDirectoryKey, NSURLLocalizedNameKey]

            let fileManager = NSFileManager.defaultManager()
            do {
                let patternImageURLs = try fileManager.contentsOfDirectoryAtURL(parentItem.url, includingPropertiesForKeys: keys, options: [NSDirectoryEnumerationOptions.SkipsHiddenFiles])
                for url in patternImageURLs {
                    let label = url.lastPathComponent!
                    let child = ImagePatternObjectWrapper(label: label, url: url, parent: parentItem)
                    if child.isDirectory {
                        children.append(child)
                    } else {
                        // Only bitmap images
                        if let ext = url.pathExtension {
                            if ext.lowercaseString == "bmp" {
                                children.append(child)
                                // set it as POV if it is in the Images or Pictures folders
                                let parentStr = parentItem.label.lowercaseString
                                if parentStr.containsString("pictures") || parentStr.containsString("images") || parentStr.containsString("pixels") || parentStr.containsString("figures") {
                                    child.pov = true
                                }
                                
                            }
                        }
                    }
                }
            } catch let error as NSError  {
                //NSLog("Error loading children: %@", error)
                NSApp.presentError(error)
            }
            parentItem.children = children
        }
    }
    
    private func _loadRootPatternImages() -> ImagePatternObjectWrapper {
        let patternURL = CDAppDelegate.appDelegate.patternDirectoryURL
        let result = ImagePatternObjectWrapper(label: "", url: patternURL, parent: nil)
        _loadChildrenItems(result)
        return result
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        let programmedPatterns = _loadPatternTypeArray()
        let programmedPatternGroupObject = HeaderPatternObjectWrapper(label: "Programmed Patterns")
        _rootChildren = [programmedPatternGroupObject]
        _rootChildren.appendContentsOf(programmedPatterns)
        
        let rootPatternImages = _loadRootPatternImages()
        if let rootImages = rootPatternImages.children {
            // Only at the image dir if we have images..
            let imagePatternGroupObject = HeaderPatternObjectWrapper(label: "Image Patterns")
            _rootChildren.append(imagePatternGroupObject)
            let a: [CDPatternItemHeaderWrapper] = rootImages
//            _rootChildren.appendContentsOf(rootImages) // why doesn't this work??
            _rootChildren.appendContentsOf(a)
        }
//        _outlineView.appearance = NSAppearance(named: NSAppearanceNameVibrantDark)
        _outlineView.reloadData()
        _outlineView.expandItem(nil)
        self.imgvwPreview.appearance = NSAppearance(named: NSAppearanceNameVibrantDark)
    }
    
    
    ///MARK: OutlineView datasource/delegate methods

    
    func outlineViewSelectionDidChange(notification: NSNotification) {
        _updatePreview();
    }
    
    private func _updatePreview() {
        if let item = _outlineView.selectedItem as? ImagePatternObjectWrapper {
            self.imgvwPreview.image = item.image
        } else {
            self.imgvwPreview.image = nil
        }
    }
    
    func outlineView(outlineView: NSOutlineView, numberOfChildrenOfItem item: AnyObject?) -> Int {
        if item == nil {
            // the root
            return _rootChildren.count
        } else {
            if let imageItem: ImagePatternObjectWrapper = item as? ImagePatternObjectWrapper {
                if imageItem.isDirectory {
                    // Make sure we loaded the children
                    _loadChildrenItems(imageItem)
                    return imageItem.children!.count
                }
            }
        }
        return 0
    }
    
    func outlineView(outlineView: NSOutlineView, child index: Int, ofItem item: AnyObject?) -> AnyObject {
        if item == nil {
            // the root
            return _rootChildren[index]
        } else {
            // must be a image wrapper
            let imageItem = item as! ImagePatternObjectWrapper
            _loadChildrenItems(imageItem)
            return imageItem.children![index]
        }
    }
    
    func outlineView(outlineView: NSOutlineView, isItemExpandable item: AnyObject) -> Bool {
        if let imageItem = item as? ImagePatternObjectWrapper {
            return imageItem.isDirectory
        } else {
            return false
        }
    }
    
    
    func outlineView(outlineView: NSOutlineView, isGroupItem item: AnyObject) -> Bool {
        // The root item's
        return item is HeaderPatternObjectWrapper
    }
    
    func outlineView(outlineView: NSOutlineView, shouldSelectItem item: AnyObject) -> Bool {
        if item is HeaderPatternObjectWrapper {
            return false
        }
        return true
    }
    
    func outlineView(outlineView: NSOutlineView, objectValueForTableColumn tableColumn: NSTableColumn?, byItem item: AnyObject?) -> AnyObject? {
        return item
    }
    
    
    func outlineView(outlineView: NSOutlineView, viewForTableColumn tableColumn: NSTableColumn?, item: AnyObject) -> NSView? {
        if item is HeaderPatternObjectWrapper {
            // Header item
            return outlineView.makeViewWithIdentifier("HeaderCell", owner: nil)
        } else if let tableColumn = tableColumn {
            // regular item
            return outlineView.makeViewWithIdentifier(tableColumn.identifier, owner: nil)
        } else {
            return nil
        }
    }
    
    func outlineView(outlineView: NSOutlineView, rowViewForItem item: AnyObject) -> NSTableRowView? {
        if item is HeaderPatternObjectWrapper {
            return outlineView.makeViewWithIdentifier("FloatingRowView", owner: nil) as? NSTableRowView
        } else {
            return outlineView.makeViewWithIdentifier("DarkRowView", owner: nil) as? NSTableRowView
        }
    }
    
    func outlineView(outlineView: NSOutlineView, heightOfRowByItem item: AnyObject) -> CGFloat {
        if item is HeaderPatternObjectWrapper {
            return outlineView.rowHeight + 4 // A little bigger/taller to look better w/the bold font
        } else {
            return outlineView.rowHeight
        }
    }

    // Cmd-R to reveal the image in finder.
    @IBAction func revealInFinder(sender: AnyObject) {
        if let item = _outlineView.selectedItem as? ImagePatternObjectWrapper {
            NSWorkspace.sharedWorkspace().selectFile(item.url.path, inFileViewerRootedAtPath: "")
        }
    }
    


    
}
