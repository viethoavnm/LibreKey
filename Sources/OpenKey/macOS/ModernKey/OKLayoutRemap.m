//
//  OKLayoutRemap.m
//  LibreKey
//

#import "OKLayoutRemap.h"

@implementation OKLayoutRemap {
    NSDictionary<NSNumber*, NSNumber*>* _table;
}

- (instancetype)initWithTable:(NSDictionary<NSNumber*, NSNumber*>*)table {
    self = [super init];
    if (self) {
        _table = [table copy];
    }
    return self;
}

- (BOOL)isIdentity {
    return _table.count == 0;
}

//The US key of each character a US keyboard types without Shift.
static NSDictionary<NSString*, NSNumber*>* USKeyCodes(void) {
    static NSDictionary<NSString*, NSNumber*>* codes;
    static dispatch_once_t once;
    dispatch_once(&once, ^{
        codes = @{@"a": @0, @"s": @1, @"d": @2, @"f": @3, @"h": @4, @"g": @5, @"z": @6, @"x": @7,
                  @"c": @8, @"v": @9, @"b": @11, @"q": @12, @"w": @13, @"e": @14, @"r": @15, @"y": @16,
                  @"t": @17, @"1": @18, @"2": @19, @"3": @20, @"4": @21, @"6": @22, @"5": @23, @"=": @24,
                  @"9": @25, @"7": @26, @"-": @27, @"8": @28, @"0": @29, @"]": @30, @"o": @31, @"u": @32,
                  @"[": @33, @"i": @34, @"p": @35, @"l": @37, @"j": @38, @"'": @39, @"k": @40, @";": @41,
                  @"\\": @42, @",": @43, @"/": @44, @"n": @45, @"m": @46, @".": @47, @"`": @50};
    });
    return codes;
}

//Letters, digits and punctuation: 0-50 on a Mac keyboard, 10 being the key
//ISO boards add. Return, Tab and Space sit among them.
static BOOL IsMainBlockKey(uint16_t keyCode) {
    return keyCode <= 50 && keyCode != 36 && keyCode != 48 && keyCode != 49;
}

+ (OKLayoutRemap*)remapForCharacters:(NSDictionary<NSNumber*, NSString*>*)charactersByKeyCode {
    NSMutableDictionary<NSNumber*, NSNumber*>* table = [NSMutableDictionary dictionary];
    NSDictionary<NSString*, NSNumber*>* usKeyCodes = USKeyCodes();
    [charactersByKeyCode enumerateKeysAndObjectsUsingBlock:^(NSNumber* key, NSString* character, BOOL* stop) {
        uint16_t keyCode = key.unsignedShortValue;
        if (!IsMainBlockKey(keyCode) || character.length != 1)
            return;
        NSNumber* usKeyCode = usKeyCodes[character.lowercaseString];
        if (usKeyCode && usKeyCode.unsignedShortValue != keyCode)
            table[key] = usKeyCode;
    }];
    return [[OKLayoutRemap alloc] initWithTable:table];
}

- (uint16_t)usKeyCodeFor:(uint16_t)keyCode {
    NSNumber* usKeyCode = _table[@(keyCode)];
    return usKeyCode ? usKeyCode.unsignedShortValue : keyCode;
}

@end
