//
//  OKSpotlightDetector.m
//  LibreKey
//

#import "OKSpotlightDetector.h"
#import <CoreGraphics/CoreGraphics.h>

@implementation OKSpotlightDetector {
    NSTimeInterval _lifetime;
    NSTimeInterval _storedAt;
    BOOL _hasAnswer;
}

+ (BOOL)windowListShowsSpotlight:(NSArray<NSDictionary*>*)windows {
    for (NSDictionary* window in windows) {
        if (![window[(__bridge NSString*)kCGWindowOwnerName] isEqualToString:@"Spotlight"])
            continue;
        NSNumber* alpha = window[(__bridge NSString*)kCGWindowAlpha];
        NSNumber* layer = window[(__bridge NSString*)kCGWindowLayer];
        if (alpha.doubleValue > 0 && layer.intValue > 0)
            return YES;
    }
    return NO;
}

- (instancetype)initWithLifetime:(NSTimeInterval)lifetime {
    self = [super init];
    if (self) {
        _lifetime = lifetime;
    }
    return self;
}

- (BOOL)hasAnswerAt:(NSTimeInterval)now {
    //before the time it was stored means the clock moved back: not trusted
    return _hasAnswer && now >= _storedAt && now - _storedAt <= _lifetime;
}

- (void)storeAnswer:(BOOL)answer at:(NSTimeInterval)now {
    _answer = answer;
    _storedAt = now;
    _hasAnswer = YES;
}

- (void)invalidate {
    _hasAnswer = NO;
}

@end
