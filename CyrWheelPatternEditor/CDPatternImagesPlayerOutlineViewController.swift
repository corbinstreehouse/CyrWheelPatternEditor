//
//  CDPatternImagesPlayerOutlineViewController.swift
//  CyrWheelPatternEditor
//
//  Created by Corbin Dunn on 2/4/16 .
//  Copyright © 2016 Corbin Dunn. All rights reserved.
//

import Cocoa

extension NSRange {
    func toRange() -> CountableRange<Int> {
        return (location ..< location + length)
    }
}

class CDPatternImagesCellView : NSTableCellView {
    @IBOutlet weak var _uploadButton: NSButton!
    @IBOutlet weak var _uploadButtonTrailingConstraint: NSLayoutConstraint!
    
}

class CDPatternImagesPlayerOutlineViewController: CDPatternImagesOutlineViewController, CDWheelConnectionPresenter, CDPatternItemHeaderWrapperChanged, CDWheelConnectionSequencesPresenter {

    override func viewDidLoad() {
        super.viewDidLoad()
        let defs = UserDefaults.standard
        if defs.value(forKey: "shouldShowPreview") != nil {
            shouldShowPreview = defs.bool(forKey: "shouldShowPreview")
        }
        if defs.value(forKey: "shouldAutoPlayOnWheel") != nil {
            shouldAutoPlayOnWheel = defs.bool(forKey: "shouldAutoPlayOnWheel")
        }
        
        _outlineView.allowsMultipleSelection = false
        _updateButtonState()
    }
    
    override func outlineView(_ outlineView: NSOutlineView, viewFor tableColumn: NSTableColumn?, item: Any) -> NSView? {
        let result = super.outlineView(outlineView, viewFor: tableColumn, item: item)
        
        if let cellView = result as? CDPatternImagesCellView {
//            cellView.appearance = NSAppearance(named: NSAppearanceNameVibrantDark)
//            cellView._uploadButton.image!.template = true
            // hide the button on dirs and programmed patterns
            var uploadButtonIsHidden = true
            if let imageItem = item as? ImagePatternObjectWrapper {
                if !imageItem.isDirectory {
                    // TODO: Only show it if it is not on the other side..
                    uploadButtonIsHidden = false;
                }
            }
            cellView._uploadButton.isHidden = uploadButtonIsHidden
            cellView._uploadButtonTrailingConstraint.constant = uploadButtonIsHidden ? -cellView._uploadButton.frame.size.width : 0;
        }
        
        return result
    }

    
    dynamic var connectedWheel: CDWheelConnection? = nil {
        didSet {
            if self.isViewLoaded {
                _updateButtonState();
                if let wheel = connectedWheel {
                    self.customSequences = wheel.customSequences
                }
            }
        }
    }

    @IBAction func _outlineDoubleClick(_ sender: NSOutlineView) {
        if connectedWheel != nil {
            if let item = _getPlayableItemAtRow(_outlineView.selectedRow) {
                _playItem(item)
            }
        }
    }
    
