//
//  OKCompoundDeletion.h
//  LibreKey
//
//  How many key presses remove one letter that LibreKey wrote as more than
//  one code unit - VNI Windows (a + a tone byte) or Unicode compound (a base
//  letter + a combining mark). Apps do not agree: Cocoa text deletes and
//  selects the whole letter at once, Chromium selects it whole but deletes
//  one code point per backspace (Blink's BackspaceStateMachine), which left
//  the base letter behind (#182: "conff" gave "coonf"). Pure model.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

//Input: a letter on screen and the app it is in.
@interface OKWrittenLetter : NSObject

//Code units the letter took: 2 for VNI á, or for Unicode compound ấ (â + U+0301).
@property (nonatomic, readonly) NSUInteger units;
//vCodeTable: 0 Unicode, 1 TCVN3, 2 VNI Windows, 3 Unicode compound, 4 CP1258.
@property (nonatomic, readonly) int codeTable;
@property (nonatomic, copy, readonly, nullable) NSString* bundleId;

- (instancetype)initWithUnits:(NSUInteger)units
                    codeTable:(int)codeTable
                     bundleId:(nullable NSString*)bundleId;

@end

//Output: what it takes to remove that letter.
@interface OKLetterRemoval : NSObject

@property (nonatomic, readonly) NSUInteger backspaces;
//Shift+Left presses that select it.
@property (nonatomic, readonly) NSUInteger selectionSteps;

- (instancetype)initWithBackspaces:(NSUInteger)backspaces
                    selectionSteps:(NSUInteger)selectionSteps;

@end

@interface OKCompoundDeletion : NSObject

+ (OKLetterRemoval*)removalOfLetter:(OKWrittenLetter*)letter;

@end

NS_ASSUME_NONNULL_END
