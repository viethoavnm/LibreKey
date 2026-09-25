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

+ (OKLetterRemoval*)removalOfLetter:(OKWrittenLetter*)letter {
    return [[OKLetterRemoval alloc] initWithBackspaces:0 selectionSteps:0];
}

@end
