//
//  OKTerminalTyping.m
//  LibreKey
//

#import "OKTerminalTyping.h"

//Lowercase. Each one also covers ids hanging off it after a dot or a dash, so
//the release channels (Warp-Preview, ghostty.debug, ...) come along.
static NSArray<NSString*>* TerminalBundleIds(void) {
    static NSArray<NSString*>* ids;
    static dispatch_once_t once;
    dispatch_once(&once, ^{
        ids = @[@"com.apple.terminal",
                @"com.googlecode.iterm2",
                @"dev.warp.warp",
                @"net.kovidgoyal.kitty",
                @"org.alacritty",
                @"com.github.wez.wezterm",
                @"com.mitchellh.ghostty",
                @"co.zeit.hyper",
                @"org.tabby",
                @"com.termius"];
    });
    return ids;
}

@implementation OKTypingTarget

- (instancetype)initWithBundleId:(nullable NSString*)bundleId
                spotlightVisible:(BOOL)spotlightVisible {
    return [self initWithBundleId:bundleId spotlightVisible:spotlightVisible integratedTerminal:NO];
}

- (instancetype)initWithBundleId:(nullable NSString*)bundleId
                spotlightVisible:(BOOL)spotlightVisible
              integratedTerminal:(BOOL)integratedTerminal {
    self = [super init];
    if (self) {
        _bundleId = [bundleId copy];
        _spotlightVisible = spotlightVisible;
        _integratedTerminal = integratedTerminal;
    }
    return self;
}

@end

@implementation OKTypingPlan

- (instancetype)initWithAllowsAutocompleteWorkaround:(BOOL)allowsAutocompleteWorkaround
                                oneCharacterPerEvent:(BOOL)oneCharacterPerEvent
                                   syntheticLockstep:(BOOL)syntheticLockstep {
    self = [super init];
    if (self) {
        _allowsAutocompleteWorkaround = allowsAutocompleteWorkaround;
        _oneCharacterPerEvent = oneCharacterPerEvent;
        _syntheticLockstep = syntheticLockstep;
    }
    return self;
}

@end

@implementation OKTerminalTyping

+ (BOOL)isTerminalBundleId:(nullable NSString*)bundleId {
    if (bundleId.length == 0)
        return NO;

    NSString* lowered = bundleId.lowercaseString;
    for (NSString* known in TerminalBundleIds()) {
        if (![lowered hasPrefix:known])
            continue;
        //A bare prefix would also take org.tabbyml.* for org.tabby.
        if (lowered.length == known.length)
            return YES;
        unichar next = [lowered characterAtIndex:known.length];
        if (next == '.' || next == '-')
            return YES;
    }
    return NO;
}

+ (BOOL)isCodeEditorBundleId:(nullable NSString*)bundleId {
    return NO;
}

+ (BOOL)isIntegratedTerminalDescription:(nullable NSString*)description {
    return NO;
}

+ (OKTypingPlan*)planForTarget:(OKTypingTarget*)target {
    BOOL terminal = !target.spotlightVisible && [self isTerminalBundleId:target.bundleId];
    return [[OKTypingPlan alloc] initWithAllowsAutocompleteWorkaround:!terminal
                                                 oneCharacterPerEvent:terminal
                                                    syntheticLockstep:terminal];
}

@end
