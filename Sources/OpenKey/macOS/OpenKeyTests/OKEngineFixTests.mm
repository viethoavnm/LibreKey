//
//  OKEngineFixTests.mm
//  OpenKeyTests
//
//  One group per engine bug: the keys that used to come out wrong, and the
//  neighbours that must keep working.
//

#import <XCTest/XCTest.h>
#include "OKEngineTypist.h"

#define XCTAssertTyped(keys, expected) \
    XCTAssertEqualObjects(@(OKTypeKeys(keys).text.c_str()), @(expected), @"keys: %s", keys)

@interface OKEngineFixTests : XCTestCase
@end

@implementation OKEngineFixTests

#pragma mark - A w after an automatic horn confirms it

/// Typing "ưo" then i, c, n... makes the engine horn the o by itself. A w the
/// user adds afterwards, to horn that o, used to undo both horns instead.
- (void)testWAfterAutomaticHornKeepsIt {
    XCTAssertTyped("buwoiw ", "bươi ");
    XCTAssertTyped("buwocsw ", "bước ");
    XCTAssertTyped("xuwosngw ", "xướng ");
}

/// A second w after that one is an undo again, like any doubled w.
- (void)testSecondWAfterAutomaticHornStillUndoes {
    XCTAssertTyped("buwoiww ", "buoiw ");
}

/// When the user typed both horns, a further w still undoes them.
- (void)testWAfterManualHornsStillUndoes {
    XCTAssertTyped("buwow ", "bươ ");
    XCTAssertTyped("buwoww ", "buow ");
}

- (void)testUsualHornTypingUnchanged {
    XCTAssertTyped("thuwowng ", "thương ");
    XCTAssertTyped("dduowcj ", "được ");
}

#pragma mark - A lone w that loses its horn is a w again

/// "ee" takes the horn off every vowel of the word, including an ư the w typed
/// on its own. That left a "standalone u" the host turned into U+0000.
- (void)testLoneWThatLosesItsHornSendsNoControlCharacter {
    for (const char *keys : {"were", "weeps", "woof", "sweet", "khwaja"}) {
        OKTypingResult r = OKTypeKeys(keys);
        XCTAssertEqual(r.controlChars, 0, @"keys: %s gave %s", keys, r.text.c_str());
    }
}

- (void)testEnglishWordsWithALoneWComeBackOnRestore {
    OKTypingSettings restore;
    restore.restoreIfWrongSpelling = true;
    for (const char *word : {"were ", "sweet ", "woof ", "weekend "}) {
        XCTAssertEqualObjects(@(OKTypeKeys(word, restore).text.c_str()), @(word));
    }
}

/// Undoing a circumflex on a vowel that already has a tone ("ầ" + a) handed the
/// host the raw letter-with-tone, which is no key code: it became U+0000.
- (void)testUndoingACircumflexUnderAToneSendsNoControlCharacter {
    for (const char *keys : {"aafa", "oorfo", "arafat", "oroonoko"}) {
        OKTypingResult r = OKTypeKeys(keys);
        XCTAssertEqual(r.controlChars, 0, @"keys: %s gave %s", keys, r.text.c_str());
    }
    XCTAssertTyped("aafa", "àa");
}

- (void)testLoneWStillMakesUHorn {
    XCTAssertTyped("w", "ư");
    XCTAssertTyped("tw", "tư");
}

#pragma mark - A lone w not drawn yet is not counted as on screen

/// The ư a lone w makes is not on screen yet when checkGrammar moves the tone
/// onto it, but it was counted in the backspaces: "irwin" typed after "pp "
/// deleted the space in front of it.
- (void)testMovingTheToneOntoALoneWDoesNotDeleteIntoThePreviousWord {
    OKTypingResult r = OKTypeKeys("irwin", OKTypingSettings(), "pp ");
    XCTAssertEqual(r.overDeletes, 0, @"gave %s", r.text.c_str());
    XCTAssertTrue([@(r.text.c_str()) hasPrefix:@"pp "], @"gave %s", r.text.c_str());
}

- (void)testToneMovesOntoALoneW {
    XCTAssertTyped("irw", "iử");
    XCTAssertTyped("twf", "từ");
}

#pragma mark - The macro key follows what the engine wrote (#313)

- (OKTypingResult)type:(const char *)keys macro:(const char *)key content:(const char *)content {
    OKTypingSettings s;
    s.macros = {{key, content}};
    return OKTypeKeys(keys, s);
}

/// After a lone w the macro key held a stale slot instead of the ư, so a macro
/// whose key starts with ư could never fire.
- (void)testMacroKeyStartingWithLoneWFires {
    XCTAssertEqualObjects(@([self type:"wds " macro:"ưds" content:"windows"].text.c_str()), @"windows ");
    XCTAssertEqualObjects(@([self type:"who " macro:"ưho" content:"who"].text.c_str()), @"who ");
}

