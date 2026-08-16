//
//  OpenKeyManager.h
//  ModernKey
//
//  Created by Tuyen on 1/27/19.
//  Copyright © 2019 Tuyen Mai. All rights reserved.
//

#ifndef OpenKeyManager_h
#define OpenKeyManager_h

#import <Cocoa/Cocoa.h>

@interface OpenKeyManager : NSObject
+(BOOL)isInited;
+(BOOL)initEventTap;
+(BOOL)stopEventTap;

/// YES while the tap exists and is actually delivering events. macOS disables a
/// tap behind our back on timeout and around Fast User Switching, and a disabled
/// tap looks identical to a working one from -isInited alone.
+(BOOL)isEventTapEnabled;

/// Re-arms a tap the system disabled. Safe to call from the event tap callback.
+(BOOL)reEnableEventTap;

+(NSArray*)getTableCodes;

+(NSString*)getBuildDate;
+(void)showMessage:(NSWindow*)window message:(NSString*)msg subMsg:(NSString*)subMsg;

+(BOOL)quickConvert;

/// `~/Library/Application Support/LibreKey` for the current mac user.
+(NSString*)getApplicationSupportFolder;
@end

#endif /* OpenKeyManager_h */
