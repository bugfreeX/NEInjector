//
//  NEInject.h
//  NEInject
//
//  Created by Nelson on 2017/5/8.
//  Copyright © 2017年 Nelson. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NEInject : NSObject
+(void)injectMachoPath:(NSString *)machoPath dylibPath:(NSString *)dylibPath;
@end
