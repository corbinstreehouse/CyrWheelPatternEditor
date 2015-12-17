#ifndef EEPROM_h
#define EEPROM_h

#include <inttypes.h>
struct EEPROMClass{
    //Basic user access methods.
//    EERef operator[]( const int idx )    { return idx; }
//    uint8_t read( int idx )              { return EERef( idx ); }
    void write( int idx, uint8_t val )   {  }
//    void update( int idx, uint8_t val )  { EERef( idx ).update( val ); }

    //STL and C++11 iteration capability.
//    EEPtr begin()                        { return 0x00; }
//    EEPtr end()                          { return length(); } //Standards requires this to be the item after the last valid entry. The returned pointer is invalid.
//    uint16_t length()                    { return E2END + 1; }

    //Functionality to 'get' and 'put' objects to and from EEPROM.
    template< typename T > T &get( int idx, T &t ){
//        EEPtr e = idx;
//        uint8_t *ptr = (uint8_t*) &t;
//        for( int count = sizeof(T) ; count ; --count, ++e )  *ptr++ = *e;
        return t;
    }

    template< typename T > const T &put( int idx, const T &t ){
//        EEPtr e = idx;
//        const uint8_t *ptr = (const uint8_t*) &t;
//        for( int count = sizeof(T) ; count ; --count, ++e )  (*e).update( *ptr++ );
//        return t;
        return t;
    }
};

static EEPROMClass EEPROM;
#endif
