#ifndef __GRRRRR_H__
#define __GRRRRR_H__
//
//  Arduino.h
//  CyrWheelPatternEditor
//
//  Created by corbin dunn on 2/5/14.
//  Copyright (c) 2014 Corbin Dunn. All rights reserved.
//

#import <Foundation/Foundation.h>
//#import <Cocoa/Cocoa.h>

#define SS 0

class Print {
public:
    void print(int i) { NSLog(@"%ld", (long)i); };
    void print(const char *s) { NSLog(@"%s", s); };
    void println(const char *s) { NSLog(@"%s", s); };
	void printf(const char *format, ...) {
       // NSString *s = [NSString stringWithFormat:@"%s", format];
//        va_start(ap, param);
//        NSLog(s, va_list);
//        va_end(ap);
//        NSLog(s);
    }
};

extern Print Serial;

#define pinMode(a, b)
#define OUTPUT 0
typedef bool boolean;



#endif