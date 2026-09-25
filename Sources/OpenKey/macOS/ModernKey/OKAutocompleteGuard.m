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

+ (BOOL)shouldAskSelectionForRole:(NSString*)role {
    return NO;
}

+ (BOOL)needsEmptyCharacterForField:(OKFocusedField*)field {
    return NO;
}

@end
