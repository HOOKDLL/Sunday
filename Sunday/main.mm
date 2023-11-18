//
//  main.m
//  Sunday
//
//  Created by 丘远冲 on 2023/10/28.
//

#import <Foundation/Foundation.h>
#import "PatternFind.h"
#import "Sunday.h"

#ifdef DEBUG
#define DebugLog(fmt, ...) NSLog((@"[DEBUG] " fmt), ##__VA_ARGS__)
#else
#define DebugLog(fmt, ...)
#endif

int main(int argc, const char * argv[]) {
    @autoreleasepool {
        // insert code here...
        NSLog(@"[+] Hello, World!");
        NSLog(@"[+] 你好，世界！");
    }
    return 0;
}

@implementation Sunday

+(void)load {
    const char* imageName = _dyld_get_image_name(0);
    if (strstr(imageName, "libBacktraceRecording.dylib") == NULL) {
        return ;
    }
        ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
        //遍历自身加载的dylib－－获取载入地址和ASLR地址等
        //NSLog(@"[+] Dyld image count is: %d.\n", _dyld_image_count());
        for (int i = 0; i < _dyld_image_count(); i++) {
            char *image_name = (char *)_dyld_get_image_name(i);
            const struct mach_header *mh = _dyld_get_image_header(i);
            intptr_t vmaddr_slide = _dyld_get_image_vmaddr_slide(i);
            //过滤想要的库
            if (strstr(image_name, "Sunday") != NULL) {

                DebugLog(@"[+] Image name %s at address 0x%llx and ASLR slide 0x%lx.\n",image_name, (mach_vm_address_t)mh, vmaddr_slide);

                uint64_t size1 = 0;
                char *referencesSection1 = getsectdatafromheader_64((struct mach_header_64 *)mh,"__TEXT", "__text", &size1);
                DebugLog(@"[+] getsectdatafromheader_64$__TEXT$__text:%p\n", (void *)referencesSection1);
                char *StartAddr__ = referencesSection1 + vmaddr_slide;  //这才是真实要访问的地址。
                DebugLog(@"[+] $__TEXT$__text_start + vmaddr_slide:%p\n", (void *)StartAddr__);
                uint64_t StartAddr = reinterpret_cast<uint64_t>(StartAddr__);
                
                uint64_t size2 = 0;
                char *referencesSection2 = getsectdatafromheader_64((struct mach_header_64 *)mh,"__DATA", "__data", &size2);
                DebugLog(@"[+] getsectdatafromheader_64$__DATA$__data:%p\n", (void *)referencesSection2);
                char *StartEnd__ = referencesSection2 + vmaddr_slide;  //这才是真实要访问的地址。
                DebugLog(@"[+] $__DATA$__data_end + vmaddr_slide:%p\n", (void *)StartEnd__);
                uint64_t StartEnd = reinterpret_cast<uint64_t>(StartEnd__);
                
                
#if defined (__arm64__)
                DebugLog(@"[+] runing arm64 64-bit [__arm64__ arch]\n");
#elif defined(__x86_64__)
                DebugLog(@"[+] runing x86_64 64-bit [__x86_64__ arch]\n");
#endif
                            
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                const wchar_t* UTF16_FeatureCode = L"你好，世界！";//长度必须为2的倍数
//                size_t len = wcslen(UTF16_FeatureCode);
//                char* FeatureCode = (char*)malloc((len * 5 + 1) * sizeof(char)); // 预留足够的空间来存储转换后的结果
//                FeatureCode[0] = '\0'; // 初始化结果字符串为空
//                setlocale(LC_ALL, ""); // 设置本地化环境以支持宽字符转换
//                for (int i = 0; i < len; i++) {
//                    wchar_t swapped = ((UTF16_FeatureCode[i] & 0xFF) << 8) | ((UTF16_FeatureCode[i] & 0xFF00) >> 8);
//                    snprintf(FeatureCode + strlen(FeatureCode), (len * 5 + 1) - strlen(FeatureCode), "%04X", swapped); // 将转换后的结果拼接到结果字符串中
//                }
//                //DebugLog(@"[+] %s\n", FeatureCode);
//                //free(FeatureCode); // 释放动态分配的内存
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                char FeatureCode[] = "Hello, World!";//长度必须为2的倍数
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                char FeatureCode[100] = "83 F? 1D 7?";//长度必须为2的倍数
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
                char FeatureCode[] = "48 65 6C 6C 6F 2C 20 57 6F 72 6C 64 21";//长度必须为2的倍数
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
                std::vector<Sunday_int64> addr = X64dbgSundayFind(FeatureCode, StartAddr, StartEnd, 0);
//              返回vector数组 ⬅️= 1️⃣特征码,2️⃣起始位置 0x0000000000000000,3️⃣结束位置 0x7FFFFFFFFFFFFFFF,4️⃣控制搜索次数(0则为无限搜索到结束)
                if (addr.size() != 0){
                    for (size_t i = 0; i < addr.size(); i++){
                        
                        uintptr_t ptr = (uintptr_t)addr[i];
                        unsigned char* bytePtr = (unsigned char*)ptr;
                        int numBytes = 13; // 读取的字节数
                        char hexString[numBytes * 2 + 1]; // 存储十六进制字符串的变量
                        for (int i = 0; i < numBytes; i++) {// 读取指针地址指向的内容
                            snprintf(hexString + (i * 2), 3, "%02X", *(bytePtr + i));
                        }
                        DebugLog(@"[+] 结果地址%zu: %p 指针内存:-> %s -> %s\n",i, (char*)(uintptr_t)addr[i] ,hexString,(char*)(uintptr_t)addr[i]);
                        
                    }
                    
                    //方式1
                    char PatchCode[] ="48 65 6C 6C 6F 2C 20 50 59 47 21 00";//破解
                    trim(PatchCode);// 去除空格
                    int iBufSize = (int)strlen(PatchCode)/2;// 缓冲区大小
                    void *lpBuf = malloc(iBufSize);
                    memset(lpBuf, 0, iBufSize);
                    strtohex(PatchCode, (Byte *)lpBuf, (int)strlen(PatchCode));
                    bool abok = Patch_Code((void *)addr[0],(uint8_t *)lpBuf,iBufSize);
                    
                    //方式2
                    char PatchCodeStr[] ="Hello, PYG!!!";
                    abok = Patch_Code((void *)addr[0],(uint8_t *)PatchCodeStr,sizeof(PatchCodeStr));
                    
                    if (abok == true) {
                        DebugLog(@"[+] Patch Successfully : %d",abok);
                    }else{
                        NSLog(@"[+] Patch Error : %d",abok);
                    }

                    break;
                    
                }else{
                    NSLog(@"[+] 没有搜索到条目\n\n");
                    break;
                }
            }
        }
    }

@end
