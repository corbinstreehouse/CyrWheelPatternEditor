//
//  CDTimelineView.swift
//  CyrWheelPatternEditor
//
//  Created by Corbin Dunn on 4/9/16 .
//  Copyright © 2016 Corbin Dunn. All rights reserved.
//

import Cocoa

enum CDTimelineViewChangeReason {
    case playheadTimeDraggingStarted;
    case playheadTimeDraggingEnded;
    case playheadTimePositionMoved;
}

protocol CDTimelineViewDelegate {
    func timelineViewChanged(_ reason: CDTimelineViewChangeReason);
}


class CDTimelineView: NSView {
    // Variables
    let timelineSeperatorWidth: CGFloat = 80.0 // They appear every X pts
    let startingOffset: CGFloat = 10.0 // they start at this offset
    let seperatorWidth: CGFloat = 1.0
    let textStartyingY: CGFloat = 1.0 // A better way??

    var delegate: CDTimelineViewDelegate? = nil
    
    fileprivate func _commonInit() {
        self.layerContentsRedrawPolicy = .onSetNeedsDisplay
        self.appearance = NSAppearance(named: NSAppearanceNameVibrantDark)
    }
    
    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        _commonInit()
    }
    
    fileprivate func _addTimelineTrackView(_ timelineTrackView: CDTimelineTrackView) {
        _timelineTrackViews.append(timelineTrackView)
        timelineTrackView.sideSpacing = self.startingOffset
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        _commonInit()
        // find all the track views already added to us
        for subview in self.subviews {
            if let timelineTrackView = subview as? CDTimelineTrackView {
                _addTimelineTrackView(timelineTrackView)
            }
            if let timecodeBGView = subview as? CDTimecodeBackgroundView {
                _timecodeBackgroundView = timecodeBGView
            }
        }
    }
    
    // Keep track of the track views
    fileprivate var _timelineTrackViews: [CDTimelineTrackView] = []
    fileprivate var _timecodeBackgroundView: CDTimecodeBackgroundView!
    
    override func didAddSubview(_ subview: NSView) {
        super.didAddSubview(subview)
        if let timelineTrackView = subview as? CDTimelineTrackView {
            _addTimelineTrackView(timelineTrackView)
        }
    }
    override func willRemoveSubview(_ subview: NSView) {
        super.willRemoveSubview(subview)
        if let timelineTrackView = subview as? CDTimelineTrackView {
            if let index = _timelineTrackViews.index(of: timelineTrackView) {
                _timelineTrackViews.remove(at: index)
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
                // fill the height and as large as the width
                if requestedSize.width < superBounds.size.width {
                    requestedSize.width = superBounds.size.width
                }
            }
            return requestedSize
        }
    }
    
    fileprivate var _registeredForChanges = false
    fileprivate func _registerForSuperFrameChangesIfNeeded() {
        if let newSuper = self.superview {
            if (!_registeredForChanges) {
                _registeredForChanges = true;
                weak var weakSelf   = self;
                // We want to know when the clip view's size changes (via the scrollview) so we can fill the height by changing our intrinsic size that we have
                NotificationCenter.default.addObserver(forName: NSNotification.Name.NSViewFrameDidChange, object: newSuper, queue: nil, using: { (note: Notification) -> Void in
                    weakSelf?.invalidateIntrinsicContentSize()
                    // All our views also depend on our size (for now!)
                    //                for view in self.views {
                    //                    view.invalidateIntrinsicContentSize()
                    //                }
                })
                // Invalidate us right away too..
                self.invalidateIntrinsicContentSize()
//                self.needsLayout = true
            }
        }
    }
    
    override func viewWillMove(toSuperview newSuperview: NSView?) {
        super.viewWillMove(toSuperview: newSuperview)
        if _registeredForChanges && newSuperview == nil {
            _registeredForChanges = false
            NotificationCenter.default.removeObserver(self, name: NSNotification.Name.NSViewFrameDidChange, object: self.superview!)
        }
    }
    
    // Dynamic width fill:
    override func viewDidMoveToSuperview() {
        super.viewDidMoveToSuperview()
        _registerForSuperFrameChangesIfNeeded()
    }
    
