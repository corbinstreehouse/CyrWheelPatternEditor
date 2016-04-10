//
//  CDTimelineView.swift
//  CyrWheelPatternEditor
//
//  Created by Corbin Dunn on 4/9/16 .
//  Copyright © 2016 Corbin Dunn. All rights reserved.
//

import Cocoa


class CDTimelineView: NSView {
    // Variables
    let timelineSeperatorWidth: CGFloat = 110.0 // They appear every 110 pts
    let startingOffset: CGFloat = 4.0 // they start at this offset
    let seperatorWidth: CGFloat = 1.0
    let textStartyingY: CGFloat = 1.0 // A better way??

    private func _commonInit() {
        self.layerContentsRedrawPolicy = .OnSetNeedsDisplay
        self.appearance = NSAppearance(named: NSAppearanceNameVibrantDark)
    }
    
    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        _commonInit()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        _commonInit()
        // find all the track views already added to us
        for subview in self.subviews {
            if let timelineTrackView = subview as? CDTimelineTrackView {
                _timelineTrackViews.append(timelineTrackView)
            }
        }
    }
    
    // Keep track of the track views
    var _timelineTrackViews: [CDTimelineTrackView] = []
    
    override func didAddSubview(subview: NSView) {
        super.didAddSubview(subview)
        if let timelineTrackView = subview as? CDTimelineTrackView {
            _timelineTrackViews.append(timelineTrackView)
        }
    }
    override func willRemoveSubview(subview: NSView) {
        super.willRemoveSubview(subview)
        if let timelineTrackView = subview as? CDTimelineTrackView {
            if let index = _timelineTrackViews.indexOf(timelineTrackView) {
                _timelineTrackViews.removeAtIndex(index)
            }
        }
    }
    
    override var intrinsicContentSize : NSSize {
        get {
            var requestedSize = super.intrinsicContentSize
            // Make sure we fill our children timelines
            for timelineTrackView in _timelineTrackViews {
                requestedSize.width = max(timelineTrackView.intrinsicContentSize.width, requestedSize.width);
            }
            
            if let superview = self.superview {
                // Make sure we fill the super
                let superBounds = superview.bounds;
                requestedSize.height = superBounds.size.height;
                // fill the height
                if requestedSize.width < superBounds.size.width {
                    requestedSize.width = superBounds.size.width
                }
            }
            return requestedSize
        }
    }
    
    
    var widthPerMS: CGFloat = CDTimelineItemView.defaultWidthPerSecond / 1000.0 {
        didSet {
            _removeAllTimeViews()
            self.needsLayout = true
        }
    }
    
    override func setFrameSize(newSize: NSSize) {
        super.setFrameSize(newSize)
        self.needsLayout = true;
    }
    
    private var _timeViews: [(NSView, NSTextField)] = []
    
    func _removeAllTimeViews() {
        for (seperator, textField) in _timeViews {
            seperator.removeFromSuperview()
            textField.removeFromSuperview()
        }
        _timeViews = []
    }
    
    func _makeSeperatorViewWithFrame(frame: NSRect) -> NSView {
        let view = CDBorderedView(frame: frame)
        view.backgroundColor = CDThemeColors.timecodeSeparatorColor
        return view
    }
    
    func _makeTimeView(frame: NSRect, timeStr: String) -> NSTextField {
        let view = NSTextField(frame: frame)
        view.stringValue = timeStr
        view.font = NSFont.systemFontOfSize(10)
        view.drawsBackground = false
        view.backgroundColor = NSColor.clearColor()
        view.bordered = false
        view.textColor = CDThemeColors.timecodeTextColor
        return view
    }
    
    override var flipped: Bool { return true; }
    
    func _updateTimeViews() {
        // Figure out how many we need.
        let bounds = self.bounds
        let width = bounds.size.width
        let countNeeded: Int = Int(ceil((width - self.startingOffset) / self.timelineSeperatorWidth))


        var sepBounds = bounds
        sepBounds.size.width = self.seperatorWidth
        sepBounds.origin.x = self.startingOffset
        
        var textBounds = bounds
        textBounds.size.width = self.timelineSeperatorWidth - self.seperatorWidth
        textBounds.size.height = 14.0 // better way than hardcoding?
        textBounds.origin.x = self.startingOffset + self.seperatorWidth
        textBounds.origin.y = self.textStartyingY // This is ugly..
        
        for var i = _timeViews.count; i <= countNeeded; i++ {
            let sepView = _makeSeperatorViewWithFrame(sepBounds)
            self.addSubview(sepView)

            let timecodeStr = "00:00:000"
            let timeView = _makeTimeView(textBounds, timeStr: timecodeStr)
            self.addSubview(timeView)
            
            _timeViews.append((sepView, timeView))
            
            sepBounds.origin.x += self.timelineSeperatorWidth
            textBounds.origin.x += self.timelineSeperatorWidth
        }
        
        
        
        // Remove the extras
        
        

        // bring the trakcs on top
        for timelineTrackView in _timelineTrackViews {
            self.addSubview(timelineTrackView, positioned: NSWindowOrderingMode.Above, relativeTo: nil)
        }

    }
    
    override func layout() {
        super.layout()
        _updateTimeViews()
    }
    
    
    
}
