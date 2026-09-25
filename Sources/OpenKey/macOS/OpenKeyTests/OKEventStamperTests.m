//
//  OKEventStamperTests.m
//  OpenKeyTests
//

#import <XCTest/XCTest.h>
#import "OKEventStamper.h"

@interface OKEventStamperTests : XCTestCase
@end

@implementation OKEventStamperTests

- (void)testFirstStampIsTheTimeItself {
    XCTAssertEqual([[OKEventStamper new] stampForTime:1000], 1000u);
}

- (void)testLaterTimesPassThrough {
    OKEventStamper *stamper = [OKEventStamper new];
    [stamper stampForTime:1000];
    XCTAssertEqual([stamper stampForTime:1500], 1500u);
}

/// Events created in the same tick must still come out in order.
- (void)testSameTimeGetsTheNextTick {
    OKEventStamper *stamper = [OKEventStamper new];
    XCTAssertEqual([stamper stampForTime:1000], 1000u);
    XCTAssertEqual([stamper stampForTime:1000], 1001u);
    XCTAssertEqual([stamper stampForTime:1000], 1002u);
}

/// A time older than the last stamp never goes back.
- (void)testOlderTimeStillMovesForward {
    OKEventStamper *stamper = [OKEventStamper new];
    [stamper stampForTime:1000];
    XCTAssertEqual([stamper stampForTime:900], 1001u);
}

@end
