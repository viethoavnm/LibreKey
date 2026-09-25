//
//  OKEventStamper.m
//  LibreKey
//

#import "OKEventStamper.h"

@implementation OKEventStamper {
    uint64_t _last;
    BOOL _started;
}

- (uint64_t)stampForTime:(uint64_t)now {
    _last = (!_started || now > _last) ? now : _last + 1;
    _started = YES;
    return _last;
}

@end
