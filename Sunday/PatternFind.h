//
//  PatternFind.h
//  Sunday
//
//  Created by 丘远冲 on 2023/10/30.
//

#ifndef PatternFind_h
#define PatternFind_h


#import <Foundation/Foundation.h>
#import <mach-o/dyld.h>
#import <mach-o/getsect.h>
#import <mach-o/ldsyms.h>
#import <mach-o/loader.h>
#import <mach/mach_vm.h>
#import <objc/message.h>
#import <objc/runtime.h>
#include <libkern/OSCacheControl.h>
#include <dlfcn.h>
#include <string.h>
#include <stdio.h>
#include <stdlib.h>
#include <math.h>
#include <signal.h>
#include <unistd.h>
#include <string>
#include <vector>
#include <cstdint>
#include <iostream>
#include <sstream>
#include <iomanip>
#include <codecvt>

#define  Sunday_int64 uint64_t

void* emalloc(size_t size, const char* reason = "emalloc:???");
void efree(void* ptr, const char* reason = "efree:???");

template<typename T>
class Memory
{
public:
    //
    // This class guarantees that the returned allocated memory
    // will always be zeroed
    //
    explicit Memory(const char* Reason = "Memory:???")
    {
        m_Ptr = nullptr;
        m_Size = 0;
        m_Reason = Reason;
    }

    explicit Memory(size_t Size, const char* Reason = "Memory:???")
    {
        m_Ptr = reinterpret_cast<T>(emalloc(Size));
        m_Size = Size;
        m_Reason = Reason;

        memset(m_Ptr, 0, Size);
    }

    ~Memory()
    {
        if (m_Ptr)
            efree(m_Ptr);
    }

    T operator()()
    {
        return m_Ptr;
    }

private:
    T           m_Ptr;
    size_t      m_Size;
    const char* m_Reason;
};



//@interface PatternFind: NSObject

struct PatternByte
{
    struct PatternNibble
    {
        unsigned char data;
        bool wildcard;
    } nibble[2];
};



void trim(char* lpStr);

//returns: offset to data when found, -1 when not found
size_t patternfind(
    const unsigned char* data, //data
    size_t datasize, //size of data
    const char* pattern, //pattern to search
    int* patternsize = 0 //outputs the number of bytes the pattern is
);

//returns: offset to data when found, -1 when not found
size_t patternfind(
    const unsigned char* data, //data
    size_t datasize, //size of data
    unsigned char* pattern, //bytes to search
    size_t patternsize //size of bytes to search
);

//returns: nothing
void patternwrite(
    unsigned char* data, //data
    size_t datasize, //size of data
    const char* pattern //pattern to write
);

//returns: true on success, false on failure
bool patternsnr(
    unsigned char* data, //data
    size_t datasize, //size of data
    const char* searchpattern, //pattern to search
    const char* replacepattern //pattern to write
);

//returns: true on success, false on failure
bool patterntransform(const std::string & patterntext, //pattern string
    std::vector<PatternByte> & pattern //pattern to feed to patternfind
);

//returns: offset to data when found, -1 when not found
size_t patternfind(
    const unsigned char* data, //data
    size_t datasize, //size of data
    const std::vector<PatternByte> & pattern //pattern to search
);

int strtohex(char *lpStr, unsigned char *cbuf, int len);

bool Patch_Code(void* patch_addr, uint8_t* patch_data, int patch_data_size);

std::vector <Sunday_int64> X64dbgSundayFind(char* Value, Sunday_int64 Start = 0, Sunday_int64 End = 0 , size_t maxFind = 0);//private: 注意，永远不要手动调用下面的函数

//@end

#endif /* PatternFind_h */
