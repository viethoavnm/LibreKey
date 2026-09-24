//
//  OKSpotlightDetector.m
//  LibreKey
//

#import "OKSpotlightDetector.h"

@implementation OKSpotlightDetector {
    NSTimeInterval _lifetime;
}

+ (BOOL)windowListShowsSpotlight:(NSArray<NSDictionary*>*)windows {
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
    return NO;
}

- (void)storeAnswer:(BOOL)answer at:(NSTimeInterval)now {
}

- (void)invalidate {
}

@end
