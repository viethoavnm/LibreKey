//
//  CandidateWindowController.m
//  LibreKey
//
//  Created for Simplified Chinese Pinyin integration.
//

#import "CandidateWindowController.h"
#import <ApplicationServices/ApplicationServices.h>

@interface CandidateWindowController ()

@property (nonatomic, strong) NSVisualEffectView *visualEffectView;
@property (nonatomic, strong) NSTextField *preeditLabel;
@property (nonatomic, strong) NSBox *separatorBox;
@property (nonatomic, strong) NSView *candidatesContainer;
@property (nonatomic, strong) NSTextField *pageLabel;

@end

@implementation CandidateWindowController

+ (instancetype)sharedController {
    static CandidateWindowController *s_instance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        s_instance = [[CandidateWindowController alloc] init];
    });
    return s_instance;
}

- (instancetype)init {
    NSRect initialRect = NSMakeRect(100, 100, 320, 68);
    NSPanel *panel = [[NSPanel alloc] initWithContentRect:initialRect
                                                styleMask:NSWindowStyleMaskNonactivatingPanel | NSWindowStyleMaskBorderless
                                                  backing:NSBackingStoreBuffered
                                                    defer:NO];
    [panel setLevel:NSPopUpMenuWindowLevel];
    [panel setOpaque:NO];
    [panel setBackgroundColor:[NSColor clearColor]];
    [panel setHasShadow:YES];
    [panel setHidesOnDeactivate:NO];
    [panel setIgnoresMouseEvents:NO];

    self = [super initWithWindow:panel];
    if (self) {
        [self setupUI];
    }
    return self;
}

- (void)setupUI {
    NSView *contentView = self.window.contentView;
    contentView.wantsLayer = YES;

    _visualEffectView = [[NSVisualEffectView alloc] initWithFrame:contentView.bounds];
    _visualEffectView.autoresizingMask = NSViewWidthSizable | NSViewHeightSizable;
    _visualEffectView.material = NSVisualEffectMaterialPopover;
    _visualEffectView.state = NSVisualEffectStateActive;
    _visualEffectView.blendingMode = NSVisualEffectBlendingModeBehindWindow;
    _visualEffectView.wantsLayer = YES;
    _visualEffectView.layer.cornerRadius = 10.0;
    _visualEffectView.layer.masksToBounds = YES;
    _visualEffectView.layer.borderWidth = 0.5;
    _visualEffectView.layer.borderColor = [NSColor colorWithWhite:1.0 alpha:0.2].CGColor;
    [contentView addSubview:_visualEffectView];

    // Preedit Label (Latin text)
    _preeditLabel = [NSTextField labelWithString:@""];
    _preeditLabel.font = [NSFont systemFontOfSize:14 weight:NSFontWeightSemibold];
    _preeditLabel.textColor = [NSColor systemBlueColor];
    _preeditLabel.lineBreakMode = NSLineBreakByTruncatingTail;
    [_visualEffectView addSubview:_preeditLabel];

    // Separator line
    _separatorBox = [[NSBox alloc] initWithFrame:NSZeroRect];
    _separatorBox.boxType = NSBoxSeparator;
    [_visualEffectView addSubview:_separatorBox];

    // Candidates container
    _candidatesContainer = [[NSView alloc] initWithFrame:NSZeroRect];
    [_visualEffectView addSubview:_candidatesContainer];

    // Page indicator
    _pageLabel = [NSTextField labelWithString:@""];
    _pageLabel.font = [NSFont systemFontOfSize:11 weight:NSFontWeightRegular];
    _pageLabel.textColor = [NSColor secondaryLabelColor];
    [_candidatesContainer addSubview:_pageLabel];
}

