//
//  CDPatternImagesPlayerOutlineViewController.swift
//  CyrWheelPatternEditor
//
//  Created by Corbin Dunn on 2/4/16 .
//  Copyright © 2016 Corbin Dunn. All rights reserved.
//

import Cocoa


class CDPatternImagesPlayerOutlineViewController: CDPatternImagesOutlineViewController, CDWheelConnectionPresenter, CDPatternItemHeaderWrapperChanged, CDWheelConnectionSequencesPresenter {

    override func viewDidLoad() {
        super.viewDidLoad()
        let defs = NSUserDefaults.standardUserDefaults()
        if defs.valueForKey("shouldShowPreview") != nil {
            shouldShowPreview = defs.boolForKey("shouldShowPreview")
        }
        if defs.valueForKey("shouldAutoPlayOnWheel") != nil {
            shouldAutoPlayOnWheel = defs.boolForKey("shouldAutoPlayOnWheel")
        }
        
        _outlineView.allowsMultipleSelection = false
        _updateButtonState()
    }
    
    dynamic var connectedWheel: CDWheelConnection? = nil {
        didSet {
            if self.viewLoaded {
                _updateButtonState();
                if let wheel = connectedWheel {
                    self.customSequences = wheel.customSequences
                }
            }
        }
    }

    @IBAction func _outlineDoubleClick(sender: NSOutlineView) {
        if connectedWheel != nil {
            if let item = _getPlayableItemAtRow(_outlineView.selectedRow) {
                _playItem(item)
            }
        }
    }
    
    private var _playTimer: NSTimer? = nil
    func _playSelectedItemAfterSlightDelay() {
        if let timer = _playTimer {
            timer.invalidate()
        }
        _playTimer = NSTimer.scheduledTimerWithTimeInterval(0.3, target: self, selector: Selector("_playTimerFired:"), userInfo: nil, repeats: false)
    }
    func _playTimerFired(sender: AnyObject?) {
        _playSelectedItem()
        _playTimer = nil
    }
    
