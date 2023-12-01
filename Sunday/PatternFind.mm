//
//  PatternFind.m
//  Sunday
//
//  Created by qyc on 2023/10/30.
//

#import <Foundation/Foundation.h>
#import "PatternFind.h"

static inline bool isHex(char ch)
{
    return (ch >= '0' && ch <= '9') || (ch >= 'A' && ch <= 'F') || (ch >= 'a' && ch <= 'f');
}

static inline std::string formathexpattern(const std::string & patterntext)
{
    std::string result;
    int len = (int)patterntext.length();
    for(int i = 0; i < len; i++)
        if(patterntext[i] == '?' || isHex(patterntext[i]))
            result += patterntext[i];
    return result;
}

static inline int hexchtoint(char ch)
{
    if(ch >= '0' && ch <= '9')
        return ch - '0';
    else if(ch >= 'A' && ch <= 'F')
        return ch - 'A' + 10;
    else if(ch >= 'a' && ch <= 'f')
        return ch - 'a' + 10;
    return -1;
}

bool patterntransform(const std::string & patterntext, std::vector<PatternByte> & pattern)
{
    pattern.clear();
    std::string formattext = formathexpattern(patterntext);
    int len = (int)formattext.length();
    if(!len)
        return false;

    if(len % 2) //not a multiple of 2
    {
        formattext += '?';
        len++;
    }

    /*PatternByte newByte;*/
    PatternByte newByte = {};
    for(int i = 0, j = 0; i < len; i++)
    {
        if(formattext[i] == '?') //wildcard
        {
            newByte.nibble[j].wildcard = true; //match anything
        }
        else //hex
        {
            newByte.nibble[j].wildcard = false;
            newByte.nibble[j].data = hexchtoint(formattext[i]) & 0xF;
        }

        j++;
        if(j == 2) //two nibbles = one byte
        {
            j = 0;
            pattern.push_back(newByte);
        }
    }
    return true;
}

static inline bool patternmatchbyte(unsigned char byte, const PatternByte & pbyte)
{
    int matched = 0;

    unsigned char n1 = (byte >> 4) & 0xF;
    if(pbyte.nibble[0].wildcard)
        matched++;
    else if(pbyte.nibble[0].data == n1)
        matched++;

    unsigned char n2 = byte & 0xF;
    if(pbyte.nibble[1].wildcard)
        matched++;
    else if(pbyte.nibble[1].data == n2)
        matched++;

    return (matched == 2);
}

size_t patternfind(const unsigned char* data, size_t datasize, unsigned char* pattern, size_t patternsize)
{
    if(patternsize > datasize)
        patternsize = datasize;
    for(size_t i = 0, pos = 0; i < datasize; i++)
    {
        if(data[i] == pattern[pos])
        {
            pos++;
            if(pos == patternsize)
                return i - patternsize + 1;
        }
        else if(pos > 0)
        {
            i -= pos;
            pos = 0; //reset current pattern position
        }
    }
    return -1;
}

static inline void patternwritebyte(unsigned char* byte, const PatternByte & pbyte)
{
    unsigned char n1 = (*byte >> 4) & 0xF;
    unsigned char n2 = *byte & 0xF;
    if(!pbyte.nibble[0].wildcard)
        n1 = pbyte.nibble[0].data;
    if(!pbyte.nibble[1].wildcard)
        n2 = pbyte.nibble[1].data;
    *byte = ((n1 << 4) & 0xF0) | (n2 & 0xF);
}

void patternwrite(unsigned char* data, size_t datasize, const char* pattern)
{
    std::vector<PatternByte> writepattern;
    std::string patterntext(pattern);
    if(!patterntransform(patterntext, writepattern))
        return;
    size_t writepatternsize = writepattern.size();
    if(writepatternsize > datasize)
        writepatternsize = datasize;
    for(size_t i = 0; i < writepatternsize; i++)
        patternwritebyte(&data[i], writepattern.at(i));
}

bool patternsnr(unsigned char* data, size_t datasize, const char* searchpattern, const char* replacepattern)
{
    size_t found = patternfind(data, datasize, searchpattern);
    if(found == -1)
        return false;
    patternwrite(data + found, datasize - found, replacepattern);
    return true;
}

size_t patternfind(const unsigned char* data, size_t datasize, const char* pattern, int* patternsize)
{
    std::string patterntext(pattern);
    std::vector<PatternByte> searchpattern;
    if (!patterntransform(patterntext, searchpattern))
        return -1;
    return patternfind(data, datasize, searchpattern);
}

size_t patternfind(const unsigned char* data, size_t datasize, const std::vector<PatternByte> & pattern)
{
    size_t searchpatternsize = pattern.size();
    for(size_t i = 0, pos = 0; i < datasize; i++)  //search for the pattern
    {
        if(patternmatchbyte(data[i], pattern.at(pos)))  //check if our pattern matches the current byte
        {
            pos++;
            if(pos == searchpatternsize)  //everything matched
                return i - searchpatternsize + 1;
        }
        else if(pos > 0)  //fix by Computer_Angel
        {
            i -= pos;
            pos = 0; //reset current pattern position
        }
    }
    return -1;
}

