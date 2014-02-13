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
    void println() { NSLog(@""); }
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


extern volatile uint32_t systick_millis_count;
extern uint32_t millis();
extern int analogRead(uint8_t pin);

#define random randomX
uint32_t random(void);
uint32_t random(uint32_t howbig);
int32_t random(int32_t howsmall, int32_t howbig);

void randomSeed(uint32_t newseed);
void yield();
 uint32_t micros();
long map(long x, long in_min, long in_max, long out_min, long out_max);

bool mainProcess();

#endif

