//
//  OKEventStamper.h
//  LibreKey
//
//  Timestamps for the events LibreKey posts. Events are delivered in timestamp
//  order, and events created back to back can share a timestamp - or, for the
//  two backspace events created once at start up and posted ever since, carry
//  one from hours ago - so a later letter could overtake an earlier correction
//  (VietTelex measured "nuwax" typed fast coming out "nuẵ"). Every posted event
//  gets a stamp strictly after the previous one. Pure model: the host passes
//  the current mach time in.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface OKEventStamper : NSObject

//Input: the current mach_absolute_time(). Output: the timestamp to put on the
//next posted event - `now`, or one tick after the last stamp handed out if
//`now` is not later than it.
- (uint64_t)stampForTime:(uint64_t)now;

@end

NS_ASSUME_NONNULL_END
