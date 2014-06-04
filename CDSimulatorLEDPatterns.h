//
//  CDSimulatorLEDPatterns.h
//  CyrWheelPatternEditor
//
//  Created by corbin dunn on 6/1/14.
//  Copyright (c) 2014 Corbin Dunn. All rights reserved.
//

#ifndef __CyrWheelPatternEditor__CDSimulatorLEDPatterns__
#define __CyrWheelPatternEditor__CDSimulatorLEDPatterns__

#include "LEDPatterns.h"
#import "CDCyrWheelView.h"


class CDSimulatorLEDPatterns : public LEDPatterns {
private:
    CDCyrWheelView *m_cyrWheelView;
protected:
    virtual void internalShow();
public:
    virtual void setBrightness(uint8_t brightness) { /* ignored */ }
    uint8_t getBrightness() { return 128; };
    
    CDSimulatorLEDPatterns(uint32_t ledCount) : LEDPatterns(ledCount) {
        
    }
    
    virtual void begin() { };
    
    void setCyrWheelView(CDCyrWheelView *view) {
        m_cyrWheelView = view;
        m_cyrWheelView.numberOfLEDs = getLEDCount();
    };
    

};


#endif /* defined(__CyrWheelPatternEditor__CDSimulatorLEDPatterns__) */