- (void)updateWithPreedit:(NSString *)preedit
               candidates:(NSArray<NSString *> *)candidates
                highlight:(NSInteger)highlightIndex
                   pageNo:(NSInteger)pageNo
                 pageSize:(NSInteger)pageSize
               isLastPage:(BOOL)isLastPage {
    dispatch_async(dispatch_get_main_queue(), ^{
        if (preedit.length == 0 && candidates.count == 0) {
            [self hideWindow];
            return;
        }

        BOOL hasPreedit = (preedit.length > 0);
        BOOL hasCandidates = (candidates.count > 0);

        self.preeditLabel.stringValue = preedit ?: @"";
        self.preeditLabel.hidden = !hasPreedit;

        // Clear existing candidate subviews (except pageLabel)
        NSArray *subviews = [self.candidatesContainer.subviews copy];
        for (NSView *v in subviews) {
            if (v != self.pageLabel) {
                [v removeFromSuperview];
            }
        }

        // Fonts matching macOS Apple Pinyin style
        NSFont *preeditFont = [NSFont systemFontOfSize:14 weight:NSFontWeightSemibold];
        NSFont *numFont = [NSFont systemFontOfSize:12 weight:NSFontWeightRegular];
        NSFont *numHighlightFont = [NSFont systemFontOfSize:12 weight:NSFontWeightMedium];
        NSFont *candFont = [NSFont systemFontOfSize:15 weight:NSFontWeightRegular];
        NSFont *candHighlightFont = [NSFont systemFontOfSize:15 weight:NSFontWeightMedium];
        NSFont *pageFont = [NSFont systemFontOfSize:11 weight:NSFontWeightRegular];

        CGFloat candX = 0.0;
        const CGFloat candRowHeight = 26.0;

        for (NSInteger i = 0; i < candidates.count; i++) {
            NSString *candText = candidates[i];
            BOOL isHighlighted = (i == highlightIndex);

            NSString *numStr = [NSString stringWithFormat:@"%ld.", (long)(i + 1)];
            NSDictionary *numAttrs = @{NSFontAttributeName: isHighlighted ? numHighlightFont : numFont};
            NSSize numSize = [numStr sizeWithAttributes:numAttrs];

            NSDictionary *candAttrs = @{NSFontAttributeName: isHighlighted ? candHighlightFont : candFont};
            NSSize candSize = [candText sizeWithAttributes:candAttrs];

            CGFloat pillPadH = isHighlighted ? 7.0 : 4.0;
            CGFloat itemWidth = pillPadH + numSize.width + 4.0 + candSize.width + pillPadH;

            // Container pill view
            NSView *itemView = [[NSView alloc] initWithFrame:NSMakeRect(candX, 0, itemWidth, candRowHeight)];
            itemView.wantsLayer = YES;
            if (isHighlighted) {
                itemView.layer.backgroundColor = [NSColor controlAccentColor].CGColor;
                itemView.layer.cornerRadius = 5.0;
            }

            // Number label
            CGFloat numY = (candRowHeight - numSize.height) / 2.0;
            NSTextField *numLabel = [[NSTextField alloc] initWithFrame:NSMakeRect(pillPadH, numY, numSize.width, numSize.height)];
            numLabel.stringValue = numStr;
            numLabel.font = isHighlighted ? numHighlightFont : numFont;
            numLabel.textColor = isHighlighted ? [NSColor colorWithWhite:1.0 alpha:0.85] : [NSColor secondaryLabelColor];
            numLabel.editable = NO;
            numLabel.bordered = NO;
            numLabel.drawsBackground = NO;
            [itemView addSubview:numLabel];

            // Candidate Chinese text label
            CGFloat candY = (candRowHeight - candSize.height) / 2.0;
            NSTextField *candLabel = [[NSTextField alloc] initWithFrame:NSMakeRect(pillPadH + numSize.width + 4.0, candY, candSize.width, candSize.height)];
            candLabel.stringValue = candText;
            candLabel.font = isHighlighted ? candHighlightFont : candFont;
            candLabel.textColor = isHighlighted ? [NSColor whiteColor] : [NSColor labelColor];
            candLabel.editable = NO;
            candLabel.bordered = NO;
            candLabel.drawsBackground = NO;
            [itemView addSubview:candLabel];

            [self.candidatesContainer addSubview:itemView];
            candX += itemWidth + 10.0;
        }

        // Page indicator
        if (pageNo > 0 || !isLastPage) {
            NSString *pageStr = [NSString stringWithFormat:@"‹ %ld ›", (long)(pageNo + 1)];
            self.pageLabel.stringValue = pageStr;
            NSSize pageSize = [pageStr sizeWithAttributes:@{NSFontAttributeName: pageFont}];
            CGFloat pageY = (candRowHeight - pageSize.height) / 2.0;
            self.pageLabel.frame = NSMakeRect(candX + 2.0, pageY, pageSize.width, pageSize.height);
            self.pageLabel.hidden = NO;
            candX += pageSize.width + 4.0;
        } else {
            self.pageLabel.hidden = YES;
        }

        CGFloat candRowWidth = candX;

        // Measure preedit width
        NSSize preeditSize = hasPreedit ? [preedit sizeWithAttributes:@{NSFontAttributeName: preeditFont}] : NSZeroSize;
        CGFloat contentWidth = MAX(preeditSize.width, candRowWidth);
        const CGFloat padH = 12.0;
        CGFloat windowWidth = MAX(contentWidth + padH * 2.0, 160.0);

        // Layout heights
        const CGFloat padV = 8.0;
        const CGFloat preeditH = hasPreedit ? 18.0 : 0.0;
        const CGFloat separatorH = (hasPreedit && hasCandidates) ? 1.0 : 0.0;
        const CGFloat spacing = (hasPreedit && hasCandidates) ? 6.0 : 0.0;
        const CGFloat candH = hasCandidates ? candRowHeight : 0.0;

        CGFloat windowHeight;
        if (hasPreedit && hasCandidates) {
            windowHeight = padV + candH + spacing + separatorH + spacing + preeditH + padV;
        } else if (hasCandidates) {
            windowHeight = padV + candH + padV;
        } else {
            windowHeight = padV + preeditH + padV;
        }

        // Position subviews inside VisualEffectView (bottom-up coordinates)
        CGFloat currentY = padV;
        if (hasCandidates) {
            self.candidatesContainer.frame = NSMakeRect(padH, currentY, candRowWidth, candH);
            self.candidatesContainer.hidden = NO;
            currentY += candH + spacing;
        } else {
            self.candidatesContainer.hidden = YES;
        }

        if (hasPreedit && hasCandidates) {
            self.separatorBox.frame = NSMakeRect(padH, currentY, windowWidth - padH * 2.0, 1.0);
            self.separatorBox.hidden = NO;
            currentY += 1.0 + spacing;
        } else {
            self.separatorBox.hidden = YES;
        }

        if (hasPreedit) {
            self.preeditLabel.frame = NSMakeRect(padH, currentY, windowWidth - padH * 2.0, preeditH);
            self.preeditLabel.hidden = NO;
        } else {
            self.preeditLabel.hidden = YES;
        }

        // Position window near caret
        NSSize winSize = NSMakeSize(windowWidth, windowHeight);
        NSPoint origin = [self calculateCaretPositionForSize:winSize];
        [self.window setFrame:NSMakeRect(origin.x, origin.y, winSize.width, winSize.height) display:YES];
        [self.window orderFrontRegardless];
    });
}

