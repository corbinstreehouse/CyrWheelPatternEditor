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
    let timelineSeperatorWidth: CGFloat = 80.0 // They appear every X pts
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
        view.editable = false
        return view
    }
    
    override var flipped: Bool { return true; }
    
    private func _timeForWidth(width: CGFloat) -> NSTimeInterval {
        return NSTimeInterval(width / self.widthPerMS / 1000)
    }
    
    private func _timeForXOffset(offset: CGFloat) -> NSTimeInterval {
        return _timeForWidth(offset - self.startingOffset)
    }
    
    private func _stringFromTimeInterval(interval: NSTimeInterval) -> String {
        let wholeSeconds = Int(interval)
        let seconds = wholeSeconds % 60
        let minutes = (wholeSeconds / 60) % 60
//        let hours = (wholeSeconds / 3600)
        let milliseconds = Int(round((interval-Double(wholeSeconds))*1000))
        // Ignore hours for now
        return String(format: "%02d:%02d:%03d", minutes, seconds, milliseconds)
    }
    
    func _updateTimeViews() {
        // Figure out how many we need.
        let bounds = self.bounds
        let width = bounds.size.width
        let countNeeded: Int = Int(ceil((width - self.startingOffset) / self.timelineSeperatorWidth))
        // Each pixel represents widthPerMS
        var sepBounds = bounds
        sepBounds.size.width = self.seperatorWidth
        // Start where we left off..
        sepBounds.origin.x = self.startingOffset + CGFloat(_timeViews.count) * self.timelineSeperatorWidth
        
        var textBounds = bounds
        textBounds.size.width = self.timelineSeperatorWidth - self.seperatorWidth
        textBounds.size.height = 14.0 // better way than hardcoding?
        textBounds.origin.x = sepBounds.minX + self.seperatorWidth
        textBounds.origin.y = self.textStartyingY // This is ugly..
        
        for var i = _timeViews.count; i <= countNeeded; i++ {
            let sepView = _makeSeperatorViewWithFrame(sepBounds)
            self.addSubview(sepView)

            var timecodeStr = "00:00:000"
            if i > 0 {
                // Format it each time to avoid rounding errors
                let time = _timeForXOffset(sepBounds.origin.x)
                timecodeStr = _stringFromTimeInterval(time)
            }
            
            let timeView = _makeTimeView(textBounds, timeStr: timecodeStr)
            self.addSubview(timeView)
            
            _timeViews.append((sepView, timeView))
            
            sepBounds.origin.x += self.timelineSeperatorWidth
            textBounds.origin.x += self.timelineSeperatorWidth
        }
        
        // Remove the extras
        while _timeViews.count > countNeeded {
            let pair = _timeViews.removeLast()
            pair.0.removeFromSuperview()
            pair.1.removeFromSuperview()
        }
        
        // bring the tracks on top
        for timelineTrackView in _timelineTrackViews {
            self.addSubview(timelineTrackView, positioned: NSWindowOrderingMode.Above, relativeTo: nil)
        }
        
        self.addSubview(playheadView, positioned: NSWindowOrderingMode.Above, relativeTo: nil)
    }
    
    internal var playheadView: NSView! {
        didSet {
            self.addSubview(playheadView)
            playheadView.translatesAutoresizingMaskIntoConstraints = false // this is set to false in IB but it screws up
//             |-0-[purpleBox]-0-|
            let views = ["playheadView": playheadView]
            let horzConstraints = NSLayoutConstraint.constraintsWithVisualFormat("|-0-[playheadView]-0-|", options: [], metrics: nil, views: views)
            self.addConstraints(horzConstraints)
            let vertConstraints = NSLayoutConstraint.constraintsWithVisualFormat("V:|-0-[playheadView]-0-|", options: [], metrics: nil, views: views)
            self.addConstraints(vertConstraints)
        }
    }
    
    override func layout() {
        super.layout()
        _updateTimeViews()
        super.layout() // stupid
    }
    
    
    
}

class CDPlayheadView : NSView {
    
    


    
    
}




