//    override func viewDidMoveToWindow() {
//        super.viewDidMoveToWindow()
//        // I'm not getting viewWillMoveToSuperview since it is setup in the nib (strange..)
//        _registerForSuperFrameChangesIfNeeded()
//    }
    
    
    var widthPerMS: CGFloat = CDTimelineItemView.defaultWidthPerSecond / 1000.0 {
        didSet {
            _removeAllTimeViews()
            self.needsLayout = true
        }
    }
    
    override func setFrameSize(_ newSize: NSSize) {
        super.setFrameSize(newSize)
        self.needsLayout = true;
    }
    
    fileprivate var _timeViews: [(NSView, NSTextField)] = []
    
    func _removeAllTimeViews() {
        for (seperator, textField) in _timeViews {
            seperator.removeFromSuperview()
            textField.removeFromSuperview()
        }
        _timeViews = []
    }
    
    func _makeSeperatorViewWithFrame(_ frame: NSRect) -> NSView {
        let view = CDBorderedView(frame: frame)
        view.backgroundColor = CDThemeColors.timecodeSeparatorColor
        return view
    }
    
    func _makeTimeView(_ frame: NSRect, timeStr: String) -> NSTextField {
        let view = NSTextField(frame: frame)
        view.stringValue = timeStr
        view.font = NSFont.systemFont(ofSize: 10)
        view.drawsBackground = false
        view.backgroundColor = NSColor.clear
        view.isBordered = false
        view.textColor = CDThemeColors.timecodeTextColor
        view.isEditable = false
        return view
    }
    
    override var isFlipped: Bool { return true; }
    
    fileprivate func _timeForWidth(_ width: CGFloat) -> TimeInterval {
        return TimeInterval(width / self.widthPerMS / 1000)
    }
    
    fileprivate func _timeForXOffset(_ offset: CGFloat) -> TimeInterval {
        return _timeForWidth(offset - self.startingOffset)
    }
    
    fileprivate func _widthForTime(_ time: TimeInterval) -> CGFloat {
        // rounding?? how? I guess round is fine..maybe round the time to get it in MS before multiplying by the width?
        return CGFloat(round(time * 1000)) * self.widthPerMS
    }
    
    fileprivate func _offsetForTime(_ time: TimeInterval) -> CGFloat {
        return _widthForTime(time) + self.startingOffset;
    }
    
    
    fileprivate func _stringFromTimeInterval(_ interval: TimeInterval) -> String {
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
        
        let rangeStart = _timeViews.count
        for i in rangeStart ..< rangeStart + countNeeded {
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
        
        // bring the tracks on top, but only if needed, as this is an expensive operation.. bah, this needs to be better as it does a lot of work
        for timelineTrackView in _timelineTrackViews {
            self.addSubview(timelineTrackView, positioned: NSWindowOrderingMode.above, relativeTo: nil)
        }
        
        if let playheadView = self.playheadView {
            if subviews.last != playheadView {
                self.addSubview(playheadView, positioned: NSWindowOrderingMode.above, relativeTo: nil)
            }
        }
    }
    
    fileprivate var _playheadViewPositionConstraint: NSLayoutConstraint?
    
    
    fileprivate func _currentPlayheadViewOffset() -> CGFloat {
        guard let playheadView = playheadView else { return 0; }
        var xOffset = _offsetForTime(self.playheadTimePosition)
        // The thing is centered..so offset by that amount
        xOffset -= playheadView.frame.size.width/2.0
        return xOffset
    }
    
    
    internal var playheadView: CDPlayheadView? {
        didSet {
            guard let playheadView = playheadView else { return }
            self.addSubview(playheadView)
            playheadView.translatesAutoresizingMaskIntoConstraints = false // this is set to false in IB but it screws up
//             |-0-[purpleBox]-0-|
            
            let xOffset = _currentPlayheadViewOffset()
            _playheadViewPositionConstraint = NSLayoutConstraint(item: playheadView, attribute: NSLayoutAttribute.leading, relatedBy: NSLayoutRelation.equal, toItem: self, attribute: NSLayoutAttribute.leading, multiplier: 1.0, constant: xOffset)
            
            let widthConstraint = NSLayoutConstraint(item: playheadView, attribute: .width, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 1.0, constant: playheadView.frame.size.width)
            
//            let horzConstraints = NSLayoutConstraint.constraintsWithVisualFormat("|-0-[playheadView]-0-|", options: [], metrics: nil, views: views)
            self.addConstraints([_playheadViewPositionConstraint!, widthConstraint])
            
            let views = ["playheadView": playheadView]
            let vertConstraints = NSLayoutConstraint.constraints(withVisualFormat: "V:|-0-[playheadView]-0-|", options: [], metrics: nil, views: views)
            self.addConstraints(vertConstraints)
            _updatePlayheadViewPosition()
        }
    }
    
    var playheadTimePosition: TimeInterval = 0 {
        didSet {
            // Don't let it go less than our start
            if playheadTimePosition < 0 {
                self.playheadTimePosition = 0
            }
            _updatePlayheadViewPosition()
        }
        
    }
    
    fileprivate func _updatePlayheadViewPosition() {
        if let c = _playheadViewPositionConstraint {
            c.constant = _currentPlayheadViewOffset()
            self.window?.layoutIfNeeded()
        }
    }

    fileprivate func _timelineViewChanged(_ reason: CDTimelineViewChangeReason) {
        if let delegate = self.delegate {
            delegate.timelineViewChanged(reason)
        }
    }
    
    override func mouseDown(with event: NSEvent) {
        // If we hit the playhead's main view, then track it and move it..
        let timecodePointLocation = event.locationInView(_timecodeBackgroundView)
        if _timecodeBackgroundView.bounds.contains(timecodePointLocation) {
            let startingPoint = event.locationInView(self)
            // If it is already in the playhead, then don't move it
            if !self.playheadView!.hitInsideDragImage(event) {
                // otherwise, move to where clicke
                self.playheadTimePosition = self._timeForXOffset(startingPoint.x)
            }
            
            
            let startingTimePosition = self.playheadTimePosition
            self._timelineViewChanged(.playheadTimeDraggingStarted)
            let maxTimePosition = self._timeForWidth(self.bounds.size.width - self.startingOffset)
            self.window!.trackEvents(matching: [NSEventMask.leftMouseDragged, NSEventMask.leftMouseUp], timeout: NSEventDurationForever, mode: RunLoopMode.eventTrackingRunLoopMode, handler: { (event: NSEvent, stop: UnsafeMutablePointer<ObjCBool>) -> Void in
                let currentPoint = event.locationInView(self)
                let distanceMoved = currentPoint.x - startingPoint.x
                let timeForDistanceMoved = self._timeForWidth(distanceMoved)
                var newTimePosition = startingTimePosition + timeForDistanceMoved
                if (newTimePosition < 0) {
                    newTimePosition = 0;
                } else if (newTimePosition > maxTimePosition) {
                    newTimePosition = maxTimePosition;
                }
                self.playheadTimePosition = newTimePosition;
                self._timelineViewChanged(.playheadTimePositionMoved)
                if event.type == NSEventType.leftMouseUp {
                    stop.pointee = true
                    self._timelineViewChanged(.playheadTimeDraggingEnded)
                }
            })
        }
        
        
    }
    
    override func layout() {
        super.layout()
        _updateTimeViews()
        super.layout() // stupid
    }
    
    
    
}

class CDPlayheadView : NSView {
    
    @IBOutlet weak var _playheadImageView: NSImageView!
    
    func hitInsideDragImage(_ event: NSEvent) -> Bool {
        // Yes if we hit our triangle view
        let point = event.locationInView(_playheadImageView)
        return _playheadImageView.bounds.contains(point)
    }


    
    
}




































