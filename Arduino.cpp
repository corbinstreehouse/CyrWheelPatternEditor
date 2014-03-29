//
//  Arduino.cpp
//  CyrWheelPatternEditor
//
//  Created by corbin dunn on 2/5/14.
//  Copyright (c) 2014 Corbin Dunn. All rights reserved.
//

#include "Arduino.h"


Print Serial;

volatile uint32_t systick_millis_count;

uint32_t millis() {
    NSTimeInterval now = [NSDate timeIntervalSinceReferenceDate];
    now *= 1000; // milliseconds
    uint32_t resAsInt = now; // trunc(now);
    return resAsInt;
}

uint32_t micros() {
    NSTimeInterval now = [NSDate timeIntervalSinceReferenceDate];
    now *= (1000000); // milliseconds
    uint32_t resAsInt = now; // trunc(now);
    return resAsInt;
}

void yield() {
   // [[NSRunLoop currentRunLoop] runMode:NSDefaultRunLoopMode beforeDate:[NSDate date]];

    NSEvent *e = [NSApp nextEventMatchingMask:NSAnyEventMask untilDate:[NSDate date] inMode:(NSString *)kCFRunLoopDefaultMode dequeue:YES];
    if (e) {
        [NSApp sendEvent:e];
    }

}

int analogRead(uint8_t pin) {
    return 0;
}


static uint32_t seed;

void randomSeed(uint32_t newseed)
{
	if (newseed > 0) seed = newseed;
}

void srandom(uint32_t newseed)
{
	seed = newseed;
}

uint32_t random(void)
{
	int32_t hi, lo, x;
    
	// the algorithm used in avr-libc 1.6.4
	x = seed;
	if (x == 0) x = 123459876;
	hi = x / 127773;
	lo = x % 127773;
	x = 16807 * lo - 2836 * hi;
	if (x < 0) x += 0x7FFFFFFF;
	seed = x;
	return x;
}

uint32_t random(uint32_t howbig)
{
	if (howbig == 0) return 0;
	return random() % howbig;
}

int32_t random(int32_t howsmall, int32_t howbig)
{
	if (howsmall >= howbig) return howsmall;
	int32_t diff = howbig - howsmall;
	return random(diff) + howsmall;
}


long map(long x, long in_min, long in_max, long out_min, long out_max)
{
	return (x - in_min) * (out_max - out_min) / (in_max - in_min) + out_min;
}


bool mainProcess() {
    yield(); // process events..
    return false;
}
void delay(int i) {
    
}

void busyDelay(unsigned int i) {

}