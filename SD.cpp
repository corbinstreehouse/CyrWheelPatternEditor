
#include "SD.h"


boolean SDClass::begin(uint8_t speed, uint8_t csPin) {
    return true;
}

boolean SDClass::remove(char *filepath) {
    return true;
}


File SDClass::open(const char *filepath, uint8_t mode) {
    File result = File(filepath);
    return result;
}


File::File(const char *filepath) {
    size_t filepathLength = strlen(filepath);
    if (filepathLength > 0) {
        _filepath = (char*)malloc(sizeof(char*) * filepathLength + 1);
        strcpy(_filepath, filepath);
    } else {
        _filepath = NULL;
    }
}

File::~File() {
    if (_filepath) {
        free(_filepath);
    }
}

NSURL *File::getURL() {
    NSCAssert(_filepath != NULL, @"need a filepath");
    NSString *filePathString = [NSString stringWithCString:_filepath encoding:NSASCIIStringEncoding];
//    pathToAppend = [pathToAppend lastPathComponent];
    NSURL *directoryURL = [NSURL fileURLWithPath:filePathString];
    return directoryURL;
}

bool File::getNextFilename(char *buffer) {
    if  (_urls == nil) {
        NSURL *directoryURL = getURL();
        _urls = [[NSFileManager defaultManager] contentsOfDirectoryAtURL:directoryURL includingPropertiesForKeys:nil options:0 error:NULL];
        _index = 0;
    }
    if (_index < _urls.count) {
        NSURL *result = [_urls  objectAtIndex:_index];
        NSString *resStr = [[result path] lastPathComponent];
        NSUInteger realLength;
        [resStr getBytes:buffer maxLength:MAX_COMPONENT_LEN-1 usedLength:&realLength encoding:NSASCIIStringEncoding options:NSStringEncodingConversionAllowLossy range:NSMakeRange(0, resStr.length) remainingRange:NULL];
        buffer[realLength] = NULL;
        
        _index++;
        return true;
    }

    return false;
}

void File::moveToStartOfDirectory() {
    _index = 0;
    _offset = 0;
    _data = nil;
}

SDClass SD;

int File::available() {
    if (_data == nil) {
        _data = [[NSData alloc] initWithContentsOfURL:getURL()];
        NSCAssert(_data != nil, @"should have created data");
        _offset = 0;
    }
    return (int)(_data.length - _offset);
}

char *File::name() {
    return _filepath;
}

size_t File::readBytes(char *buffer, size_t length)
{
    available();
    // basic hack checks
    if ((_offset + length) <= _data.length) {
        memcpy(buffer, &((char*)_data.bytes)[_offset], length);
        _offset += length;
        return length;
    } else {
        NSCAssert(NO, @"reading error");
        return 0;
    }
}

boolean File::seek(uint32_t pos) {
    available();
    _offset = pos;
    NSCAssert(_offset >= 0 && _offset <= _data.length, @"seek error");
    return true;
}

uint32_t File::position() {
    return (uint32_t)_offset;
}


void File::close() {
    _data = nil;
}
