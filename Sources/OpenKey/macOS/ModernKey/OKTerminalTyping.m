//
//  OKTerminalTyping.m
//  LibreKey
//

#import "OKTerminalTyping.h"

@implementation OKTypingTarget

- (instancetype)initWithBundleId:(nullable NSString*)bundleId
                spotlightVisible:(BOOL)spotlightVisible {
    self = [super init];
    if (self) {
        _bundleId = [bundleId copy];
        _spotlightVisible = spotlightVisible;
    }
    return self;
}

@end

@implementation OKTypingPlan

- (instancetype)initWithAllowsAutocompleteWorkaround:(BOOL)allowsAutocompleteWorkaround
                                oneCharacterPerEvent:(BOOL)oneCharacterPerEvent {
    self = [super init];
    if (self) {
        _allowsAutocompleteWorkaround = allowsAutocompleteWorkaround;
        _oneCharacterPerEvent = oneCharacterPerEvent;
    }
    return self;
}

@end

@implementation OKTerminalTyping

+ (BOOL)isTerminalBundleId:(nullable NSString*)bundleId {
    return NO;
}

+ (OKTypingPlan*)planForTarget:(OKTypingTarget*)target {
    return [[OKTypingPlan alloc] initWithAllowsAutocompleteWorkaround:YES oneCharacterPerEvent:NO];
}

@end