static int emalloc_count = 0;

void* emalloc(size_t size, const char* reason)
{
    unsigned char* a = (unsigned char*)malloc(size);
    if (!a)
    {
        printf("Error：Could not allocate memory\n");
        return 0;
    }
    memset(a, 0, size);
    emalloc_count++;
    /*
    FILE* file = fopen(alloctrace, "a+");
    fprintf(file, "DBG%.5d:  alloc:" fhex ":%s:" fhex "\n", emalloc_count, a, reason, size);
    fclose(file);
    */
    return a;
}

void efree(void* ptr, const char* reason)
{
    emalloc_count--;
    /*
    FILE* file = fopen(alloctrace, "a+");
    fprintf(file, "DBG%.5d:   free:" fhex ":%s\n", emalloc_count, ptr, reason);
    fclose(file);
    */
    //GlobalFree(ptr);
    free(ptr);
}

char* convertStringToHex(char* value)
{
    if (isHex(value[0])) {
        // 如果输入值已经是十六进制，则直接返回
        return value;
    }
    else {
        // 将非十六进制字符串转换为十六进制
        std::stringstream hexStream;
        hexStream << std::hex << std::setfill('0');
        for (int i = 0; value[i] != '\0'; ++i) {
            hexStream << std::setw(2) << static_cast<int>(value[i]);
        }
        std::string hexCode = hexStream.str();
        char* result = new char[hexCode.length() + 1];
        std::strcpy(result, hexCode.c_str());
        return result;
    }
}

//新的
std::vector <Sunday_int64> X64dbgSundayFind(char* Value, Sunday_int64 Start, Sunday_int64 End, size_t maxFind)
{
    std::vector <Sunday_int64> SaveArray;
    Sunday_int64 SegmentSize = 0;
    
    char* converted = convertStringToHex(Value);
    
    trim(converted);//去除空格
    size_t dx = strlen(converted);//获取去除空格后字符数
    if (dx % 2 == 0){//判断奇偶数
        if (End != 0 || Start != 0 || Start > End){
            SegmentSize = End - Start ;//计算区段大小
            Memory<unsigned char*> data(SegmentSize);//申请内存空间
            memcpy(reinterpret_cast<void*>(data()), reinterpret_cast<void*>(Start), SegmentSize);
            size_t foundOffset = 0;
            size_t foundCount = static_cast<size_t>(SaveArray.size());
            size_t i = 0;
            while (true) {
                foundOffset = static_cast<size_t>(patternfind(data() + i, SegmentSize - i, converted));
                if (foundOffset == -1)
                    break;

                i += foundOffset + 1;
                size_t foundIndex = static_cast<size_t>(Start + i - 1);
                SaveArray.push_back(foundIndex);
                foundCount++;

                if (maxFind > 0 && foundCount >= maxFind)
                    break;
            }
        }
    }
    return SaveArray;
}


/************************************************************************/
/* 函数名称: trim                                                       */
/* 函数功能: 删除空格--指针操作                                            */
/* 输入参数: lpStr 字符串指针                                            */
/* 输出参数: 0成功 -1失败                                                */
/* 函数作者: 飘云/P.Y.G  http://www.chinapyg.com                        */
/* 编写时间: 2014-11-02                                                 */
/************************************************************************/
void trim(char * lpStr)
{
    char *p1, *p2;
    p1 = p2 = lpStr;  // 初值
    while (*p2)
    {
        if (*p2 != ' ')
            *p1++ = *p2++;
        else
            p2++; // 跳过空格
    }
    *p1 = '\0'; // 补上结束符
    //return p;
}

/************************************************************************/
/* 函数名称: str_to_hex                                                 */
/* 函数功能: 字符串转换为十六进制                                        */
/* 输入参数: lpStr 字符串指针 cbuf 十六进制 len 字符串的长度            */
/* 输出参数: 0成功 -1失败                                                */
/* 函数作者: 飘云/P.Y.G  http://www.chinapyg.com                        */
/* 编写时间: 2014-11-02                                                 */
/************************************************************************/
int strtohex(char *lpStr, unsigned char *cbuf, int len)
{
    Byte high, low;
    int idx, ii=0;
    for (idx=0; idx<len; idx+=2)
    {
        high = lpStr[idx];
        low = lpStr[idx+1];
        
        if(high>='0' && high<='9')
            high = high-'0';
        else if(high>='A' && high<='F')
            high = high - 'A' + 10;
        else if(high>='a' && high<='f')
            high = high - 'a' + 10;
        else
            return -1;
        
        if(low>='0' && low<='9')
            low = low-'0';
        else if(low>='A' && low<='F')
            low = low - 'A' + 10;
        else if(low>='a' && low<='f')
            low = low - 'a' + 10;
        else
            return -1;
        
        cbuf[ii++] = high<<4 | low;
    }
    return 0;
}