    fileprivate var _playTimer: Timer? = nil
    func _playSelectedItemAfterSlightDelay() {
        if let timer = _playTimer {
            timer.invalidate()
        }
        _playTimer = Timer.scheduledTimer(timeInterval: 0.3, target: self, selector: #selector(CDPatternImagesPlayerOutlineViewController._playTimerFired(_:)), userInfo: nil, repeats: false)
    }
    func _playTimerFired(_ sender: AnyObject?) {
        _playSelectedItem()
        _playTimer = nil
    }
    
    // for bindings
    dynamic var selectedItem: CDPatternItemHeaderWrapper? {
        didSet {
            detailViewController.representedObject = _outlineView.selectedItem
            // Make sure we are the delegate
            if let item = _outlineView.selectedItem as? CDPatternItemHeaderWrapper {
                item.delegate = self
            }
        }
    }
    
    func _updateAllStateForSelectionChanged() {
        _updateButtonState()
        // Setup a temporary represention to play in the simulator..
        _updatePreview()
        if shouldAutoPlayOnWheel {
            // Process on a slight delay when from a selection change to avoid pounding the BLTE and making it being unable to keep up..
            _playSelectedItemAfterSlightDelay()
        }
        self.selectedItem = _outlineView.selectedItem as? CDPatternItemHeaderWrapper
    }
    
    internal var _customSequenceChildren: [CDPatternItemHeaderWrapper] = []
    
    internal var customSequences: [String] = [] {
        didSet {
            // Diff the two and apply the updates to the outlineView
            // First a header section
            // everything is hardcoded at the start
            if oldValue.count == 0 && customSequences.count == 0 {
                // ignore empty to empty
            } else if oldValue.count == 0 {
                // Inserting everything new
                // Add a header
                let programmedPatternGroupObject = HeaderPatternObjectWrapper(label: "Custom Sequences")
                _customSequenceChildren.append(programmedPatternGroupObject)
                for sequenceFilename in customSequences {
                    let wrapper = CustomSequencePatternObjectWrapper(relativeFilename: sequenceFilename)
                    _customSequenceChildren.append(wrapper);
                }
                _rootChildren.insert(contentsOf: _customSequenceChildren, at: 0)
                let insertionRange = 0 ..< _customSequenceChildren.count
                let insertionIndexes = IndexSet(integersIn: insertionRange)
                _outlineView.insertItems(at: insertionIndexes, inParent: nil, withAnimation: .slideDown)
            } else if customSequences.count == 0 {
                // Remove everything; capture the range first...
//                let range = NSRange(location: 0, length: _customSequenceChildren.count)
//                _rootChildren.removeSubrange(range.toRange())
                let range = 0 ..< _customSequenceChildren.count
                _rootChildren.removeSubrange(range)
                _customSequenceChildren = []
                let removeIndexes = IndexSet(integersIn: range)
                _outlineView.removeItems(at: removeIndexes, inParent: nil, withAnimation: .slideUp)
            } else {
                _outlineView.beginUpdates()
                // "Diff" the two arrays in a simple way
                var oldCustomSequences = oldValue
                for i in 0 ..< customSequences.count {
                    if let oldIndex = oldCustomSequences.index(of: customSequences[i]) {
                        // Note that as we insert above, the stuff left offset is always lower than index
                        // Move this item, if needed, and remove it from our items that we know we processed
                        let oldIndexInTable = i + oldIndex;
                        if oldIndexInTable != i {
                            // +1 is the header offset
                            // Add one for the header...bah...
                            _outlineView.moveItem(at: oldIndexInTable + 1, inParent: nil, to: i + 1, inParent: nil)
                            // Keep the "model" up to date too
                            let tmp = _customSequenceChildren[oldIndexInTable + 1]
                            _customSequenceChildren.remove(at: oldIndexInTable + 1)
                            _customSequenceChildren.insert(tmp, at: i + 1)
                        }
                        
                        // oldCustomSequences is really kept around just so I can find the updated indexes. I could probabl do this faster/better...
                        oldCustomSequences.remove(at: oldIndex)
                    } else {
                        // Insert it at "i"
                        let wrapper = CustomSequencePatternObjectWrapper(relativeFilename: customSequences[i])
                        let wrapperIndex = i + 1 // accounts for header
                        // Wasn't around before..so it is new and add it at the end
                        _customSequenceChildren.insert(wrapper, at: wrapperIndex)
                        // It is trickier to find out where to insert it into the root children
                        _rootChildren.insert(wrapper, at: wrapperIndex)
                        // And same goes for the outlienview
                        _outlineView.insertItems(at: IndexSet(integer: wrapperIndex), inParent: nil, withAnimation: .slideDown)
                    }
                }
                
                // Remove all the old stuff left; now pushed at the bottom
                if oldCustomSequences.count > 0 {
                    // again, offset for the header
                    let range =  NSMakeRange(customSequences.count + 1, oldCustomSequences.count);
                    _outlineView.removeItems(at: IndexSet(integersIn: range.toRange() ?? 0..<0), inParent: nil, withAnimation: .slideUp)
                    _customSequenceChildren.removeSubrange(range.toRange())
                }
                
                _outlineView.endUpdates()
            }
        }
    }
    
    override func outlineViewSelectionDidChange(_ notification: Notification) {
        super.outlineViewSelectionDidChange(notification);
        _updateAllStateForSelectionChanged()
    }

    // Set by a parent to another thing that is doing the running
    var patternRunner: CDPatternRunner?
    
    fileprivate func _updatePreview() {
        guard shouldShowPreview else { _clearPreview(); return }
        guard let item = _getPlayableItemAtRow(_outlineView.selectedRow) else { _clearPreview(); return }
        
        switch item {
        case let programmedItem as ProgrammedPatternObjectWrapper:
            patternRunner?.loadDynamicPatternType(programmedItem.patternType, patternSpeed: programmedItem.speed, patternColor: programmedItem.color)
            patternRunner?.play()
            break
        case let imageItem as ImagePatternObjectWrapper:
            patternRunner?.loadDynamicBitmapPatternType(withFilename: imageItem.relativeFilename, patternSpeed: imageItem.speed, bitmapOptions: imageItem.bitmapPatternOptions)
            patternRunner?.play()
            break
        case _ as CustomSequencePatternObjectWrapper:
            // No preview yet...we'd have to download the item
            patternRunner?.setBlackAndPause()
            break;
        default:
            break
        }
    }
    
    fileprivate func _selectAndAttemptToPlayAtRow(_ selectedRow: Int) -> Bool {
        if _getPlayableItemAtRow(selectedRow) != nil {
            _outlineView.selectRowIndexes(IndexSet(integer: selectedRow), byExtendingSelection: false)
            _outlineView.scrollRowToVisible(selectedRow)
            _updateAllStateForSelectionChanged()
            return true
        } else {
            return false
        }
    }
    
    // Button actions
    @IBAction func patternNext(_ sender: AnyObject?) {
        // Select the next row and do a play
        var selectedRow = _outlineView.selectedRow
        if selectedRow != -1 {
            selectedRow += 1
            while (selectedRow < _outlineView.numberOfRows) {
                if let itemAtRow = _outlineView.item(atRow: selectedRow) {
                    // If it is expandable..expand it..and go to it's first child
                    if _outlineView.isExpandable(itemAtRow) && !_outlineView.isItemExpanded(itemAtRow) {
                        _outlineView.expandItem(itemAtRow) // numberOfRows is now larger.
                        selectedRow += 1
                    }
                }
                if _selectAndAttemptToPlayAtRow(selectedRow) {
                    break;
                }
                selectedRow += 1
            }
        }
    }
    
    @IBAction func patternPrior(_ sender: AnyObject?) {
        var selectedRow = _outlineView.selectedRow
        if selectedRow != -1 {
            selectedRow -= 1
            while (selectedRow > 0) {
                if _selectAndAttemptToPlayAtRow(selectedRow) {
                    break;
                }
                selectedRow -= 1
            }
        }
    }
    
    fileprivate func _playSelectedItem() {
        if let item = _getPlayableItemAtRow(_outlineView.selectedRow) {
            _playItem(item)
        }
    }
    
    fileprivate func _clearPreview() {
        patternRunner?.setBlackAndPause()
    }
    
    @IBAction func patternPlay(_ sender: AnyObject?) {
        if let item = _getPlayableItemAtRow(_outlineView.selectedRow) {
            _playItem(item)
        }
    }
    
    var detailViewController: CDWheelPlayerDetailViewController! {
        didSet {
            // Bind some of the UI to us
            detailViewController.chkbxShowPreview.state = shouldShowPreview ? 1 : 0
            self.bind("shouldShowPreview", to: detailViewController.chkbxShowPreview, withKeyPath: "cell.state", options: nil)
            detailViewController.chkbxAutoPlayOnWheel.state = shouldAutoPlayOnWheel ? 1 : 0
            self.bind("shouldAutoPlayOnWheel", to: detailViewController.chkbxAutoPlayOnWheel, withKeyPath: "cell.state", options: nil)
            detailViewController.btnPlayOnWheel.cell!.bind("enabled", to: self, withKeyPath: "patternPlayEnabled", options: nil)
            detailViewController.btnPlayOnWheel.target = self
            detailViewController.btnPlayOnWheel.action = #selector(CDPatternImagesPlayerOutlineViewController.patternPlay(_:))
            _updateAllStateForSelectionChanged()
        }
    }
    
    func _commonUpdateAfterItemPropertyChanged() {
        _updatePreview()
        if shouldAutoPlayOnWheel {
            // Process on a slight delay when from a selection change to avoid pounding the BLTE and making it being unable to keep up..
            _playSelectedItemAfterSlightDelay()
        }
    }
    
    func patternItemSpeedChanged(_ item: CDPatternItemHeaderWrapper) {
        _commonUpdateAfterItemPropertyChanged()
    }
    
    func patternItemColorChanged(_ item: CDPatternItemHeaderWrapper) {
        _commonUpdateAfterItemPropertyChanged()
    }
    
    func patternItemVelocityBasedBrightnessChanged(_ item: CDPatternItemHeaderWrapper) {
        _commonUpdateAfterItemPropertyChanged()
    }
    
    func patternItemBitmapOptionsChanged(_ item: CDPatternItemHeaderWrapper) {
        _commonUpdateAfterItemPropertyChanged()
    }
    
    dynamic var shouldShowPreview: Bool = true {
        didSet {
            _updatePreview()
            UserDefaults.standard.set(shouldShowPreview, forKey: "shouldShowPreview")
        }
    }
    
    dynamic var shouldAutoPlayOnWheel: Bool = true {
        didSet {
            if shouldAutoPlayOnWheel {
                _playSelectedItem()
            }
            UserDefaults.standard.set(shouldAutoPlayOnWheel, forKey: "shouldAutoPlayOnWheel")
        }
    }
    
    //  For bindings on the buttons
    dynamic var patternNextEnabled: Bool = false;
    dynamic var patternPriorEnabled: Bool = false;
    dynamic var patternPlayEnabled: Bool = false;
    
    fileprivate func _updateButtonState() {
        if connectedWheel != nil && _outlineView.selectedRow != -1 {
            patternNextEnabled = _outlineView.selectedRow < (_outlineView.numberOfRows - 1)
            patternPriorEnabled = _outlineView.selectedRow > 1 // row 0 is a header
            patternPlayEnabled = _canPlaySelectedItem()
        } else {
            patternNextEnabled = false
            patternPriorEnabled = false
            patternPlayEnabled = false
        }
    }
    
    fileprivate func _playItem(_ item: CDPatternItemHeaderWrapper) {
        // We might not have a conneciton, so do nothing then
        if let connectedWheel = connectedWheel {
            switch item {
            case let programmedItem as ProgrammedPatternObjectWrapper:
                let color = programmedItem.color.usingColorSpace(NSColorSpace.sRGB)!
                let r = UInt8(round(color.redComponent*255.0))
                let g = UInt8(round(color.greenComponent*255.0))
                let b = UInt8(round(color.blueComponent*255.0))
                let rgbColor = CRGB(red: r, green: g, blue: b);
                // Convert the speed to a duration
                let duration: UInt32 = CDPatternDurationForPatternSpeed(item.speed, item.patternType)
                connectedWheel.setDynamicPatternType(programmedItem.patternType, color: rgbColor, duration: duration)
            case let imageItem as ImagePatternObjectWrapper:
                // Convert the speed to a duration
                let duration: UInt32 = CDPatternDurationForPatternSpeed(item.speed, item.patternType)

                connectedWheel.setDynamicImagePattern(imageItem.relativeFilename, duration: duration, bitmapOptions: imageItem.bitmapPatternOptions)
            case let sequenceItem as CustomSequencePatternObjectWrapper:
                connectedWheel.playPatternSequence(sequenceItem.relativeFilename)
                break;

            default:
                break
            }
        }
    }
    
    fileprivate func _canPlaySelectedItem() -> Bool {
        return _getPlayableSelectedItemWrapper() != nil
    }
    
    func _getPlayableItemAtRow(_ row: Int) -> CDPatternItemHeaderWrapper? {
        if (row >= 0 && row < _outlineView.numberOfRows) {
            let item = _outlineView.item(atRow: row)
            switch item {
            case let programmedItem as ProgrammedPatternObjectWrapper:
                return programmedItem
            case let imageItem as ImagePatternObjectWrapper:
                if !imageItem.isDirectory {
                    return imageItem
                } else {
                    return nil
                }
            case let programmedItem as CustomSequencePatternObjectWrapper:
                return programmedItem
            default:
                return nil
            }
        } else {
            return nil
        }
    }
    
    func _getPlayableSelectedItemWrapper() -> CDPatternItemHeaderWrapper? {
        return _getPlayableItemAtRow(_outlineView.selectedRow)
    }
    
    @IBAction func btnUploadFileClicked(_ sender: NSButton) {
        if let wheel = self.connectedWheel {
            if !wheel.uploading {
                _doAddWithOpenPanel()
            }
        }
    }
    
    @IBAction func btnDeleteClicked(_ sender: NSButton) {
        if let wheel = self.connectedWheel {
            if wheel.uploading {
                return;
            }
            
            guard let item = _outlineView.selectedItem as? CustomSequencePatternObjectWrapper else { return }
            
            let alert = NSAlert()
            alert.messageText = "Are you sure you want to delete the file? You can't undo this."
            alert.alertStyle = NSAlertStyle.critical
            let buttonOK = alert.addButton(withTitle: "OK")
            buttonOK.tag = NSModalResponseOK
            let cancelButton = alert.addButton(withTitle: "Cancel")
            cancelButton.tag = NSModalResponseCancel
            
            alert.beginSheetModal(for: self.view.window!, completionHandler: { (r: NSModalResponse) -> Void in
                if r == NSModalResponseOK {
                    wheel.removeFile(item.relativeFilename);
                }
            })
        }
    }
    
    // this does the upload with UI feedback
    fileprivate func _uploadFileFromURL(_ url: URL, filename: String, isSequenceFile: Bool, wheel: CDWheelConnection) {
        
        let vc = self.storyboard!.instantiateController(withIdentifier: "CDUploadProgressViewController") as! CDUploadProgressViewController
        vc.filename = "Uploading: " + filename
        self.presentViewControllerAsSheet(vc)
        
        wheel.uploadFileFromURL(url, filename: filename) { (uploadProgressAmount, finished, error) -> Void in
            vc.progress = uploadProgressAmount * 100.0
            if finished {
                vc.dismiss(nil)
                if let error = error {
                    self.view.window!.presentError(error)
                } else {
                    // When doing sequences, ask for them again
                    if (isSequenceFile) {
                        wheel.requestCustomSequences()
                    }
                }
            } else if uploadProgressAmount == 1.0 {
                vc.filename = "Waiting for confirmation receipt..."
            }
        }

    }

    fileprivate func _uploadSequenceFileAtURL(_ url: URL) {
        if let wheel = self.connectedWheel {
            var filename: String!
            // swap to a .pat extension if it isn't a .pat
            if url.pathExtension != "pat" {
                filename = url.deletingPathExtension().appendingPathExtension("pat").lastPathComponent
            } else {
                filename = url.lastPathComponent
            }
            
            if wheel.customSequences.contains(filename) {
                let alert = NSAlert()
                alert.messageText = "A file already exists on the wheel with that name. Replace it?"
                alert.alertStyle = NSAlertStyle.critical
                let buttonOK = alert.addButton(withTitle: "OK")
                buttonOK.tag = NSModalResponseOK
                let cancelButton = alert.addButton(withTitle: "Cancel")
                cancelButton.tag = NSModalResponseCancel
                
                alert.beginSheetModal(for: self.view.window!, completionHandler: { (r: NSModalResponse) -> Void in
                    if r == NSModalResponseOK {
                        self._uploadFileFromURL(url, filename: filename, isSequenceFile: true, wheel: wheel);
                    }
                })
                
            } else {
                self._uploadFileFromURL(url, filename: filename, isSequenceFile: true, wheel: wheel);
            }
        }
    }
    
    fileprivate func _doAddWithOpenPanel() {
        let openPanel = NSOpenPanel()
        openPanel.title = "Select a pattern sequence"
        openPanel.allowedFileTypes = [gPatternFilenameExtension, gSequenceEditorExtension]
        openPanel.allowsOtherFileTypes = false
        openPanel.beginSheetModal(for: self.view.window!) { (result: Int) -> Void in
            if result == NSModalResponseOK {
                openPanel.orderOut(self)
                self._uploadSequenceFileAtURL(openPanel.url!)
            }
        }
        
    }
    
    @IBAction func _cellBtnUploadClicked(_ sender: NSButton) {
        if let wheel = self.connectedWheel {
            if wheel.uploading {
                return;
            }
            
            let row = _outlineView.row(for: sender)
            let item = _outlineView.item(atRow: row)
            if let imageItem = item as? ImagePatternObjectWrapper {
                if !imageItem.isDirectory {
                    // Going to the root!
                    
                    
                    let alert = NSAlert()
                    let filename = "/" + imageItem.relativeFilename
                    alert.messageText = "Are you sure you want to upload " + filename + "?"
                    alert.alertStyle = NSAlertStyle.critical
                    let buttonOK = alert.addButton(withTitle: "OK")
                    buttonOK.tag = NSModalResponseOK
                    let cancelButton = alert.addButton(withTitle: "Cancel")
                    cancelButton.tag = NSModalResponseCancel
                    
                    alert.beginSheetModal(for: self.view.window!, completionHandler: { (r: NSModalResponse) -> Void in
                        if r == NSModalResponseOK {
                            self._uploadFileFromURL(imageItem.url as URL, filename: filename, isSequenceFile: false, wheel: wheel);
                        }
                    })
                    
                }
            }
        }
    }
    
    
    
}
