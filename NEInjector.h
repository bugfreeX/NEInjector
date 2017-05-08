//
//  NEInjector.h
//  NEInjector
//
//  Created by Nelson on 2017/5/8.
//  Copyright © 2017 Nelson. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NEInjector : NSObject

/**
 dylib injector for mach-o binaries

 @param machoPath mach-o file path
 @param dylibPath .dylib file path
 */
+(void)injectMachoPath:(NSString *)machoPath dylibPath:(NSString *)dylibPath;
@end
