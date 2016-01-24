//
//  CDPatternImagesTableViewController.swift
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
class PatternObjectWrapper : NSObject {
    dynamic var label: String
    dynamic var image: NSImage?
    init(label: String, image: NSImage?) {
        self.label = label
        self.image = image
    }
}

class HeaderPatternObjectWrapper : PatternObjectWrapper {
    
}

class ImagePatternObjectWrapper: PatternObjectWrapper {
    var url: NSURL!
    var children: [ImagePatternObjectWrapper]?
    var isDirectory: Bool = false

    weak var parent: ImagePatternObjectWrapper?
    
    init (label: String, url: NSURL, parent: ImagePatternObjectWrapper?) {
        super.init(label: label, image: nil)
        
        self.url = url
        self.parent = parent
        self.isDirectory = false
        do {
            var getter: AnyObject? = false
            try url.getResourceValue(&getter, forKey: NSURLIsDirectoryKey)
            self.isDirectory = getter as! Bool
        } catch {
          
        }
        // TODO: load the image!
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
    
}

class ProgrammedPatternObjectWrapper: PatternObjectWrapper {
    var patternType: LEDPatternType = LEDPatternTypeAllOff
    init(patternType: LEDPatternType) {
        let image: NSImage? = nil; // TODO: Load the template image (or start creating it..)
        super.init(label: CDPatternItemNames.nameForPatternType(patternType), image: image)
        self.patternType = patternType
    }

}

class CDPatternImagesOutlineViewController: NSViewController, NSOutlineViewDataSource, NSOutlineViewDelegate {

    @IBOutlet weak var _outlineView: NSOutlineView!
    
    private let _ignoredPatternTypes: [LEDPatternType] = [LEDPatternTypeMax, LEDPatternTypeImageReferencedBitmap, LEDPatternTypeImageEntireStrip_UNUSED, LEDPatternTypeBitmap]
    private var _rootChildren: [PatternObjectWrapper] = []
    
    private func _loadPatternTypeArray() -> [PatternObjectWrapper] {
        var result = [PatternObjectWrapper]()
        // Create a sorted array of pattern types to show
        for rawType in LEDPatternTypeMin.rawValue...LEDPatternTypeMax.rawValue  {
            let patternType = LEDPatternType(rawType)
            let patternTypeWrapper = ProgrammedPatternObjectWrapper(patternType: patternType)
            if !_ignoredPatternTypes.contains(patternType) {
                let index = result.insertionIndexOf(patternTypeWrapper) {
                    return $0.label.localizedStandardCompare($1.label) == NSComparisonResult.OrderedAscending
                }
                
                result.insert(patternTypeWrapper, atIndex: index)
            }
        }
        return result
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
                            }
                        }
                    }
                }
            } catch let error as NSError  {
                NSLog("Error loading children: %@", error)
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
        let programmedPatternGroupObject = HeaderPatternObjectWrapper(label: "Programmed Patterns", image: nil)
        _rootChildren = [programmedPatternGroupObject]
        _rootChildren.appendContentsOf(programmedPatterns)
        
        
        let rootPatternImages = _loadRootPatternImages()
        if let rootImages = rootPatternImages.children {
            // Only at the image dir if we have images..
            let imagePatternGroupObject = HeaderPatternObjectWrapper(label: "Image Patterns", image: nil)
            _rootChildren.append(imagePatternGroupObject)
            let a: [PatternObjectWrapper] = rootImages
//            _rootChildren.appendContentsOf(rootImages) // why doesn't this work??
            _rootChildren.appendContentsOf(a)
        }
        _outlineView.reloadData()
        _outlineView.expandItem(nil)
    }
    
    private func _getDocument() -> CDDocument {
        // This is a rather ugly way to get to the document..
        return self.parentWindowController!.document as! CDDocument
    }
    
    private func _addNewItemWithPatternType(patternType: LEDPatternType) -> CDPatternItem {
        let doc = _getDocument()
        let newItem = doc.addNewPatternItem()
        newItem.patternType = patternType
        return newItem
    }
    
    private func _addSelectedItemsToSequence(indexes: NSIndexSet) {
        
        for index in indexes {
            let item = _outlineView.itemAtRow(index)
            switch item {
            case let programmedItem as ProgrammedPatternObjectWrapper:
                _addNewItemWithPatternType(programmedItem.patternType)
            case let imageItem as ImagePatternObjectWrapper:
                if !imageItem.isDirectory {
                    let newItem = _addNewItemWithPatternType(LEDPatternTypeImageReferencedBitmap)
                    newItem.imageFilename = imageItem.relativeFilename
                    // Set the default speed...
                    newItem.patternSpeed = 0.50; // 50% speed by default (whatever that means..)
                    
                }
            default:
                assert(false, "Unhandled type")
            }
        }
    }
    
    
    ///MARK: OutlineView datasource/delegate methods

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
    
    @IBAction func _outlineDoubleClick(sender: NSOutlineView) {
        _addSelectedItemsToSequence(sender.selectedRowIndexes)
    }
    
}
