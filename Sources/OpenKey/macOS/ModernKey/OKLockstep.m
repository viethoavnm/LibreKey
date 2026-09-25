//
//  OKLockstep.m
//  LibreKey
//

#import "OKLockstep.h"

@implementation OKLockstep {
    NSTimeInterval _window;
    BOOL _correctionInWord;
    BOOL _hasCorrection;
    NSTimeInterval _lastCorrection;
}

- (instancetype)initWithWindow:(NSTimeInterval)window {
    self = [super init];
    if (self) {
        _window = window;
    }
    return self;
}

- (void)noteCorrectionPostedAt:(NSTimeInterval)now {
    _correctionInWord = YES;
    _hasCorrection = YES;
    _lastCorrection = now;
}

- (void)reset {
    _correctionInWord = NO;
    _hasCorrection = NO;
}

- (BOOL)shouldPostKeyAt:(NSTimeInterval)now
                   plan:(OKTypingPlan*)plan
               endsWord:(BOOL)endsWord
               shortcut:(BOOL)shortcut {
    if (shortcut) {
        [self reset];
        return NO;
    }
    BOOL closeBehind = _hasCorrection && now >= _lastCorrection && now - _lastCorrection <= _window;
    BOOL post = plan.syntheticLockstep && (_correctionInWord || closeBehind);
    if (endsWord)
        _correctionInWord = NO;
    return post;
}

@end
