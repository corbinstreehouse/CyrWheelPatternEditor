//
//  CDPatternImagesOutlineViewController.swift
//  CyrWheelPatternEditor
//
//  Created by corbin dunn on 23/01/16.
//  Copyright © 2016 Corbin Dunn. All rights reserved.
//

import Cocoa

extension Array {
    func insertionIndexOf(_ elem: Element, isOrderedBefore: (Element, Element) -> Bool) -> Int {
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
    var url: URL!
    var children: [ImagePatternObjectWrapper]?
    dynamic var isDirectory: Bool = false

    weak var parent: ImagePatternObjectWrapper?
    
    init (label: String, url: URL, parent: ImagePatternObjectWrapper?) {
        super.init(patternType: LEDPatternTypeImageReferencedBitmap, label: label)
        self.url = url
        self.parent = parent
        self.isDirectory = false

        do {
            var getter: AnyObject? = false as AnyObject
            try (url as NSURL).getResourceValue(&getter, forKey: URLResourceKey.isDirectoryKey)
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
                _cachedImage = NSImage(byReferencing: self.url);
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
    static func allSortedProgrammedPatternsIgnoring(_ ignoredPatternTypes: [LEDPatternType]) -> [ProgrammedPatternObjectWrapper] {
        var _allSortedProgrammedPatterns = [ProgrammedPatternObjectWrapper]()
        for rawType in LEDPatternTypeMin.rawValue...LEDPatternTypeCount.rawValue  {
            let patternType = LEDPatternType(rawType)
            if !ignoredPatternTypes.contains(patternType) {
                let patternTypeWrapper = ProgrammedPatternObjectWrapper(patternType: patternType)
                let index = _allSortedProgrammedPatterns.insertionIndexOf(patternTypeWrapper) {
                    return $0.label.localizedStandardCompare($1.label) == ComparisonResult.orderedAscending
                }
                
                _allSortedProgrammedPatterns.insert(patternTypeWrapper, at: index)
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
    
    fileprivate let _ignoredPatternTypes: [LEDPatternType] = [LEDPatternTypeCount, LEDPatternTypeImageReferencedBitmap, LEDPatternTypeImageEntireStrip_UNUSED, LEDPatternTypeBitmap]
    internal var _rootChildren: [CDPatternItemHeaderWrapper] = []
    
    fileprivate func _loadPatternTypeArray() -> [CDPatternItemHeaderWrapper] {
        return ProgrammedPatternObjectWrapper.allSortedProgrammedPatternsIgnoring(LEDPatternType.nonSelectablePatternTypes)
    }
    
    fileprivate func _loadChildrenItems(_ parentItem: ImagePatternObjectWrapper) {
        if parentItem.children == nil {
            var children: [ImagePatternObjectWrapper] = []
            
            // I store a relative filename name in the label
            let keys = [URLResourceKey.isDirectoryKey, URLResourceKey.localizedNameKey]

            let fileManager = FileManager.default
            do {
                let patternImageURLs = try fileManager.contentsOfDirectory(at: parentItem.url, includingPropertiesForKeys: keys, options: [FileManager.DirectoryEnumerationOptions.skipsHiddenFiles])
                for url in patternImageURLs {
                    let label = url.lastPathComponent
                    let child = ImagePatternObjectWrapper(label: label, url: url, parent: parentItem)
                    if child.isDirectory {
                        children.append(child)
                    } else {
                        // Only bitmap images
                        if url.pathExtension.lowercased() == "bmp" {
                            children.append(child)
                            // set it as POV if it is in the Images or Pictures folders
                            let parentStr = parentItem.label.lowercased()
                            if parentStr.contains("pictures") || parentStr.contains("images") || parentStr.contains("pixels") || parentStr.contains("figures") {
                                child.pov = true
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
    
    fileprivate func _loadRootPatternImages() -> ImagePatternObjectWrapper {
        let patternURL = CDAppDelegate.appDelegate.patternDirectoryURL
        let result = ImagePatternObjectWrapper(label: "", url: patternURL as URL, parent: nil)
        _loadChildrenItems(result)
        return result
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        let programmedPatterns = _loadPatternTypeArray()
        let programmedPatternGroupObject = HeaderPatternObjectWrapper(label: "Programmed Patterns")
        _rootChildren = [programmedPatternGroupObject]
        _rootChildren.append(contentsOf: programmedPatterns)
        
        let rootPatternImages = _loadRootPatternImages()
        if let rootImages = rootPatternImages.children {
            // Only at the image dir if we have images..
            let imagePatternGroupObject = HeaderPatternObjectWrapper(label: "Image Patterns")
            _rootChildren.append(imagePatternGroupObject)
            let a: [CDPatternItemHeaderWrapper] = rootImages
//            _rootChildren.appendContentsOf(rootImages) // why doesn't this work??
            _rootChildren.append(contentsOf: a)
        }
//        _outlineView.appearance = NSAppearance(named: NSAppearanceNameVibrantDark)
        _outlineView.reloadData()
        _outlineView.expandItem(nil)
        self.imgvwPreview.appearance = NSAppearance(named: NSAppearanceNameVibrantDark)
        // allow adding files (no way to remove them yet...)
        _outlineView.register(forDraggedTypes: [kUTTypeURL as String])
    }
    
    
    ///MARK: OutlineView datasource/delegate methods

    
    func outlineViewSelectionDidChange(_ notification: Notification) {
        _updatePreview();
    }
    
    fileprivate func _updatePreview() {
        if let item = _outlineView.selectedItem as? ImagePatternObjectWrapper {
            self.imgvwPreview.image = item.image
        } else {
            self.imgvwPreview.image = nil
        }
    }
    
    func outlineView(_ outlineView: NSOutlineView, numberOfChildrenOfItem item: Any?) -> Int {
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
    
    func outlineView(_ outlineView: NSOutlineView, child index: Int, ofItem item: Any?) -> Any {
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
    
    func outlineView(_ outlineView: NSOutlineView, isItemExpandable item: Any) -> Bool {
        if let imageItem = item as? ImagePatternObjectWrapper {
            return imageItem.isDirectory
        } else {
            return false
        }
    }
    
    
    func outlineView(_ outlineView: NSOutlineView, isGroupItem item: Any) -> Bool {
        // The root item's
        return item is HeaderPatternObjectWrapper
    }
    
    func outlineView(_ outlineView: NSOutlineView, shouldSelectItem item: Any) -> Bool {
        if item is HeaderPatternObjectWrapper {
            return false
        }
        return true
    }
    
    func outlineView(_ outlineView: NSOutlineView, objectValueFor tableColumn: NSTableColumn?, byItem item: Any?) -> Any? {
        return item
    }
    
    
    func outlineView(_ outlineView: NSOutlineView, viewFor tableColumn: NSTableColumn?, item: Any) -> NSView? {
        if item is HeaderPatternObjectWrapper {
            // Header item
            return outlineView.make(withIdentifier: "HeaderCell", owner: nil)
        } else if let tableColumn = tableColumn {
            // regular item
            return outlineView.make(withIdentifier: tableColumn.identifier, owner: nil)
        } else {
            return nil
        }
    }
    
    func outlineView(_ outlineView: NSOutlineView, rowViewForItem item: Any) -> NSTableRowView? {
        if item is HeaderPatternObjectWrapper {
            return outlineView.make(withIdentifier: "FloatingRowView", owner: nil) as? NSTableRowView
        } else {
            return outlineView.make(withIdentifier: "DarkRowView", owner: nil) as? NSTableRowView
        }
    }
    
    func outlineView(_ outlineView: NSOutlineView, heightOfRowByItem item: Any) -> CGFloat {
        if item is HeaderPatternObjectWrapper {
            return outlineView.rowHeight + 4 // A little bigger/taller to look better w/the bold font
        } else {
            return outlineView.rowHeight
        }
    }
    
    func _acceptableTypesFromPasteboard(_ pasteboard: NSPasteboard) -> [URL] {
//        let options: [NSString: AnyObject] = [NSString(string: NSPasteboardURLReadingFileURLsOnlyKey): true, NSString(string: NSPasteboardURLReadingContentsConformToTypesKey): NSString(string: "com.microsoft.bmp") ]
//        let options: [String: AnyObject] = [NSPasteboardURLReadingFileURLsOnlyKey: true as AnyObject, NSPasteboardURLReadingContentsConformToTypesKey: ["com.microsoft.bmp"] ] // Swift 1

//        let k = NSPasteboard.ReadingOptionKey.urlReadingContentsConformToTypes
        
        let options: [String : Any] = [NSPasteboardURLReadingFileURLsOnlyKey : true, NSPasteboardURLReadingContentsConformToTypesKey : ["com.microsoft.bmp"] ] // Swift 3
        
        // syntax HAS to be This stupidness
        let aClass : AnyClass = NSURL.self
        let classes = [aClass]
        let objects = pasteboard.readObjects(forClasses: classes, options: options)
//        let objects = pasteboard.readObjects(forClasses: [URL.self], options: options) // swift 4?
        
        if let urls = objects as? [URL] {
            return urls
        }
        return []
    }
    
    func outlineView(_ outlineView: NSOutlineView, validateDrop info: NSDraggingInfo, proposedItem item: Any?, proposedChildIndex index: Int) -> NSDragOperation {
        // we only accept image types on image folders..
        if let imageItem = item as? ImagePatternObjectWrapper {
            if imageItem.isDirectory {
                // allow it
                // TODO: make sure it doesn't exist already with the same name, or it is coming from the same parent folder!
                if _acceptableTypesFromPasteboard(info.draggingPasteboard()).count > 0 {
                    return NSDragOperation.copy
                }
            }
        }
        return NSDragOperation()
        
    }
    
    func outlineView(_ outlineView: NSOutlineView, acceptDrop info: NSDraggingInfo, item: Any?, childIndex index: Int) -> Bool {
        var result = false;
        if let imageItem = item as? ImagePatternObjectWrapper {
            if imageItem.isDirectory {
                _outlineView.beginUpdates()
                
                let urls = _acceptableTypesFromPasteboard(info.draggingPasteboard())
                if urls.count > 0 {
                    let baseURL = imageItem.url
                    var insertIndex = index
                    if insertIndex == -1 {
                        insertIndex = imageItem.children!.count
                    }
                    
                    do {
                        for url in urls {
                            let urlToCopyTo = baseURL?.appendingPathComponent(url.lastPathComponent)
                            try FileManager.default.copyItem(at: url, to: urlToCopyTo!)
                            
                            let label = url.lastPathComponent
                            let newWrapperChild = ImagePatternObjectWrapper(label: label, url: urlToCopyTo!, parent: imageItem)
                            imageItem.children!.insert(newWrapperChild, at: insertIndex)
                            _outlineView.insertItems(at: IndexSet(integer: insertIndex), inParent: imageItem, withAnimation: .slideDown)
                            insertIndex += 1
                        }
                    } catch let error as NSError  {
                        //NSLog("Error loading children: %@", error)
                        self.view.window!.presentError(error)
                    }
                    result = true
                }
                _outlineView.endUpdates()
            }
        }
        return result
    }

    // Cmd-R to reveal the image in finder.
    @IBAction func revealInFinder(_ sender: AnyObject) {
        if let item = _outlineView.selectedItem as? ImagePatternObjectWrapper {
            NSWorkspace.shared().selectFile(item.url.path, inFileViewerRootedAtPath: "")
        }
    }
    


    
}
