//
//  OKLockstep.m
//  LibreKey
//

#import "OKLockstep.h"

@implementation OKLockstep {
    NSTimeInterval _window;
}

- (instancetype)initWithWindow:(NSTimeInterval)window {
    self = [super init];
    if (self) {
        _window = window;
    }
    return self;
}

- (void)noteCorrectionPostedAt:(NSTimeInterval)now {
}

- (void)reset {
}

- (BOOL)shouldPostKeyAt:(NSTimeInterval)now
                   plan:(OKTypingPlan*)plan
               endsWord:(BOOL)endsWord
               shortcut:(BOOL)shortcut {
    return NO;
}

@end