/// A restore puts the typed key back after the restored letters; the macro key
/// lost one of them ("tesst" gave the key "tst").
- (void)testMacroKeyKeepsEveryLetterAfterARestore {
    XCTAssertEqualObjects(@([self type:"tesst " macro:"test" content:"TEST"].text.c_str()), @"TEST ");
}

- (void)testMacroKeyWithVietnameseLettersStillFires {
    XCTAssertEqualObjects(@([self type:"ddc " macro:"đc" content:"được"].text.c_str()), @"được ");
}

#pragma mark - Backspacing into a word brings its macro key back (#242)

/// "char" is "chả" in Telex. Backspacing over the space and the ả leaves "ch";
/// the macro key was left empty, so typing r made it "r" and fired r -> rồi
/// in the middle of the word.
- (void)testMacroDoesNotFireInsideAWordBackspacedInto {
    XCTAssertEqualObjects(@([self type:"char {BS}{BS}r " macro:"r" content:"rồi"].text.c_str()), @"chr ");
}

/// The word backspaced into is the macro key again.
- (void)testMacroFiresOnAWordBackspacedInto {
    XCTAssertEqualObjects(@([self type:"k {BS}o " macro:"ko" content:"không"].text.c_str()), @"không ");
}

#pragma mark - Macros inside punctuation (#279)

- (NSString *)btw:(const char *)keys {
    return @([self type:keys macro:"btw" content:"by the way"].text.c_str());
}

/// The quote in front went into the macro key, so "btw" never matched.
- (void)testMacroInsideQuotesFires {
    XCTAssertEqualObjects([self btw:"\"btw\""], @"\"by the way\"");
}

/// A closing ) ! or * is a shifted digit, which did not end a macro.
- (void)testMacroBeforeShiftedDigitPunctuationFires {
    XCTAssertEqualObjects([self btw:"(btw)"], @"(by the way)");
    XCTAssertEqualObjects([self btw:"btw!"], @"by the way!");
}

- (void)testMacroOnSpaceUnchanged {
    XCTAssertEqualObjects([self btw:"btw "], @"by the way ");
    XCTAssertEqualObjects([self btw:"xbtw "], @"xbtw ");
}

/// Digits typed without Shift are still part of a word, not an end of it.
- (void)testPlainDigitsDoNotEndAMacro {
    XCTAssertEqualObjects([self btw:"btw2 "], @"btw2 ");
}

#pragma mark - Backspace re-enables marks with spelling off (#145)

/// "aaa" undoes the circumflex and stops marking the word. With spelling off
/// nothing turned marking back on after backspacing past the undo.
- (void)testBackspacePastAnUndoMarksAgainWithSpellingOff {
    OKTypingSettings noSpelling;
    noSpelling.spelling = false;
    XCTAssertEqualObjects(@(OKTypeKeys("thaaa{BS}{BS}aa", noSpelling).text.c_str()), @"thâ");
    XCTAssertEqualObjects(@(OKTypeKeys("aaa{BS}{BS}aa", noSpelling).text.c_str()), @"â");
}

- (void)testBackspacePastAnUndoWithSpellingOnUnchanged {
    XCTAssertTyped("thaaa{BS}{BS}aa", "thâ");
}

#pragma mark - A second w undoes a horn on the second vowel (#216)

/// oa, io and qu + o put the horn or breve on the second vowel. A second w
/// put it on again, so the word stuck at "hoă" and w could not be typed.
- (void)testSecondWUndoesAHornOnTheSecondVowel {
    XCTAssertTyped("hoaww", "hoaw");
    XCTAssertTyped("tioww", "tiow");
    XCTAssertTyped("quoww", "quow");
}

/// After th the first w horns only the o ("thuơ"). The second one horns the u
/// as well, as UniKey does - "thươ" is on the way to "thương" - and a third
/// one undoes.
- (void)testThUoCyclesThroughBothHornsBeforeUndoing {
    XCTAssertTyped("thuoww", "thươ");
    XCTAssertTyped("thuowwng", "thương");
    XCTAssertTyped("thuowww", "thuow");
}

- (void)testSecondWUndoesWithSpellingOff {
    OKTypingSettings noSpelling;
    noSpelling.spelling = false;
    XCTAssertEqualObjects(@(OKTypeKeys("bloatww", noSpelling).text.c_str()), @"bloatw");
}

