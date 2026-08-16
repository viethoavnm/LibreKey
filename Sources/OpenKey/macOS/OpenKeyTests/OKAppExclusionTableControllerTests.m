//
//  OKAppExclusionTableControllerTests.m
//  OpenKeyTests
//

#import <XCTest/XCTest.h>
#import "OKAppExclusionTableController.h"

static NSString* const kFinderPath = @"/System/Library/CoreServices/Finder.app";
static NSString* const kFinderBundleId = @"com.apple.finder";

@interface OKAppExclusionTableControllerTests : XCTestCase
@end

@implementation OKAppExclusionTableControllerTests {
    NSUserDefaults *_defaults;
    NSString *_suiteName;
    OKAppExclusionTableController *_controller;
}

- (void)setUp {
    [super setUp];
    _suiteName = [NSString stringWithFormat:@"OKAppExclusionTableTests-%@", [[NSUUID UUID] UUIDString]];
    _defaults = [[NSUserDefaults alloc] initWithSuiteName:_suiteName];
    _controller = [[OKAppExclusionTableController alloc] initWithDefaults:_defaults];
}

- (void)tearDown {
    _controller = nil;
    [_defaults removePersistentDomainForName:_suiteName];
    _defaults = nil;
    [super tearDown];
}

- (NSURL *)finderURL {
    return [NSURL fileURLWithPath:kFinderPath];
}

#pragma mark - Loading

- (void)testStartsEmptyOnFreshDefaults {
    XCTAssertEqual(_controller.entries.count, 0u);
    XCTAssertEqual([_controller numberOfRowsInTableView:nil], 0);
}

- (void)testReloadPicksUpWhatIsInDefaults {
    OKAppExclusionEntry *entry = [[OKAppExclusionEntry alloc] initWithBundleId:@"com.acme.App" name:@"Acme"];
    [OKAppExclusionList writeEntries:@[entry] toDefaults:_defaults];

    [_controller reload];

    XCTAssertEqual(_controller.entries.count, 1u);
    XCTAssertEqual([_controller numberOfRowsInTableView:nil], 1);
}

#pragma mark - Adding

- (void)testAddingAnApplicationStoresIt {
    XCTAssertTrue([_controller addApplicationAtURL:[self finderURL]]);
    XCTAssertEqual(_controller.entries.count, 1u);
    XCTAssertEqualObjects(_controller.entries[0].bundleId, kFinderBundleId);
}

/// The point of the whole class: whatever the panel does has to reach the
/// defaults, because that is the only channel to the event tap.
- (void)testAddingAnApplicationWritesThroughToDefaults {
    [_controller addApplicationAtURL:[self finderURL]];

    NSArray<OKAppExclusionEntry *> *stored = [OKAppExclusionList entriesFromDefaults:_defaults];
    XCTAssertEqual(stored.count, 1u);
    XCTAssertEqualObjects(stored[0].bundleId, kFinderBundleId);
}

- (void)testAddingTheSameApplicationTwiceReportsFailure {
    XCTAssertTrue([_controller addApplicationAtURL:[self finderURL]]);
    XCTAssertFalse([_controller addApplicationAtURL:[self finderURL]]);
    XCTAssertEqual(_controller.entries.count, 1u);
}

- (void)testAddingSomethingThatIsNotAnApplicationReportsFailure {
    XCTAssertFalse([_controller addApplicationAtURL:[NSURL fileURLWithPath:@"/etc/hosts"]]);
    XCTAssertEqual(_controller.entries.count, 0u);
}

#pragma mark - Removing

- (void)testRemovingASelectedRow {
    [_controller addApplicationAtURL:[self finderURL]];

    XCTAssertTrue([_controller removeEntriesAtIndexes:[NSIndexSet indexSetWithIndex:0]]);
    XCTAssertEqual(_controller.entries.count, 0u);
    XCTAssertEqual([OKAppExclusionList entriesFromDefaults:_defaults].count, 0u);
}

/// The − button is clickable with nothing selected until the delegate catches
/// up, so an empty index set must be a no-op rather than a crash.
- (void)testRemovingNothingReportsFailure {
    [_controller addApplicationAtURL:[self finderURL]];

    XCTAssertFalse([_controller removeEntriesAtIndexes:[NSIndexSet indexSet]]);
    XCTAssertEqual(_controller.entries.count, 1u);
}

- (void)testRemovingAnOutOfRangeRowReportsFailure {
    XCTAssertFalse([_controller removeEntriesAtIndexes:[NSIndexSet indexSetWithIndex:3]]);
}

#pragma mark - Cell text

- (void)testCellTextForEachColumn {
    OKAppExclusionEntry *entry = [[OKAppExclusionEntry alloc] initWithBundleId:@"com.acme.App" name:@"Acme"];
    [OKAppExclusionList writeEntries:@[entry] toDefaults:_defaults];
    [_controller reload];

    XCTAssertEqualObjects([_controller textForColumnIdentifier:OKAppExclusionColumnAppName row:0], @"Acme");
    XCTAssertEqualObjects([_controller textForColumnIdentifier:OKAppExclusionColumnBundleId row:0], @"com.acme.App");
}

- (void)testCellTextIsNilOutsideTheList {
    [_controller addApplicationAtURL:[self finderURL]];

    XCTAssertNil([_controller textForColumnIdentifier:OKAppExclusionColumnAppName row:1]);
    XCTAssertNil([_controller textForColumnIdentifier:OKAppExclusionColumnAppName row:-1]);
    XCTAssertNil([_controller textForColumnIdentifier:@"NoSuchColumn" row:0]);
}

@end
