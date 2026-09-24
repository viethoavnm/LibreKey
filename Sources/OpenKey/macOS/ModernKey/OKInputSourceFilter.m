//
//  OKInputSourceFilter.m
//  LibreKey
//

#import "OKInputSourceFilter.h"

@implementation OKInputSourceFilter

+ (BOOL)shouldBypassForLanguages:(nullable NSArray<NSString*>*)languages {
    return NO;
}

@end
