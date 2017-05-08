//
//  NEInjector.m
//  NEInjector
//
//  Created by Nelson on 2017/5/8.
//  Copyright © 2017年 Nelson. All rights reserved.
//

#import "NEInjector.h"
#include <mach-o/loader.h>
#include <mach-o/fat.h>
@implementation NEInjector
+(void)injectMachoPath:(NSString *)machoPath dylibPath:(NSString *)dylibPath{
    int fd = open(machoPath.UTF8String, O_RDWR, 0777);
    if (fd < 0)
    {
        NSLog(@"Inject failed: failed to open %@",machoPath);
        return;
    }
    else
    {
        uint32_t magic;
        read(fd, &magic, sizeof(magic));
        if (magic == MH_MAGIC || magic == MH_MAGIC_64)
        {
            lseek(fd, 0, SEEK_SET);
            [self injectArchitecture:fd dylibPath:dylibPath exePath:machoPath];
        }
        else if (magic == FAT_MAGIC || magic == FAT_CIGAM)
        {
            struct fat_header header;
            lseek(fd, 0, SEEK_SET);
            read(fd, &header, sizeof(fat_header));
            int nArch = header.nfat_arch;
            if (magic == FAT_CIGAM) nArch = [self bigEndianToSmallEndian:header.nfat_arch];
            
            struct fat_arch arch;
            NSMutableArray *offsetArray = [NSMutableArray array];
            for (int i = 0; i < nArch; i++)
            {
                memset(&arch, 0, sizeof(fat_arch));
                read(fd, &arch, sizeof(fat_arch));
                int offset = arch.offset;
                if (magic == FAT_CIGAM) offset = [self bigEndianToSmallEndian:arch.offset];
                [offsetArray addObject:[NSNumber numberWithUnsignedInt:offset]];
            }
            
            for (NSNumber *offsetNum in offsetArray)
            {
                lseek(fd, [offsetNum unsignedIntValue], SEEK_SET);
                [self injectArchitecture:fd dylibPath:dylibPath exePath:machoPath];
            }
        }
        close(fd);
    }
}
+ (void)injectArchitecture:(int)fd dylibPath:(NSString *)dylibPath exePath:(NSString *)exePathForInfoOnly
{
    off_t archPoint = lseek(fd, 0, SEEK_CUR);
    struct mach_header header;
    read(fd, &header, sizeof(header));
    if (header.magic != MH_MAGIC && header.magic != MH_MAGIC_64)
    {
        NSLog(@"Inject failed: Invalid executable %@",exePathForInfoOnly);
    }
    else
    {
        if (header.magic == MH_MAGIC_64)
        {
            int delta = sizeof(mach_header_64) - sizeof(mach_header);
            lseek(fd, delta, SEEK_CUR);
        }
        
        char *buffer = (char *)malloc(header.sizeofcmds + 2048);
        read(fd, buffer, header.sizeofcmds);
        
        if ([[NSFileManager defaultManager] fileExistsAtPath:dylibPath])
        {
            dylibPath = [@"@executable_path" stringByAppendingPathComponent:[dylibPath lastPathComponent]];
        }
        const char *dylib = dylibPath.UTF8String;
        struct dylib_command *p = (struct dylib_command *)buffer;
        struct dylib_command *last = NULL;
        for (uint32_t i = 0; i < header.ncmds; i++, p = (struct dylib_command *)((char *)p + p->cmdsize))
        {
            if (p->cmd == LC_LOAD_DYLIB || p->cmd == LC_LOAD_WEAK_DYLIB)
            {
                char *name = (char *)p + p->dylib.name.offset;
                if (strcmp(dylib, name) == 0)
                {
                    NSLog(@"Already Injected: %@ with %s", exePathForInfoOnly, dylib);
                    close(fd);
                    return;
                }
                last = p;
            }
        }
        
        if ((char *)p - buffer != header.sizeofcmds)
        {
            NSLog(@"LC payload not mismatch: %@", exePathForInfoOnly);
        }
        
        if (last)
        {
            struct dylib_command *inject = (struct dylib_command *)((char *)last + last->cmdsize);
            char *movefrom = (char *)inject;
            uint32_t cmdsize = sizeof(*inject) + (uint32_t)strlen(dylib) + 1;
            cmdsize = (cmdsize + 0x10) & 0xFFFFFFF0;
            char *moveout = (char *)inject + cmdsize;
            for (int i = (int)(header.sizeofcmds - (movefrom - buffer) - 1); i >= 0; i--)
            {
                moveout[i] = movefrom[i];
            }
            memset(inject, 0, cmdsize);
            inject->cmd = LC_LOAD_DYLIB;
            inject->cmdsize = cmdsize;
            inject->dylib.name.offset = sizeof(dylib_command);
            inject->dylib.timestamp = 2;
            inject->dylib.current_version = 0x00010000;
            inject->dylib.compatibility_version = 0x00010000;
            strcpy((char *)inject + inject->dylib.name.offset, dylib);
            
            header.ncmds++;
            header.sizeofcmds += inject->cmdsize;
            lseek(fd, archPoint, SEEK_SET);
            write(fd, &header, sizeof(header));
            
            lseek(fd, archPoint + ((header.magic == MH_MAGIC_64) ? sizeof(mach_header_64) : sizeof(mach_header)), SEEK_SET);
            write(fd, buffer, header.sizeofcmds);
        }
        else
        {
            NSLog(@"nject failed: No valid LC_LOAD_DYLIB %@",exePathForInfoOnly);
        }
        
        free(buffer);
    }
}

+ (uint32_t)bigEndianToSmallEndian:(uint32_t)bigEndian
{
    uint32_t smallEndian = 0;
    unsigned char *small = (unsigned char *)&smallEndian;
    unsigned char *big = (unsigned char *)&bigEndian;
    for (int i=0; i<4; i++)
    {
        small[i] = big[3-i];
    }
    return smallEndian;
}

@end
