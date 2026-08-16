//
//  OKAppExclusionListTests.m
//  OpenKeyTests
//

#import <XCTest/XCTest.h>
#import "OKAppExclusionList.h"

@interface OKAppExclusionListTests : XCTestCase
@end

@implementation OKAppExclusionListTests {
    NSUserDefaults *_defaults;
    NSString *_suiteName;
}

- (void)setUp {
    [super setUp];
    //A throwaway suite, so the tests never touch the real LibreKey settings.
    _suiteName = [NSString stringWithFormat:@"OKAppExclusionTests-%@", [[NSUUID UUID] UUIDString]];
    _defaults = [[NSUserDefaults alloc] initWithSuiteName:_suiteName];
}

- (void)tearDown {
    [_defaults removePersistentDomainForName:_suiteName];
    _defaults = nil;
    [super tearDown];
}

- (OKAppExclusionEntry *)entryWithBundleId:(NSString *)bundleId {
    return [[OKAppExclusionEntry alloc] initWithBundleId:bundleId name:@"Some App"];
}

#pragma mark - OKAppExclusionEntry

- (void)testEntryKeepsBundleIdAndName {
    OKAppExclusionEntry *entry = [[OKAppExclusionEntry alloc] initWithBundleId:@"com.apple.Safari"
                                                                          name:@"Safari"];
    XCTAssertEqualObjects(entry.bundleId, @"com.apple.Safari");
    XCTAssertEqualObjects(entry.name, @"Safari");
}

- (void)testEntryRoundTripsThroughDictionary {
    OKAppExclusionEntry *entry = [[OKAppExclusionEntry alloc] initWithBundleId:@"com.apple.Terminal"
                                                                          name:@"Terminal"];
    OKAppExclusionEntry *restored = [OKAppExclusionEntry entryFromDictionary:[entry dictionaryValue]];
    XCTAssertEqualObjects(restored.bundleId, @"com.apple.Terminal");
    XCTAssertEqualObjects(restored.name, @"Terminal");
}

- (void)testEntryFromDictionaryRejectsMissingBundleId {
    XCTAssertNil([OKAppExclusionEntry entryFromDictionary:@{}]);
    XCTAssertNil([OKAppExclusionEntry entryFromDictionary:@{@"name": @"No id"}]);
    XCTAssertNil([OKAppExclusionEntry entryFromDictionary:@{@"bundleId": @""}]);
}

/// A stored name may go missing; the entry must still load, because the bundle
/// id is what the event tap matches on.
- (void)testEntryFromDictionaryFallsBackToBundleIdAsName {
    OKAppExclusionEntry *entry = [OKAppExclusionEntry entryFromDictionary:@{@"bundleId": @"com.acme.App"}];
    XCTAssertEqualObjects(entry.bundleId, @"com.acme.App");
    XCTAssertEqualObjects(entry.name, @"com.acme.App");
}

#pragma mark - Persistence

- (void)testEntriesFromEmptyDefaultsIsEmpty {
    XCTAssertEqualObjects([OKAppExclusionList entriesFromDefaults:_defaults], @[]);
}

- (void)testEntriesRoundTripThroughDefaults {
    NSArray *entries = @[[self entryWithBundleId:@"com.apple.Safari"],
                         [self entryWithBundleId:@"com.apple.Terminal"]];
    [OKAppExclusionList writeEntries:entries toDefaults:_defaults];

    NSArray<OKAppExclusionEntry *> *loaded = [OKAppExclusionList entriesFromDefaults:_defaults];
    XCTAssertEqual(loaded.count, 2u);
    XCTAssertEqualObjects(loaded[0].bundleId, @"com.apple.Safari");
    XCTAssertEqualObjects(loaded[1].bundleId, @"com.apple.Terminal");
}

/// Anything can end up under a defaults key - another app, a bad migration, a
/// hand-edited plist. Reading must not throw, or the event tap dies with it.
- (void)testEntriesFromDefaultsSurvivesGarbage {
    [_defaults setObject:@"not an array" forKey:OKAppExclusionDefaultsKey];
    XCTAssertEqualObjects([OKAppExclusionList entriesFromDefaults:_defaults], @[]);

    [_defaults setObject:@[@"not a dictionary", @{@"bundleId": @"com.acme.App"}]
                  forKey:OKAppExclusionDefaultsKey];
    NSArray<OKAppExclusionEntry *> *loaded = [OKAppExclusionList entriesFromDefaults:_defaults];
    XCTAssertEqual(loaded.count, 1u);
    XCTAssertEqualObjects(loaded[0].bundleId, @"com.acme.App");
}

