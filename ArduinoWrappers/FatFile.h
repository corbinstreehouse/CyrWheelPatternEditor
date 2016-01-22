#ifndef FatFile_h
#define FatFile_h

#include "Arduino.h"
#include "FatApiConstants.h"

@class NSURL;

/** Set SCK to max rate of F_CPU/2. */
uint8_t const SPI_FULL_SPEED = 2;
/** Set SCK rate to F_CPU/3 for Due */
uint8_t const SPI_DIV3_SPEED = 3;
/** Set SCK rate to F_CPU/4. */
uint8_t const SPI_HALF_SPEED = 4;
/** Set SCK rate to F_CPU/6 for Due */
uint8_t const SPI_DIV6_SPEED = 6;
/** Set SCK rate to F_CPU/8. */
uint8_t const SPI_QUARTER_SPEED = 8;
/** Set SCK rate to F_CPU/16. */
uint8_t const SPI_EIGHTH_SPEED = 16;
/** Set SCK rate to F_CPU/32. */
uint8_t const SPI_SIXTEENTH_SPEED = 32;

class FatVolume;
class FatFileSystem;

// A wrapper around the SdFat, etc. Pure quick hacks


class FatFile  {
private:
    NSArray *_urls;
    int m_childURLIndex;
    NSData *_data;
    uint32_t m_curPosition;
    NSURL *m_url;
    NSURL *getURL();
    uint16_t m_dirIndex;         // index of directory entry in dir file
    
    bool urlHasBoolProperty(NSString *property) {
        NSURL *directoryURL = getURL();
        NSNumber *value = nil;
        NSError *error = nil;
        if ([directoryURL getResourceValue:&value forKey:property error:&error]) {
            return [value boolValue];
        } else {
            return false;
        }
    }
    

    void ensureChildrenAreLoaded();
    NSURL *childURLAtIndex(int index);
    NSURL *nextChildURL();
    int currentChildURLIndex() { return m_childURLIndex; };
    
public:
    FatFile(const char *filepath, uint8_t oflag);
    FatFile() : FatFile(NULL, 0) { }
    ~FatFile();
    
    void setData(NSData *data) { _data = data; } // Allows me to do file operations "in memory"
    
    size_t read(char *buffer, size_t length);

    int available();
    uint32_t curPosition() const {
         return m_curPosition;
    }
    
    void close();
    
    bool isDir() {
        return urlHasBoolProperty(NSURLIsDirectoryKey);
    }
    bool isFile() {
        NSURL *u = getURL();
        if (u && [u checkResourceIsReachableAndReturnError:NULL]) {
            return true;
        } else {
            return false;
        }
    }
    bool isHidden() {
        return urlHasBoolProperty(NSURLIsHiddenKey);
    }
    
    bool seekSet(uint32_t pos);
    
    bool seekCur(int32_t offset) {
        return seekSet((uint32_t)m_curPosition + offset);
    }
    bool isOpen() {
        return _data != nil;
    }
    bool getName(char* name, size_t size);
    
    bool openRoot(FatVolume* vol);

    bool open(FatFileSystem* fs, const char* path, uint8_t oflag);
    bool open(FatFile* dirFile, uint16_t index, uint8_t oflag);
    bool open(FatFile* dirFile, const char* path, uint8_t oflag);

    bool getSFN(char* name);
    size_t printName();
    
    bool exists(const char* path) {
        FatFile file;
        return file.open(this, path, O_READ);
    }

    bool openNext(FatFile* dirFile, uint8_t oflag = O_READ);

    // Only valid after an openNext...
    uint16_t dirIndex() {
        return m_dirIndex;
    }
};

class SdFile: public FatFile {
public:
    SdFile(const char *filepath, uint8_t oflag) : FatFile(filepath, oflag) { }
    SdFile() : FatFile(NULL, 0) {  }
};


class FatVolume {
private:
    NSURL *m_baseURL;
public:
    void setBaseURL(NSURL *url) { m_baseURL = url; }
    NSURL *getBaseURL() { return m_baseURL; }

    ~FatVolume() { m_baseURL = nil; } // ARC cleanup
};

class FatFileSystem : public  FatVolume {

};

class SdFat : public FatFileSystem {
private:
    FatFile m_vwd;
public:
    // This needs to be called to set up the connection to the SD card
    // before other methods are used.
    boolean begin(uint8_t csPin, uint8_t speed);
    
    bool chdir(bool set_cwd = false) {
        vwd()->close();
        return vwd()->openRoot(this);
//        return vwd()->openRoot(this) && (set_cwd ? FatFile::setCwd(vwd()) : true);
    }
    
    FatFile* vwd() {
        return &m_vwd;
    }
    // Open the specified file/directory with the supplied mode (e.g. read or
    // write, etc). Returns a File object for interacting with the file.
    // Note that currently only one file can be open at a time.
//    File open(const char *filename, uint8_t mode = FILE_READ);
    
    bool exists(const char* path) {
        return vwd()->exists(path);
    }
//
//    // Create the requested directory heirarchy--if intermediate directories
//    // do not exist they will be created.
//    boolean mkdir(char *filepath);
//    
//    // Delete the file.
//    boolean remove(char *filepath);
//
//    boolean rmdir(char *filepath);
};

#endif
