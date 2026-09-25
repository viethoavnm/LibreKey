//
//  OKAutocompleteGuardTests.m
//  OpenKeyTests
//

#import <XCTest/XCTest.h>
#import "OKAutocompleteGuard.h"

@interface OKAutocompleteGuardTests : XCTestCase
@end

@implementation OKAutocompleteGuardTests

- (BOOL)needsForRole:(NSString *)role known:(BOOL)known length:(NSUInteger)length {
    OKFocusedField *field = [[OKFocusedField alloc] initWithRole:role selectionKnown:known selectionLength:length];
    return [OKAutocompleteGuard needsEmptyCharacterForField:field];
}

#pragma mark - shouldAskSelectionForRole

- (void)testMultiLineTextIsWorthAsking {
    XCTAssertTrue([OKAutocompleteGuard shouldAskSelectionForRole:@"AXTextArea"]);
}

/// Address bars and search boxes may put a suggestion up after the check.
- (void)testSingleLineFieldsAreNotAsked {
    XCTAssertFalse([OKAutocompleteGuard shouldAskSelectionForRole:@"AXTextField"]);
    XCTAssertFalse([OKAutocompleteGuard shouldAskSelectionForRole:@"AXComboBox"]);
    XCTAssertFalse([OKAutocompleteGuard shouldAskSelectionForRole:@"AXSearchField"]);
    XCTAssertFalse([OKAutocompleteGuard shouldAskSelectionForRole:nil]);
}

#pragma mark - needsEmptyCharacterForField

/// TextEdit, Notes, Mail: nothing selected, nothing to eat the backspace.
- (void)testMultiLineTextWithNothingSelectedGoesWithout {
    XCTAssertFalse([self needsForRole:@"AXTextArea" known:YES length:0]);
}

/// Something selected after the cursor: the first backspace would take it.
- (void)testSelectionKeepsTheEmptyCharacter {
    XCTAssertTrue([self needsForRole:@"AXTextArea" known:YES length:4]);
}

/// When Accessibility does not answer, keep doing what always worked.
- (void)testUnknownSelectionKeepsTheEmptyCharacter {
    XCTAssertTrue([self needsForRole:@"AXTextArea" known:NO length:0]);
}

- (void)testSingleLineFieldsKeepTheEmptyCharacter {
    XCTAssertTrue([self needsForRole:@"AXTextField" known:YES length:0]);
    XCTAssertTrue([self needsForRole:@"AXComboBox" known:YES length:0]);
}

- (void)testUnknownRoleKeepsTheEmptyCharacter {
    XCTAssertTrue([self needsForRole:nil known:NO length:0]);
    XCTAssertTrue([self needsForRole:nil known:YES length:0]);
}

@end
