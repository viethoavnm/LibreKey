//
//  OKAutocompleteGuard.m
//  LibreKey
//

#import "OKAutocompleteGuard.h"

@implementation OKFocusedField

- (instancetype)initWithRole:(NSString*)role
              selectionKnown:(BOOL)selectionKnown
             selectionLength:(NSUInteger)selectionLength {
    self = [super init];
    if (self) {
        _role = [role copy];
        _selectionKnown = selectionKnown;
        _selectionLength = selectionLength;
    }
    return self;
}

@end

@implementation OKAutocompleteGuard

//Multi-line text: documents, notes, mail bodies, code. Autocomplete there
//shows as ghost text or a list, not as a selection put up behind the cursor.
static NSString* const kMultiLineRole = @"AXTextArea";

+ (BOOL)shouldAskSelectionForRole:(NSString*)role {
    return [role isEqualToString:kMultiLineRole];
}

+ (BOOL)needsEmptyCharacterForField:(OKFocusedField*)field {
    if (![self shouldAskSelectionForRole:field.role])
        return YES;
    if (!field.selectionKnown)
        return YES;
    return field.selectionLength > 0;
}

@end
