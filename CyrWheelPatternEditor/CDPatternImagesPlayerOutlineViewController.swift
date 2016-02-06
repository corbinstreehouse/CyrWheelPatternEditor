//
//  CDPatternImagesPlayerOutlineViewController.swift
//  CyrWheelPatternEditor
//
//  Created by Corbin Dunn on 2/4/16 .
//  Copyright © 2016 Corbin Dunn. All rights reserved.
//

import Cocoa

class CDPatternImagesPlayerOutlineViewController: CDPatternImagesOutlineViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        _outlineView.allowsMultipleSelection = false
    }
    
    dynamic var connectedWheel: CDWheelConnection? = nil {
        didSet {
            _updateButtonState();
        }
    }

    @IBAction func _outlineDoubleClick(sender: NSOutlineView) {
        if let item = _getPlayableItemAtRow(_outlineView.selectedRow) {
            _playItem(item)
        }
    }
    
    func outlineViewSelectionDidChange(notification: NSNotification) {
        _updateButtonState()
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
                if let item = _getPlayableItemAtRow(selectedRow) {
                    _outlineView.selectRowIndexes(NSIndexSet(index: selectedRow), byExtendingSelection: false)
                    _outlineView.scrollRowToVisible(selectedRow)
                    _playItem(item)
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
                if let item = _getPlayableItemAtRow(selectedRow) {
                    _outlineView.selectRowIndexes(NSIndexSet(index: selectedRow), byExtendingSelection: false)
                    _outlineView.scrollRowToVisible(selectedRow)
                    _playItem(item)
                    break;
                }
                selectedRow--
            }
        }
    }
    
    @IBAction func patternPlay(sender: AnyObject?) {
        if let item = _getPlayableItemAtRow(_outlineView.selectedRow) {
            _playItem(item)
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
    
    private func _playItem(item: PatternObjectWrapper) {
        switch item {
        case let programmedItem as ProgrammedPatternObjectWrapper:
            // TODO: update the color that it has stored in it..
            var rgbColor: CRGB!
            if let color = programmedItem.color {
                let r = UInt8(round(color.redComponent*255.0))
                let g = UInt8(round(color.greenComponent*255.0))
                let b = UInt8(round(color.blueComponent*255.0))
                rgbColor = CRGB(red: r, green: g, blue: b);
            } else {
                rgbColor = CRGB(red: 255, green: 0, blue: 0);
            }
            
            let duration: UInt32 = 50
            
            connectedWheel!.setDynamicPatternType(programmedItem.patternType, color: rgbColor, duration: duration)
        case let imageItem as ImagePatternObjectWrapper:
            break
            
        default: break
            
        }

        
        
        
    }
    
    private func _canPlaySelectedItem() -> Bool {
        return _getPlayableSelectedItemWrapper() != nil
    }
    
    func _getPlayableItemAtRow(row: Int) -> PatternObjectWrapper? {
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
            default:
                return nil
            }
        } else {
            return nil
        }
    }
    
    func _getPlayableSelectedItemWrapper() -> PatternObjectWrapper? {
        return _getPlayableItemAtRow(_outlineView.selectedRow)
    }
    
    
}
