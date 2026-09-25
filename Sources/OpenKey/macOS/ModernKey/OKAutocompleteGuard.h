//
//  OKAutocompleteGuard.h
//  LibreKey
//
//  Whether a correction needs the empty character (U+202F) in front of its
//  backspaces. The character is there for inline autocomplete: a suggestion
//  selected after the cursor would eat the first backspace. Everywhere else
//  it is one more event to go wrong, and it is left in the undo history. Only
//  multi-line text asks Accessibility about the selection, since single-line
//  fields (address bars, search boxes) may put a suggestion up at any moment.
//  After OreoKey (inject.rs, MIT) and Goxkey (macos.rs, BSD-3). Pure model.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

//Input: what Accessibility says about the focused field.
@interface OKFocusedField : NSObject

//kAXRoleAttribute, nil when Accessibility did not answer.
@property (nonatomic, copy, readonly, nullable) NSString* role;
//Whether kAXSelectedTextRangeAttribute was read.
@property (nonatomic, readonly) BOOL selectionKnown;
@property (nonatomic, readonly) NSUInteger selectionLength;

- (instancetype)initWithRole:(nullable NSString*)role
              selectionKnown:(BOOL)selectionKnown
             selectionLength:(NSUInteger)selectionLength;

@end

@interface OKAutocompleteGuard : NSObject

//Whether reading the selection can make a difference for a field of this role.
+ (BOOL)shouldAskSelectionForRole:(nullable NSString*)role;

//Output: whether the empty character goes before the backspaces. Asked only
//when the fix autocomplete setting and the typing plan allow it at all.
+ (BOOL)needsEmptyCharacterForField:(OKFocusedField*)field;

@end

NS_ASSUME_NONNULL_END
