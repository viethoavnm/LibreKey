//
//  CandidateWindowController.m
//  LibreKey
//
//  Created for Simplified Chinese Pinyin integration.
//

#import "CandidateWindowController.h"

@interface CandidateWindowController ()

@property (nonatomic, strong) NSVisualEffectView *visualEffectView;
@property (nonatomic, strong) NSTextField *preeditLabel;
@property (nonatomic, strong) NSStackView *candidatesStackView;
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
    NSRect initialRect = NSMakeRect(100, 100, 320, 64);
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
    _visualEffectView.material = NSVisualEffectMaterialHUDWindow;
    _visualEffectView.state = NSVisualEffectStateActive;
    _visualEffectView.blendingMode = NSVisualEffectBlendingModeBehindWindow;
    _visualEffectView.wantsLayer = YES;
    _visualEffectView.layer.cornerRadius = 8.0;
    _visualEffectView.layer.masksToBounds = YES;
    _visualEffectView.layer.borderWidth = 1.0;
    _visualEffectView.layer.borderColor = [NSColor colorWithWhite:1.0 alpha:0.15].CGColor;
    [contentView addSubview:_visualEffectView];

    // Main vertical layout
    NSStackView *mainStack = [[NSStackView alloc] initWithFrame:NSInsetRect(contentView.bounds, 10, 8)];
    mainStack.orientation = NSUserInterfaceLayoutOrientationVertical;
    mainStack.alignment = NSLayoutAttributeLeading;
    mainStack.spacing = 4.0;
    mainStack.autoresizingMask = NSViewWidthSizable | NSViewHeightSizable;
    [_visualEffectView addSubview:mainStack];

    // Preedit Label
    _preeditLabel = [NSTextField labelWithString:@""];
    _preeditLabel.font = [NSFont monospacedSystemFontOfSize:13 weight:NSFontWeightMedium];
    _preeditLabel.textColor = [NSColor systemBlueColor];
    [mainStack addArrangedSubview:_preeditLabel];

    // Candidates horizontal stack
    _candidatesStackView = [[NSStackView alloc] init];
    _candidatesStackView.orientation = NSUserInterfaceLayoutOrientationHorizontal;
    _candidatesStackView.alignment = NSLayoutAttributeCenterY;
    _candidatesStackView.spacing = 10.0;
    [mainStack addArrangedSubview:_candidatesStackView];

    // Page indicator
    _pageLabel = [NSTextField labelWithString:@""];
    _pageLabel.font = [NSFont systemFontOfSize:11 weight:NSFontWeightRegular];
    _pageLabel.textColor = [NSColor secondaryLabelColor];
    [_candidatesStackView addArrangedSubview:_pageLabel];
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

        self.preeditLabel.stringValue = preedit ?: @"";

        // Remove old candidate views except pageLabel
        NSArray *subviews = [self.candidatesStackView.arrangedSubviews copy];
        for (NSView *v in subviews) {
            if (v != self.pageLabel) {
                [self.candidatesStackView removeArrangedSubview:v];
                [v removeFromSuperview];
            }
        }

        // Add new candidates
        for (NSInteger i = 0; i < candidates.count; i++) {
            NSString *candText = candidates[i];
            NSString *itemText = [NSString stringWithFormat:@"%ld. %@", (long)(i + 1), candText];

            NSTextField *label = [NSTextField labelWithString:itemText];
            if (i == highlightIndex) {
                label.font = [NSFont systemFontOfSize:14 weight:NSFontWeightBold];
                label.textColor = [NSColor whiteColor];
                label.wantsLayer = YES;
                label.layer.backgroundColor = [NSColor colorWithRed:0.0 green:0.48 blue:1.0 alpha:0.5].CGColor;
                label.layer.cornerRadius = 4.0;
            } else {
                label.font = [NSFont systemFontOfSize:14 weight:NSFontWeightRegular];
                label.textColor = [NSColor colorWithWhite:0.9 alpha:1.0];
            }
            // Insert before pageLabel
            [self.candidatesStackView insertArrangedSubview:label atIndex:i];
        }

        if (pageNo > 0 || !isLastPage) {
            self.pageLabel.stringValue = [NSString stringWithFormat:@"[%ld]", (long)(pageNo + 1)];
            self.pageLabel.hidden = NO;
        } else {
            self.pageLabel.hidden = YES;
        }

        // Compute needed size
        [self.candidatesStackView layoutSubtreeIfNeeded];
        NSSize targetSize = [self.window.contentView fittingSize];
        CGFloat width = MAX(targetSize.width + 24, 180.0);
        CGFloat height = MAX(targetSize.height + 16, 56.0);

        NSRect frame = self.window.frame;
        frame.size = NSMakeSize(width, height);
        [self.window setFrame:frame display:YES];

        [self updatePositionNearCaret];
        [self.window orderFrontRegardless];
    });
}