    func _updateAllStateForSelectionChanged() {
        _updateButtonState()
        // Setup a temporary represention to play in the simulator..
        _updatePreview()
        if shouldAutoPlayOnWheel {
            // Process on a slight delay when from a selection change to avoid pounding the BLTE and making it being unable to keep up..
            _playSelectedItemAfterSlightDelay()
        }

        // Bindings will update based on this..
        detailViewController.representedObject = _outlineView.selectedItem
        // Make sure we are the delegate
        if let item = _outlineView.selectedItem as? CDPatternItemHeaderWrapper {
            item.delegate = self
        }
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
                _rootChildren.insertContentsOf(_customSequenceChildren, at: 0)
                let range = NSRange(location: 0, length: _customSequenceChildren.count)
                _outlineView.insertItemsAtIndexes(NSIndexSet(indexesInRange: range), inParent: nil, withAnimation: .SlideDown)
            } else if customSequences.count == 0 {
                // Remove everything; capture the range first...
                let range = NSRange(location: 0, length: _customSequenceChildren.count)
                _rootChildren.removeRange(Range<Int>(start: 0, end: _customSequenceChildren.count))
                _customSequenceChildren = []
                
                _outlineView.removeItemsAtIndexes(NSIndexSet(indexesInRange: range), inParent: nil, withAnimation: .SlideUp)
            } else {
                _outlineView.beginUpdates()
                // "Diff" the two arrays in a simple way
                var oldCustomSequences = oldValue
                var oldCustomSequenceWrappers = _customSequenceChildren
                for var i = 0; i < customSequences.count; i++ {
                    if let oldIndex = oldCustomSequences.indexOf(customSequences[i]) {
                        // Note that as we insert above, the stuff left offset is always lower than index
                        // Move this item, if needed, and remove it from our items that we know we processed
                        let oldIndexInTable = i + oldIndex;
                        let oldWrapperIndex = oldIndexInTable + 1 // Accounts for the header that I insert..I really should make it have a parent/child relationship for header items.
                        if oldIndexInTable != i {
                            // +1 is the header offset
                            _outlineView.moveItemAtIndex(oldWrapperIndex, inParent: nil, toIndex: i+1, inParent: nil)
                        }
                        
                        // oldCustomSequences is really kept around just so I can find the updated indexes. I could probabl do this faster/better...
                        oldCustomSequences.removeAtIndex(oldIndex)
                        // Wrappers; one extra offset..
                        oldCustomSequenceWrappers.removeAtIndex(oldWrapperIndex)
                    } else {
                        let wrapperIndex = _customSequenceChildren.count // accounts for the header...
                        let wrapper = CustomSequencePatternObjectWrapper(relativeFilename: customSequences[i])
                        // Wasn't around before..so it is new and add it at the end
                        _customSequenceChildren.append(wrapper)
                        // It is trickier to find out where to insert it into the root children
                        _rootChildren.insert(wrapper, atIndex: wrapperIndex)
                        // And same goes for the outlienview
                        _outlineView.insertItemsAtIndexes(NSIndexSet(index: wrapperIndex), inParent: nil, withAnimation: .SlideDown)
                    }
                }
                
                // Remove all the old stuff left; now pushed at the bottom
                if oldCustomSequenceWrappers.count > 0 {
                    // again, offset for the header
                    let range =  NSMakeRange(customSequences.count + 1, oldCustomSequenceWrappers.count);
                    _outlineView.removeItemsAtIndexes(NSIndexSet(indexesInRange: range), inParent: nil, withAnimation: .SlideUp)
                }
                
                _outlineView.endUpdates()
            }
        }
    }
    
    func outlineViewSelectionDidChange(notification: NSNotification) {
        _updateAllStateForSelectionChanged()
    }

    // Set by a parent to another thing that is doing the running
    var patternRunner: CDPatternRunner?
    
    private func _updatePreview() {
        guard shouldShowPreview else { _clearPreview(); return }
        guard let item = _getPlayableItemAtRow(_outlineView.selectedRow) else { _clearPreview(); return }
        
        switch item {
        case let programmedItem as ProgrammedPatternObjectWrapper:
            patternRunner?.loadDynamicPatternType(programmedItem.patternType, patternSpeed: programmedItem.speed, patternColor: programmedItem.color)
            patternRunner?.play()
            break
        case let imageItem as ImagePatternObjectWrapper:
            patternRunner?.loadDynamicBitmapPatternTypeWithFilename(imageItem.relativeFilename, patternSpeed: imageItem.speed, bitmapOptions: imageItem.bitmapPatternOptions)
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
    
    private func _selectAndAttemptToPlayAtRow(selectedRow: Int) -> Bool {
        if _getPlayableItemAtRow(selectedRow) != nil {
            _outlineView.selectRowIndexes(NSIndexSet(index: selectedRow), byExtendingSelection: false)
            _outlineView.scrollRowToVisible(selectedRow)
            _updateAllStateForSelectionChanged()
            return true
        } else {
            return false
        }
    }
    
    // Button actions
    @IBAction func patternNext(sender: AnyObject?) {
        // Select the next row and do a play
        var selectedRow = _outlineView.selectedRow
        if selectedRow != -1 {
            selectedRow++
            while (selectedRow < _outlineView.numberOfRows) {
                if let itemAtRow = _outlineView.itemAtRow(selectedRow) {
                    // If it is expandable..expand it..and go to it's first child
                    if _outlineView.isExpandable(itemAtRow) && !_outlineView.isItemExpanded(itemAtRow) {
                        _outlineView.expandItem(itemAtRow) // numberOfRows is now larger.
                        selectedRow++
                    }
                }
                if _selectAndAttemptToPlayAtRow(selectedRow) {
                    break;
                }
                selectedRow++
            }
        }
    }
    
    @IBAction func patternPrior(sender: AnyObject?) {
        var selectedRow = _outlineView.selectedRow
        if selectedRow != -1 {
            selectedRow--
            while (selectedRow > 0) {
                if _selectAndAttemptToPlayAtRow(selectedRow) {
                    break;
                }
                selectedRow--
            }
        }
    }
    
    private func _playSelectedItem() {
        if let item = _getPlayableItemAtRow(_outlineView.selectedRow) {
            _playItem(item)
        }
    }
    
    private func _clearPreview() {
        patternRunner?.setBlackAndPause()
    }
    
    @IBAction func patternPlay(sender: AnyObject?) {
        if let item = _getPlayableItemAtRow(_outlineView.selectedRow) {
            _playItem(item)
        }
    }
    
    var detailViewController: CDWheelPlayerDetailViewController! {
        didSet {
            // Bind some of the UI to us
            detailViewController.chkbxShowPreview.state = shouldShowPreview ? 1 : 0
            self.bind("shouldShowPreview", toObject: detailViewController.chkbxShowPreview, withKeyPath: "cell.state", options: nil)
            detailViewController.chkbxAutoPlayOnWheel.state = shouldAutoPlayOnWheel ? 1 : 0
            self.bind("shouldAutoPlayOnWheel", toObject: detailViewController.chkbxAutoPlayOnWheel, withKeyPath: "cell.state", options: nil)
            detailViewController.btnPlayOnWheel.cell!.bind("enabled", toObject: self, withKeyPath: "patternPlayEnabled", options: nil)
            detailViewController.btnPlayOnWheel.target = self
            detailViewController.btnPlayOnWheel.action = Selector("patternPlay:")
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
    
    func patternItemSpeedChanged(item: CDPatternItemHeaderWrapper) {
        _commonUpdateAfterItemPropertyChanged()
    }
    
    func patternItemColorChanged(item: CDPatternItemHeaderWrapper) {
        _commonUpdateAfterItemPropertyChanged()
    }
    
    func patternItemVelocityBasedBrightnessChanged(item: CDPatternItemHeaderWrapper) {
        _commonUpdateAfterItemPropertyChanged()
    }
    
    func patternItemBitmapOptionsChanged(item: CDPatternItemHeaderWrapper) {
        _commonUpdateAfterItemPropertyChanged()
    }
    
    dynamic var shouldShowPreview: Bool = true {
        didSet {
            _updatePreview()
            NSUserDefaults.standardUserDefaults().setBool(shouldShowPreview, forKey: "shouldShowPreview")
        }
    }
    
    dynamic var shouldAutoPlayOnWheel: Bool = true {
        didSet {
            if shouldAutoPlayOnWheel {
                _playSelectedItem()
            }
            NSUserDefaults.standardUserDefaults().setBool(shouldAutoPlayOnWheel, forKey: "shouldAutoPlayOnWheel")
        }
    }
    
    //  For bindings on the buttons
    dynamic var patternNextEnabled: Bool = false;
    dynamic var patternPriorEnabled: Bool = false;
    dynamic var patternPlayEnabled: Bool = false;
    
    private func _updateButtonState() {
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
    
    private func _playItem(item: CDPatternItemHeaderWrapper) {
        // We might not have a conneciton, so do nothing then
        if let connectedWheel = connectedWheel {
            switch item {
            case let programmedItem as ProgrammedPatternObjectWrapper:
                let color = programmedItem.color.colorUsingColorSpace(NSColorSpace.sRGBColorSpace())!
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
    
    private func _canPlaySelectedItem() -> Bool {
        return _getPlayableSelectedItemWrapper() != nil
    }
    
    func _getPlayableItemAtRow(row: Int) -> CDPatternItemHeaderWrapper? {
        if (row >= 0 && row < _outlineView.numberOfRows) {
            let item = _outlineView.itemAtRow(row)
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
    
    
}
