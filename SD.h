#ifndef __SD_H__
#define __SD_H__

#include "Arduino.h"


uint8_t const O_READ = 0X01;
/** open() oflag - same as O_READ */
//uint8_t const O_RDONLY = O_READ;
/** open() oflag for write */
uint8_t const O_WRITE = 0X02;
/** open() oflag - same as O_WRITE */
//uint8_t const O_WRONLY = O_WRITE;


#define FILE_READ  O_READ
#define FILE_WRITE (O_READ | O_WRITE | O_CREAT)

#define MAX_COMPONENT_LEN 128 // Cuz that's what old-school DOS likes. We should make this work with FAT32 long file names..
#define PATH_COMPONENT_BUFFER_LEN MAX_COMPONENT_LEN+1

class File/* : public Stream*/ {
private:
    NSArray *_urls;
    NSURL *_url;
    NSInteger _index;
    NSData *_data;
    char *_filepath;
    NSInteger _offset;
    
    NSURL *getURL();
public:
    File(const char *filepath);
    ~File();
    
    size_t readBytes(char *buffer, size_t length);

//    virtual size_t write(uint8_t);
//    virtual size_t write(const uint8_t *buf, size_t size);
//    virtual int read();
//    virtual int peek();
    int available();
//    virtual void flush();
//    int read(void *buf, uint16_t nbyte);
    boolean seek(uint32_t pos);
    uint32_t position();
//    uint32_t size();
    void close();
//    operator bool();
    char *name();
//    
//    boolean isDirectory(void);
//    File openNextFile(uint8_t mode = O_RDONLY);
//    
//    // Pass a buffer of PATH_COMPONENT_BUFFER_LEN size
    bool getNextFilename(char *buffer);

    void moveToStartOfDirectory();
};

class SDClass {
public:
    // This needs to be called to set up the connection to the SD card
    // before other methods are used.
    boolean begin(uint8_t csPin);
    
    // Open the specified file/directory with the supplied mode (e.g. read or
    // write, etc). Returns a File object for interacting with the file.
    // Note that currently only one file can be open at a time.
    File open(const char *filename, uint8_t mode = FILE_READ);
    
//    // Methods to determine if the requested file path exists.
//    boolean exists(char *filepath);
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

extern SDClass SD;


extern void SDSetBaseDirectoryURL(NSURL *url);
#endif