- (void)updatePositionNearCaret {
    NSRect targetRect = NSZeroRect;
    BOOL foundCaret = NO;

    AXUIElementRef systemWide = AXUIElementCreateSystemWide();
    if (systemWide) {
        AXUIElementRef focusedElement = NULL;
        if (AXUIElementCopyAttributeValue(systemWide, kAXFocusedUIElementAttribute, (CFTypeRef *)&focusedElement) == kAXErrorSuccess && focusedElement) {
            AXValueRef rangeValue = NULL;
            if (AXUIElementCopyAttributeValue(focusedElement, kAXSelectedTextRangeAttribute, (CFTypeRef *)&rangeValue) == kAXErrorSuccess && rangeValue) {
                CFRange range;
                if (AXValueGetValue(rangeValue, kAXValueCFRangeType, &range)) {
                    AXValueRef boundsValue = NULL;
                    if (AXUIElementCopyParameterizedAttributeValue(focusedElement, kAXBoundsForRangeParameterizedAttribute, rangeValue, (CFTypeRef *)&boundsValue) == kAXErrorSuccess && boundsValue) {
                        CGRect rect;
                        if (AXValueGetValue(boundsValue, kAXValueCGRectType, &rect)) {
                            targetRect = NSRectFromCGRect(rect);
                            foundCaret = YES;
                        }
                        CFRelease(boundsValue);
                    }
                }
                CFRelease(rangeValue);
            }
            CFRelease(focusedElement);
        }
        CFRelease(systemWide);
    }

    NSRect windowFrame = self.window.frame;
    NSScreen *screen = [NSScreen mainScreen];
    NSRect screenFrame = screen ? screen.visibleFrame : NSMakeRect(0, 0, 1440, 900);

    NSPoint origin;
    if (foundCaret && targetRect.size.width >= 0 && targetRect.size.height >= 0 && targetRect.origin.y > 0) {
        // macOS AX coordinates: (0,0) is top-left, Cocoa coordinates: (0,0) is bottom-left
        CGFloat cocoaY = screenFrame.size.height + screenFrame.origin.y - targetRect.origin.y;
        origin.x = targetRect.origin.x;
        origin.y = cocoaY - windowFrame.size.height - 4;
        if (origin.y < screenFrame.origin.y) {
            origin.y = cocoaY + targetRect.size.height + 4;
        }
    } else {
        // Fallback to mouse location
        NSPoint mouseLoc = [NSEvent mouseLocation];
        origin.x = mouseLoc.x + 12;
        origin.y = mouseLoc.y - windowFrame.size.height - 12;
    }

    // Clamp inside screen bounds
    if (origin.x + windowFrame.size.width > NSMaxX(screenFrame)) {
        origin.x = NSMaxX(screenFrame) - windowFrame.size.width - 8;
    }
    if (origin.x < NSMinX(screenFrame)) {
        origin.x = NSMinX(screenFrame) + 8;
    }
    if (origin.y < NSMinY(screenFrame)) {
        origin.y = NSMinY(screenFrame) + 8;
    }
    if (origin.y + windowFrame.size.height > NSMaxY(screenFrame)) {
        origin.y = NSMaxY(screenFrame) - windowFrame.size.height - 8;
    }

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