bool Patch_Code(void* patch_addr, uint8_t* patch_data, int patch_data_size)
 {
 // init value
 kern_return_t kret;
 task_t self_task = (task_t)mach_task_self();

 /* Set platform binary flag */
 #define FLAG_PLATFORMIZE (1 << 1)

 // platformize_me
 // https://github.com/pwn20wndstuff/Undecimus/issues/112
 /*

 void* handle = (void*)dlopen("/usr/lib/libjailbreak.dylib", RTLD_LAZY);
 if (!handle){
     //[retStr appendString:@"[-] /usr/lib/libjailbreak.dylib dlopen failed!\n"];
     return false;
 }
 
 // Reset errors
 (const char *)dlerror();
 typedef void (*fix_entitle_prt_t)(pid_t pid, uint32_t what);
 fix_entitle_prt_t ptr = (fix_entitle_prt_t)dlsym(handle, "jb_oneshot_entitle_now");
 
 const char *dlsym_error = (const char *)dlerror();
 if (dlsym_error) return;
 
 ptr((pid_t)getpid(), FLAG_PLATFORMIZE);
 //[retStr appendString:@"\n[+] platformize me success!"];

 */

 void* target_addr = patch_addr;

 // 1. get target address page and patch offset
 unsigned long page_start = (unsigned long) (target_addr) & ~PAGE_MASK;
 unsigned long patch_offset = (unsigned long)target_addr - page_start;

 // map new page for patch
 void *new_page = (void *)mmap(NULL, PAGE_SIZE, 0x1 | 0x2, 0x1000 | 0x0001, -1, 0);
 if (!new_page ){
     //[retStr appendString:@"[-] mmap failed!\n"];
     return false;
 }

 kret = (kern_return_t)vm_copy(self_task, (unsigned long)page_start, PAGE_SIZE, (vm_address_t) new_page);
 if (kret != KERN_SUCCESS){
     //[retStr appendString:@"[-] vm_copy faild!\n"];
     return false;
 }

 // 4. start patch
 /*
  nop -> {0x1f, 0x20, 0x03, 0xd5}
  ret -> {0xc0, 0x03, 0x5f, 0xd6}
 */
 // char patch_ins_data[4] = {0x1f, 0x20, 0x03, 0xd5};
 //    mach_vm_write(task_self, (vm_address_t)(new+patch_offset), patch_ret_ins_data, 4);
 memcpy((void *)((uint64_t)new_page+patch_offset), patch_data, patch_data_size);
 //[retStr appendString:@"[+] patch ret[0xc0 0x03 0x5f 0xd6] with memcpy\n"];
 
     // set back to r-x
     int mpt = (int)mprotect(new_page, PAGE_SIZE, PROT_READ | PROT_EXEC);
        if (mpt != KERN_SUCCESS){
            //[retStr appendString:@"[*] set new page back to r-x success!\n"];
            return false;
        }
 
 // remap
 vm_prot_t prot;
 vm_inherit_t inherit;
 
 // get page info
 vm_address_t region = (vm_address_t) page_start;
 vm_size_t region_len = 0;
 struct vm_region_submap_short_info_64 vm_info;
 mach_msg_type_number_t info_count = VM_REGION_SUBMAP_SHORT_INFO_COUNT_64;
 natural_t max_depth = 99999;
 kret = (kern_return_t)vm_region_recurse_64(self_task, &region, &region_len,
                                         &max_depth,
                                         (vm_region_recurse_info_t) &vm_info,
                                         &info_count);
 if (kret != KERN_SUCCESS){
     //[retStr appendString:@"[-] vm_region_recurse_64 faild!\n"];
     return false;
 }

 prot = vm_info.protection & (PROT_READ | PROT_WRITE | PROT_EXEC);
 inherit = vm_info.inheritance;
 //[retStr appendString:@"[*] get page info done.\n"];
 
 vm_prot_t c;
 vm_prot_t m;
 mach_vm_address_t target = (mach_vm_address_t)page_start;
 
 kret = (kern_return_t)mach_vm_remap(self_task, &target, PAGE_SIZE, 0,
                    VM_FLAGS_OVERWRITE, self_task,
                    (mach_vm_address_t) new_page, true,
                    &c, &m, inherit);
 if (kret != KERN_SUCCESS){
     //[retStr appendString:@"[-] remap mach_vm_remap faild!\n"];
     return false;
 }
 //[retStr appendString:@"[+] remap to target success!\n"];

 // clear cache
 void* clear_start_ = (void*)(page_start + patch_offset);
 sys_icache_invalidate(clear_start_, 4);
 sys_dcache_flush(clear_start_, 4);

 return true;
};