- (NSPoint)calculateCaretPositionForSize:(NSSize)windowSize {
    NSRect targetRect = NSZeroRect;
    BOOL foundCaret = NO;

    // 1. Query frontmost application directly
    NSRunningApplication *frontApp = [[NSWorkspace sharedWorkspace] frontmostApplication];
    pid_t pid = frontApp ? frontApp.processIdentifier : 0;

    if (pid > 0) {
        AXUIElementRef appElement = AXUIElementCreateApplication(pid);
        if (appElement) {
            AXUIElementSetMessagingTimeout(appElement, 0.15);
            AXUIElementRef focusedElement = NULL;
            if (AXUIElementCopyAttributeValue(appElement, kAXFocusedUIElementAttribute, (CFTypeRef *)&focusedElement) == kAXErrorSuccess && focusedElement) {
                AXValueRef rangeValue = NULL;
                if (AXUIElementCopyAttributeValue(focusedElement, kAXSelectedTextRangeAttribute, (CFTypeRef *)&rangeValue) == kAXErrorSuccess && rangeValue) {
                    CFRange range;
                    if (AXValueGetValue(rangeValue, kAXValueCFRangeType, &range)) {
                        // Attempt bounds for current range
                        AXValueRef boundsValue = NULL;
                        if (AXUIElementCopyParameterizedAttributeValue(focusedElement, kAXBoundsForRangeParameterizedAttribute, rangeValue, (CFTypeRef *)&boundsValue) == kAXErrorSuccess && boundsValue) {
                            CGRect rect;
                            if (AXValueGetValue(boundsValue, kAXValueCGRectType, &rect)) {
                                if (rect.size.height > 0) {
                                    targetRect = NSRectFromCGRect(rect);
                                    foundCaret = YES;
                                }
                            }
                            CFRelease(boundsValue);
                        }

                        // If range has length 0 and bounds was empty, query previous character
                        if (!foundCaret && range.location > 0) {
                            CFRange prevRange = CFRangeMake(range.location - 1, 1);
                            AXValueRef prevRangeValue = AXValueCreate(kAXValueCFRangeType, &prevRange);
                            if (prevRangeValue) {
                                AXValueRef prevBoundsValue = NULL;
                                if (AXUIElementCopyParameterizedAttributeValue(focusedElement, kAXBoundsForRangeParameterizedAttribute, prevRangeValue, (CFTypeRef *)&prevBoundsValue) == kAXErrorSuccess && prevBoundsValue) {
                                    CGRect rect;
                                    if (AXValueGetValue(prevBoundsValue, kAXValueCGRectType, &rect)) {
                                        if (rect.size.height > 0) {
                                            targetRect = NSMakeRect(rect.origin.x + rect.size.width, rect.origin.y, 0, rect.size.height);
                                            foundCaret = YES;
                                        }
                                    }
                                    CFRelease(prevBoundsValue);
                                }
                                CFRelease(prevRangeValue);
                            }
                        }
                    }
                    CFRelease(rangeValue);
                }

                // If text range bounds failed, query element position and size as fallback
                if (!foundCaret) {
                    AXValueRef posValue = NULL;
                    AXValueRef sizeValue = NULL;
                    CGPoint pos = CGPointZero;
                    CGSize size = CGSizeZero;
                    if (AXUIElementCopyAttributeValue(focusedElement, kAXPositionAttribute, (CFTypeRef *)&posValue) == kAXErrorSuccess && posValue) {
                        AXValueGetValue(posValue, kAXValueCGPointType, &pos);
                        CFRelease(posValue);
                        if (AXUIElementCopyAttributeValue(focusedElement, kAXSizeAttribute, (CFTypeRef *)&sizeValue) == kAXErrorSuccess && sizeValue) {
                            AXValueGetValue(sizeValue, kAXValueCGSizeType, &size);
                            CFRelease(sizeValue);
                            if (size.height > 0) {
                                targetRect = NSMakeRect(pos.x, pos.y, size.width, size.height);
                                foundCaret = YES;
                            }
                        }
                    }
                }

                CFRelease(focusedElement);
            }
            CFRelease(appElement);
        }
    }

    // 2. Fallback query to systemWide element
    if (!foundCaret) {
        AXUIElementRef systemWide = AXUIElementCreateSystemWide();
        if (systemWide) {
            AXUIElementSetMessagingTimeout(systemWide, 0.1);
            AXUIElementRef focusedElement = NULL;
            if (AXUIElementCopyAttributeValue(systemWide, kAXFocusedUIElementAttribute, (CFTypeRef *)&focusedElement) == kAXErrorSuccess && focusedElement) {
                AXValueRef rangeValue = NULL;
                if (AXUIElementCopyAttributeValue(focusedElement, kAXSelectedTextRangeAttribute, (CFTypeRef *)&rangeValue) == kAXErrorSuccess && rangeValue) {
                    AXValueRef boundsValue = NULL;
                    if (AXUIElementCopyParameterizedAttributeValue(focusedElement, kAXBoundsForRangeParameterizedAttribute, rangeValue, (CFTypeRef *)&boundsValue) == kAXErrorSuccess && boundsValue) {
                        CGRect rect;
                        if (AXValueGetValue(boundsValue, kAXValueCGRectType, &rect)) {
                            if (rect.size.height > 0) {
                                targetRect = NSRectFromCGRect(rect);
                                foundCaret = YES;
                            }
                        }
                        CFRelease(boundsValue);
                    }
                    CFRelease(rangeValue);
                }
                CFRelease(focusedElement);
            }
            CFRelease(systemWide);
        }
    }

    // Convert Quartz coordinates to Cocoa coordinates
    NSScreen *primaryScreen = [NSScreen screens].firstObject;
    CGFloat primaryHeight = primaryScreen ? primaryScreen.frame.size.height : 900.0;

    NSPoint origin;
    if (foundCaret && targetRect.origin.y > 0) {
        CGFloat caretBottomCocoa = primaryHeight - (targetRect.origin.y + targetRect.size.height);
        CGFloat caretTopCocoa = primaryHeight - targetRect.origin.y;

        origin.x = targetRect.origin.x;
        origin.y = caretBottomCocoa - windowSize.height - 4.0;

        // Target screen visible frame
        NSScreen *targetScreen = nil;
        for (NSScreen *s in [NSScreen screens]) {
            if (NSPointInRect(NSMakePoint(origin.x, caretBottomCocoa), s.frame)) {
                targetScreen = s;
                break;
            }
        }
        if (!targetScreen) targetScreen = [NSScreen mainScreen];
        NSRect visibleFrame = targetScreen ? targetScreen.visibleFrame : NSMakeRect(0, 0, 1440, 900);

        // Flip above caret if it goes below visible screen area
        if (origin.y < NSMinY(visibleFrame)) {
            origin.y = caretTopCocoa + 4.0;
        }

        // Clamp horizontally within visible frame
        if (origin.x + windowSize.width > NSMaxX(visibleFrame) - 8.0) {
            origin.x = NSMaxX(visibleFrame) - windowSize.width - 8.0;
        }
        if (origin.x < NSMinX(visibleFrame) + 8.0) {
            origin.x = NSMinX(visibleFrame) + 8.0;
        }
    } else {
        // Fallback to mouse position
        NSPoint mouseLoc = [NSEvent mouseLocation];
        NSScreen *targetScreen = [NSScreen mainScreen];
        NSRect visibleFrame = targetScreen ? targetScreen.visibleFrame : NSMakeRect(0, 0, 1440, 900);

        origin.x = mouseLoc.x + 12.0;
        origin.y = mouseLoc.y - windowSize.height - 12.0;

        if (origin.y < NSMinY(visibleFrame)) {
            origin.y = mouseLoc.y + 16.0;
        }
        if (origin.x + windowSize.width > NSMaxX(visibleFrame) - 8.0) {
            origin.x = NSMaxX(visibleFrame) - windowSize.width - 8.0;
        }
        if (origin.x < NSMinX(visibleFrame) + 8.0) {
            origin.x = NSMinX(visibleFrame) + 8.0;
        }
    }

    return origin;
}

- (void)updatePositionNearCaret {
    NSPoint origin = [self calculateCaretPositionForSize:self.window.frame.size];
    [self.window setFrameOrigin:origin];
}

- (void)hideWindow {
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.window orderOut:nil];
    });
}

- (BOOL)isWindowVisible {
    return self.window.isVisible;
}

@end
