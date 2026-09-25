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
    return NO;
}

+ (OKLayoutRemap*)remapForCharacters:(NSDictionary<NSNumber*, NSString*>*)charactersByKeyCode {
    return [[OKLayoutRemap alloc] initWithTable:@{}];
}

- (uint16_t)usKeyCodeFor:(uint16_t)keyCode {
    return 0;
}

@end
