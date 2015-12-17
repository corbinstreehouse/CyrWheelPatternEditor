// by corbin dunn, (c)2014

#include "FatFile.h"
#include <Foundation/Foundation.h>
#include "CWPatternSequenceManager.h" / for MAX_PATH

boolean SdFat::begin(uint8_t csPin, uint8_t speed) {
    return true;
}



FatFile::FatFile(const char *filepath, uint8_t oflag) : m_dirIndex(0), _urls(nil), m_curPosition(0), _data(nil) {
    if (filepath) {
        NSString *filePathString = [NSString stringWithCString:filepath encoding:NSASCIIStringEncoding];
        m_url = [NSURL fileURLWithPath:filePathString];
    } else {
        m_url = nil;
    }
}

FatFile::~FatFile() {
    m_url = nil;
    NSCAssert(_data == nil, @"file should have been closed");
    _data = nil;
    _urls = nil;
}

bool FatFile::openRoot(FatVolume* vol) {
    m_url = vol->getBaseURL();
    return m_url != nil;
}

NSURL *FatFile::getURL() {
    return m_url;
}

bool FatFile::open(FatFileSystem* fs, const char* path, uint8_t oflag) {
    NSString *filePathString = [NSString stringWithCString:path encoding:NSASCIIStringEncoding];
    if ([[NSFileManager defaultManager] fileExistsAtPath:filePathString]) {
        // complete path
        m_url = [NSURL fileURLWithPath:filePathString];
        return true;
    } else {
        NSURL *baseURL = nil;
        if (fs) {
            baseURL = fs->getBaseURL();
        }
        if (baseURL == nil) {
            baseURL = m_url;
        }
        // relative path?
        NSURL *newURL = [baseURL URLByAppendingPathComponent:filePathString];
        if (newURL && [newURL checkResourceIsReachableAndReturnError:NULL]) {
            m_url = newURL;
            return true;
        }
        return false;
    }
}

void FatFile::ensureChildrenAreLoaded() {
    if  (_urls == nil) {
        NSURL *directoryURL = getURL();
        NSCAssert(directoryURL != nil, @"need a URL");
        _urls = [[NSFileManager defaultManager] contentsOfDirectoryAtURL:directoryURL includingPropertiesForKeys:nil options:0 error:NULL];
        m_childURLIndex = -1; // always index in nextChildURL
    }
}

NSURL *FatFile::nextChildURL() {
    if (_urls == nil) {
        ensureChildrenAreLoaded();
    }
    m_childURLIndex++;
    if (m_childURLIndex < _urls.count) {
        return _urls[m_childURLIndex];
    }
    return nil;
}

// NOTE: I need to keep the parent open for this to work...so I might have to move to that model, or tightly control the tmp dir
NSURL *FatFile::childURLAtIndex(int index) {
    ensureChildrenAreLoaded();
    if (index >= 0 && index < _urls.count) {
        return _urls[index];
    } else {
        return nil; // out of bounds...but might be "expected" if the file disappeared..
    }
}

bool FatFile::open(FatFile* dirFile, uint16_t index, uint8_t oflag) {
    NSCAssert(dirFile != nil, @"need a parent directory");
    m_url = dirFile->childURLAtIndex(index);
    return m_url != nil;
}

bool FatFile::open(FatFile* dirFile, const char* path, uint8_t oflag) {
    NSString *filePathString = [NSString stringWithCString:path encoding:NSASCIIStringEncoding];
    if ([[NSFileManager defaultManager] fileExistsAtPath:filePathString]) {
        // complete path
        m_url = [NSURL fileURLWithPath:filePathString];
        return true;
    } else {
        NSURL *baseURL = nil;
        if (dirFile) {
            baseURL = dirFile->getURL();
        }
        if (baseURL == nil) {
            baseURL = m_url;
        }
        // relative path?
        NSURL *newURL = [baseURL URLByAppendingPathComponent:filePathString];
        if (newURL && [newURL checkResourceIsReachableAndReturnError:NULL]) {
            m_url = newURL;
            return true;
        }
        return false;
    }
}

bool FatFile::getSFN(char* name) {
    // So, we assume a large buffer (MAX_PATH)
    if (m_url) {
        NSString *filename = [m_url lastPathComponent];
        strlcpy(name, filename.UTF8String, MAX_PATH);
        return true;
    }
    return false;
}

size_t FatFile::printName() {
    if (m_url) {
        NSString *filename = [m_url lastPathComponent];
        Serial.printf("%s", filename.UTF8String);
        return filename.length;
    }
    return 0;
}

bool FatFile::openNext(FatFile *dirFile, uint8_t oflag) {
    NSCAssert(dirFile != nil, @"error with directory file");
    m_url = dirFile->nextChildURL();
    m_dirIndex = dirFile->currentChildURLIndex();
    return m_url != nil;
}

int FatFile::available() {
    if (_data == nil) {
        _data = [[NSData alloc] initWithContentsOfURL:getURL()];
        NSCAssert(_data != nil, @"should have created data");
        m_curPosition = 0;
    }
    return (int)(_data.length - m_curPosition);
}

size_t FatFile::read(char *buffer, size_t length)
{
    available();
    // basic hack checks
    if ((m_curPosition + length) <= _data.length) {
        memcpy(buffer, &((char*)_data.bytes)[m_curPosition], length);
        m_curPosition += length;
        return length;
    } else {
        NSCAssert(NO, @"reading error");
        return 0;
    }
}

boolean FatFile::seekSet(uint32_t pos) {
    available();
    m_curPosition = pos;
    NSCAssert(m_curPosition >= 0 && m_curPosition <= _data.length, @"seek error");
    return true;
}

void FatFile::close() {
    _data = nil;
    _urls = nil; // drops the children
}

bool FatFile::getName(char *name, size_t size) {
    NSURL *u = getURL();
    if (u) {
        NSString *filename = u.lastPathComponent;
        if (filename && filename.UTF8String) {
            NSCAssert(filename.length < size, @"buffer overflow");
            strlcpy(name, filename.UTF8String, size);
            return true;
        }
    }
    return false;
}


