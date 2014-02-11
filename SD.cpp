
#include "SD.h"


boolean SDClass::begin(uint8_t csPin) {
    return true;
}


File SDClass::open(const char *filepath, uint8_t mode) {
    File result = File(filepath);
    return result;
}


static NSURL *g_baseDirectoryURL = nil;

void SDSetBaseDirectoryURL(NSURL *url) {
    g_baseDirectoryURL = url;
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
    NSString *pathToAppend = [NSString stringWithCString:_filepath encoding:NSASCIIStringEncoding];
    NSURL *directoryURL = [g_baseDirectoryURL URLByAppendingPathComponent:pathToAppend];
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
}

SDClass SD;


size_t File::readBytes(char *buffer, size_t length)
{
    if (_data == nil) {
        _data = [[NSData alloc] initWithContentsOfURL:getURL()];
        _offset = 0;
    }
    // basic hack checks
    if ((_offset + length) < _data.length) {
        memcpy(buffer, &((char*)_data.bytes)[_offset], length);
        return length;
    } else {
        return 0;
    }
}

void File::close() {
    _data = nil;
}