- (void)testFirstWOnTheseVowelsUnchanged {
    XCTAssertTyped("hoaw", "hoă");
    XCTAssertTyped("tiow", "tiơ");
    XCTAssertTyped("thuow", "thuơ");
    XCTAssertTyped("muaw", "mưa");
    XCTAssertTyped("muaww", "muaw");
}

#pragma mark - huơ, khuơ (#229)

/// After h, kh or no onset, uo + w is uơ while nothing follows, like th.
- (void)testUoWAfterHOrKhIsUHornlessO {
    XCTAssertTyped("huow", "huơ");
    XCTAssertTyped("khuow", "khuơ");
    XCTAssertTyped("uowr", "uở");
    XCTAssertTyped("Huow", "Huơ");
}

/// A final consonant, or i/u, still makes it ươ.
- (void)testUoWBecomesUoHornedOnceTheWordGoesOn {
    XCTAssertTyped("huowng", "hương");
    XCTAssertTyped("huowu", "hươu");
    XCTAssertTyped("khuowu", "khươu");
    XCTAssertTyped("huowi", "hươi");
}

/// Horning the u yourself still gives ươ, and other onsets keep ươ.
- (void)testUoWElsewhereUnchanged {
    XCTAssertTyped("huwow", "hươ");
    XCTAssertTyped("tuow", "tươ");
    XCTAssertTyped("muowi", "mươi");
    XCTAssertTyped("thuowr", "thuở");
    XCTAssertTyped("Thuowr", "Thuở");
}

#pragma mark - Place names ending in k (#134)

/// With spelling off, a final k after a or e takes marks and đ like any
/// other final: Đắk Lắk typed with the marks at the end.
- (void)testFinalKTakesMarksWithSpellingOff {
    OKTypingSettings noSpelling;
    noSpelling.spelling = false;
    XCTAssertEqualObjects(@(OKTypeKeys("dakdws", noSpelling).text.c_str()), @"đắk");
    XCTAssertEqualObjects(@(OKTypeKeys("laksw", noSpelling).text.c_str()), @"lắk");
    XCTAssertEqualObjects(@(OKTypeKeys("ddawsk", noSpelling).text.c_str()), @"đắk");
}

/// With spelling on, k is still not a Vietnamese final.
- (void)testFinalKStillRefusedWithSpellingOn {
    XCTAssertTyped("laksw", "laksw");
}

#pragma mark - Capitalising the first letter of a sentence (#285)

- (NSString *)capitalising:(const char *)keys {
    OKTypingSettings s;
    s.upperCaseFirstChar = true;
    return @(OKTypeKeys(keys, s).text.c_str());
}

- (void)testSentenceEndsCapitaliseTheNextWord {
    XCTAssertEqualObjects([self capitalising:"abc. oo"], @"abc. Ô");
    XCTAssertEqualObjects([self capitalising:"hi! oo"], @"hi! Ô");
    XCTAssertEqualObjects([self capitalising:"hi? oo"], @"hi? Ô");
}

/// > is Shift + the dot key; it used to count as a full stop.
- (void)testGreaterThanDoesNotCapitalise {
    XCTAssertEqualObjects([self capitalising:"a> oo"], @"a> ô");
}

/// Backspacing over the space left the capital pending in the middle of text.
- (void)testBackspaceDropsThePendingCapital {
    XCTAssertEqualObjects([self capitalising:"abc. {BS}oo"], @"abc.ô");
}

/// A click elsewhere is a new place in the text: nothing pending carries over.
- (void)testClickDropsThePendingCapital {
    XCTAssertEqualObjects([self capitalising:"abc. {CLICK}oo"], @"abc. ô");
}

/// Backspacing within the letters the undo wrote keeps the undo.
- (void)testUndoStaysWhileTheWordIsStillUndone {
    OKTypingSettings noSpelling;
    noSpelling.spelling = false;
    XCTAssertEqualObjects(@(OKTypeKeys("aaaa", noSpelling).text.c_str()), @"aaa");
}

#pragma mark - Space after a backspace, two-unit code tables

/// The space kept the delete code of the backspace before it, so the host took
/// it for one more delete: it dropped the length of the last letter and, when
/// that letter took two units (VNI ấ = a + á), sent a backspace through half of
/// it. VNI shows each unit as its own Latin-1 character.
- (void)testSpaceAfterBackspaceKeepsTheLetterBeforeIt {
    OKTypingSettings vni;
    vni.codeTable = 2;
    XCTAssertEqualObjects(@(OKTypeKeys("aasb{BS} ", vni).text.c_str()), @"a\u00E1 ");
    //and the letter still comes off whole afterwards
    XCTAssertEqualObjects(@(OKTypeKeys("aasb{BS} {BS}{BS}", vni).text.c_str()), @"");
}

@end
