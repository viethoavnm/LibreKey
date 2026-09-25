//
//  OKCompoundDeletion.m
//  LibreKey
//

#import "OKCompoundDeletion.h"

@implementation OKWrittenLetter

- (instancetype)initWithUnits:(NSUInteger)units
                    codeTable:(int)codeTable
                     bundleId:(NSString*)bundleId {
    self = [super init];
    if (self) {
        _units = units;
        _codeTable = codeTable;
        _bundleId = [bundleId copy];
    }
    return self;
}

@end

@implementation OKLetterRemoval

- (instancetype)initWithBackspaces:(NSUInteger)backspaces
                    selectionSteps:(NSUInteger)selectionSteps {
    self = [super init];
    if (self) {
        _backspaces = backspaces;
        _selectionSteps = selectionSteps;
    }
    return self;
}

@end

@implementation OKCompoundDeletion

//Whether bundleId is `known` or one of its channels (known.beta, known.Dev...).
static BOOL MatchesApp(NSString* bundleId, NSString* known) {
    NSString* lower = bundleId.lowercaseString;
    NSString* knownLower = known.lowercaseString;
    return [lower isEqualToString:knownLower] || [lower hasPrefix:[knownLower stringByAppendingString:@"."]];
}

//Cocoa text: a base letter and its combining marks are one character.
static BOOL IsCocoaApp(NSString* bundleId) {
    return [bundleId.lowercaseString hasPrefix:@"com.apple."];
}

//Chromium: Shift+Left moves by grapheme, a backspace by code point.
static BOOL IsChromiumApp(NSString* bundleId) {
    for (NSString* known in @[@"com.google.Chrome", @"com.brave.Browser",
                              @"com.microsoft.edgemac", @"com.microsoft.Edge"]) {
        if (MatchesApp(bundleId, known))
            return YES;
    }
    return NO;
}

+ (OKLetterRemoval*)removalOfLetter:(OKWrittenLetter*)letter {
    NSUInteger units = letter.units > 0 ? letter.units : 1;
    //only a Unicode compound letter is one character made of several units
    if (units == 1 || letter.codeTable != 3 || letter.bundleId == nil)
        return [[OKLetterRemoval alloc] initWithBackspaces:units selectionSteps:units];
    if (IsCocoaApp(letter.bundleId))
        return [[OKLetterRemoval alloc] initWithBackspaces:1 selectionSteps:1];
    if (IsChromiumApp(letter.bundleId))
        return [[OKLetterRemoval alloc] initWithBackspaces:units selectionSteps:1];
    return [[OKLetterRemoval alloc] initWithBackspaces:units selectionSteps:units];
}

@end
