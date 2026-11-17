//
//  CandidateWindowController.h
//  LibreKey
//
//  Created for Simplified Chinese Pinyin integration.
//

#import <Cocoa/Cocoa.h>

@interface CandidateWindowController : NSWindowController

+ (instancetype)sharedController;

- (void)updateWithPreedit:(NSString *)preedit
               candidates:(NSArray<NSString *> *)candidates
                highlight:(NSInteger)highlightIndex
                   pageNo:(NSInteger)pageNo
                 pageSize:(NSInteger)pageSize
               isLastPage:(BOOL)isLastPage;

- (void)hideWindow;
- (BOOL)isWindowVisible;
- (void)updatePositionNearCaret;

@end
