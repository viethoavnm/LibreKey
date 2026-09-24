//
//  OKSpotlightDetectorTests.m
//  OpenKeyTests
//

#import <XCTest/XCTest.h>
#import <CoreGraphics/CoreGraphics.h>
#import "OKSpotlightDetector.h"

@interface OKSpotlightDetectorTests : XCTestCase
@end

@implementation OKSpotlightDetectorTests

- (NSDictionary *)window:(NSString *)owner alpha:(double)alpha layer:(int)layer {
    return @{(__bridge NSString *)kCGWindowOwnerName: owner,
             (__bridge NSString *)kCGWindowAlpha: @(alpha),
             (__bridge NSString *)kCGWindowLayer: @(layer)};
}

#pragma mark - windowListShowsSpotlight

- (void)testVisibleSpotlightPanel {
    NSArray *windows = @[[self window:@"Finder" alpha:1 layer:0],
                         [self window:@"Spotlight" alpha:1 layer:25]];
    XCTAssertTrue([OKSpotlightDetector windowListShowsSpotlight:windows]);
}

/// While it fades out after being dismissed, Spotlight is still in the list.
- (void)testFadedOutSpotlightDoesNotCount {
    XCTAssertFalse([OKSpotlightDetector windowListShowsSpotlight:@[[self window:@"Spotlight" alpha:0 layer:25]]]);
}

/// A Spotlight window at the normal layer is not the search panel.
- (void)testSpotlightWindowAtNormalLayerDoesNotCount {
    XCTAssertFalse([OKSpotlightDetector windowListShowsSpotlight:@[[self window:@"Spotlight" alpha:1 layer:0]]]);
}

- (void)testOtherAppsAndEmptyList {
    XCTAssertFalse([OKSpotlightDetector windowListShowsSpotlight:@[[self window:@"Safari" alpha:1 layer:25]]]);
    XCTAssertFalse([OKSpotlightDetector windowListShowsSpotlight:@[]]);
}

- (void)testMissingFieldsDoNotCount {
    NSDictionary *bare = @{(__bridge NSString *)kCGWindowOwnerName: @"Spotlight"};
    XCTAssertFalse([OKSpotlightDetector windowListShowsSpotlight:@[bare]]);
}

#pragma mark - cache

- (void)testNoAnswerBeforeOneIsStored {
    OKSpotlightDetector *cache = [[OKSpotlightDetector alloc] initWithLifetime:2];
    XCTAssertFalse([cache hasAnswerAt:100]);
}

- (void)testStoredAnswerLastsItsLifetime {
    OKSpotlightDetector *cache = [[OKSpotlightDetector alloc] initWithLifetime:2];
    [cache storeAnswer:YES at:100];
    XCTAssertTrue([cache hasAnswerAt:100]);
    XCTAssertTrue([cache hasAnswerAt:101.9]);
    XCTAssertTrue(cache.answer);
    XCTAssertFalse([cache hasAnswerAt:102.1]);
}

- (void)testInvalidateDropsTheAnswer {
    OKSpotlightDetector *cache = [[OKSpotlightDetector alloc] initWithLifetime:2];
    [cache storeAnswer:NO at:100];
    [cache invalidate];
    XCTAssertFalse([cache hasAnswerAt:100.5]);
}

/// A clock that went backwards (sleep, time change) must not keep an answer alive.
- (void)testAnswerFromTheFutureIsNotTrusted {
    OKSpotlightDetector *cache = [[OKSpotlightDetector alloc] initWithLifetime:2];
    [cache storeAnswer:YES at:100];
    XCTAssertFalse([cache hasAnswerAt:50]);
}

@end