#pragma mark - Lookup

- (void)testContainBundleIdFindsAnExcludedApp {
    NSArray *entries = @[[self entryWithBundleId:@"com.apple.Safari"]];
    XCTAssertTrue([OKAppExclusionList entries:entries containBundleId:@"com.apple.Safari"]);
}

- (void)testContainBundleIdIgnoresOtherApps {
    NSArray *entries = @[[self entryWithBundleId:@"com.apple.Safari"]];
    XCTAssertFalse([OKAppExclusionList entries:entries containBundleId:@"com.apple.Terminal"]);
    XCTAssertFalse([OKAppExclusionList entries:@[] containBundleId:@"com.apple.Safari"]);
}

/// Excluding "com.apple.Safari" must not silently exclude every com.apple app,
/// and a nil bundle id (frontmostApplication can hand us one) is never excluded.
- (void)testContainBundleIdIsExactNotPrefix {
    NSArray *entries = @[[self entryWithBundleId:@"com.apple.Safari"]];
    XCTAssertFalse([OKAppExclusionList entries:entries containBundleId:@"com.apple.SafariTechnologyPreview"]);
    XCTAssertFalse([OKAppExclusionList entries:entries containBundleId:@"com.apple."]);
    XCTAssertFalse([OKAppExclusionList entries:entries containBundleId:nil]);
}

#pragma mark - Add and remove

- (void)testAddingEntryAppendsIt {
    NSArray *entries = [OKAppExclusionList entries:@[]
                                     byAddingEntry:[self entryWithBundleId:@"com.apple.Safari"]];
    XCTAssertEqual(entries.count, 1u);

    entries = [OKAppExclusionList entries:entries
                            byAddingEntry:[self entryWithBundleId:@"com.apple.Terminal"]];
    XCTAssertEqual(entries.count, 2u);
    XCTAssertEqualObjects(((OKAppExclusionEntry *)entries[1]).bundleId, @"com.apple.Terminal");
}

- (void)testAddingTheSameAppTwiceIsIgnored {
    NSArray *entries = @[[self entryWithBundleId:@"com.apple.Safari"]];
    NSArray *afterAdd = [OKAppExclusionList entries:entries
                                      byAddingEntry:[self entryWithBundleId:@"com.apple.Safari"]];
    XCTAssertEqual(afterAdd.count, 1u);
}

- (void)testRemovingIndexesDropsTheRightRows {
    NSArray *entries = @[[self entryWithBundleId:@"a"],
                         [self entryWithBundleId:@"b"],
                         [self entryWithBundleId:@"c"]];
    NSMutableIndexSet *indexes = [NSMutableIndexSet indexSetWithIndex:0];
    [indexes addIndex:2];

    NSArray<OKAppExclusionEntry *> *left = [OKAppExclusionList entries:entries byRemovingIndexes:indexes];
    XCTAssertEqual(left.count, 1u);
    XCTAssertEqualObjects(left[0].bundleId, @"b");
}

- (void)testRemovingOutOfRangeIndexesIsIgnored {
    NSArray *entries = @[[self entryWithBundleId:@"a"]];
    NSArray *left = [OKAppExclusionList entries:entries
                              byRemovingIndexes:[NSIndexSet indexSetWithIndex:7]];
    XCTAssertEqual(left.count, 1u);

    left = [OKAppExclusionList entries:entries byRemovingIndexes:[NSIndexSet indexSet]];
    XCTAssertEqual(left.count, 1u);
}

#pragma mark - Reading an app off disk

- (void)testEntryForApplicationReadsBundleIdAndName {
    //Finder is on every mac and its bundle id has not moved in twenty years.
    OKAppExclusionEntry *entry =
        [OKAppExclusionList entryForApplicationAtURL:[NSURL fileURLWithPath:@"/System/Library/CoreServices/Finder.app"]];
    XCTAssertEqualObjects(entry.bundleId, @"com.apple.finder");
    XCTAssertTrue(entry.name.length > 0);
}

- (void)testEntryForApplicationRejectsNonApplications {
    XCTAssertNil([OKAppExclusionList entryForApplicationAtURL:[NSURL fileURLWithPath:@"/etc/hosts"]]);
    XCTAssertNil([OKAppExclusionList entryForApplicationAtURL:[NSURL fileURLWithPath:@"/no/such/App.app"]]);
}

@end
