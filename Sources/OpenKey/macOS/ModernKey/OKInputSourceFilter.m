//
//  OKInputSourceFilter.m
//  LibreKey
//

#import "OKInputSourceFilter.h"

@implementation OKInputSourceFilter

+ (BOOL)shouldBypassForLanguages:(nullable NSArray<NSString*>*)languages {
    if (languages.count == 0)
        return NO;
    for (NSString* language in languages) {
        if (![language isKindOfClass:[NSString class]])
            continue;
        //en, or en followed by a region or script: en-GB, en_US
        if ([language isEqualToString:@"en"] || [language hasPrefix:@"en-"] || [language hasPrefix:@"en_"])
            return NO;
    }
    return YES;
}

@end
