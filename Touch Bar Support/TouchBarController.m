//
//  TouchBarController.m
//  Flycut
//
//  Created by Chris Galzerano on 12/31/18.
//

#import "TouchBarController.h"
#import "TouchBar.h"
#import "AppController.h"
#import "NSButton+Property.h"

static const NSTouchBarItemIdentifier kjumpCutIdentifier = @"com.jumpcut.jumpcut";
static const NSTouchBarItemIdentifier kClipItemIdentifier = @"com.jumpcut.clipItem";

@interface TouchBarController () <NSTouchBarDelegate>

@property (nonatomic) NSTouchBar *touchBar;

@end

@implementation TouchBarController {
    AppController *controller;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        controller = (AppController*)[NSApp delegate];
        DFRSystemModalShowsCloseBoxWhenFrontMost(YES);
        NSCustomTouchBarItem *item = [[NSCustomTouchBarItem alloc] initWithIdentifier:kjumpCutIdentifier];
        item.view = [NSButton buttonWithTitle:@"✂" target:self action:@selector(expandBar:)];
        [NSTouchBarItem addSystemTrayItem:item];
        DFRElementSetControlStripPresenceForIdentifier(kjumpCutIdentifier, YES);
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(clipboardUpdated) name:@"ClipboardUpdatedTouchBar" object:nil];
    }
    return self;
}

- (void)clipboardUpdated {
    NSLog(@"clipboardUpdated");
    dispatch_async(dispatch_get_main_queue(), ^{
        if (@available(macOS 10.14, *)) {
            [NSTouchBar dismissSystemModalTouchBar:self.touchBar];
        }
        else {
            [NSTouchBar dismissSystemModalFunctionBar:self.touchBar];
        }
        dispatch_async(dispatch_get_main_queue(), ^{
            [self expandBar:nil];
        });
    });
    
    
}

- (NSCustomTouchBarItem*)pasteboardItem {
    //https://stackoverflow.com/questions/42123495/touch-bar-how-to-add-a-scrollable-list-of-buttons
    
    NSScrollView *scrollView = [[NSScrollView alloc] initWithFrame:CGRectMake(0, 0, 400, 30)];
    
    NSMutableDictionary *constraintViews = [NSMutableDictionary dictionary];
    NSView *documentView = [[NSView alloc] initWithFrame:NSZeroRect];
    
    NSString *layoutFormat = @"H:|-8-";
    NSSize size = NSMakeSize(8, 30);
    
    for (int i = 0; i < [self clipboardItems].count; i++) {
        NSString *objectName = [NSString stringWithFormat:@"view%d", i];
        NSButton *button = [NSButton buttonWithTitle:[self shorten:[self clipboardItems][i]] target:self action:@selector(pasteItemFromTouchIndex:)];
        button.property = [NSNumber numberWithInt:i];
        button.translatesAutoresizingMaskIntoConstraints = NO;
        [documentView addSubview:button];
        
        // Constraint information
        layoutFormat = [layoutFormat stringByAppendingString:[NSString stringWithFormat:@"[%@]-8-", objectName]];
        [constraintViews setObject:button forKey:objectName];
        size.width += 8 + button.intrinsicContentSize.width;
    }
    
    layoutFormat = [layoutFormat stringByAppendingString:[NSString stringWithFormat:@"|"]];
    
    NSArray *hConstraints = [NSLayoutConstraint constraintsWithVisualFormat:layoutFormat
                                                                    options:NSLayoutFormatAlignAllCenterY
                                                                    metrics:nil
                                                                      views:constraintViews];
    
    [documentView setFrame:NSMakeRect(0, 0, size.width, size.height)];
    [NSLayoutConstraint activateConstraints:hConstraints];
    scrollView.documentView = documentView;
    
    NSCustomTouchBarItem *item = [[NSCustomTouchBarItem alloc] initWithIdentifier:kClipItemIdentifier];
    item.view = scrollView;
    
    return item;
}

- (NSTouchBar *)touchBar {
    if (!_touchBar) {
        NSTouchBar *touchBar = [[NSTouchBar alloc] init];
        touchBar.delegate = self;
        touchBar.defaultItemIdentifiers = [self itemIdentifiersForClipboard];
        _touchBar = touchBar;
    }
    return _touchBar;
}

- (NSArray*)clipboardItems {
    NSArray *items = [controller menuStrings];
    NSInteger itemsToShow = items.count-9;
    if (itemsToShow > 0) {
        NSArray *clipItems = [items subarrayWithRange:NSMakeRange(0, itemsToShow)];
        return clipItems;
    }
    return @[];
}

- (NSArray*)itemIdentifiersForClipboard {
    return @[kClipItemIdentifier];
}

- (void)expandBar:(id)sender {
    self.touchBar = nil;
    if (@available(macOS 10.14, *)) {
        [NSTouchBar presentSystemModalTouchBar:self.touchBar
                      systemTrayItemIdentifier:kjumpCutIdentifier];
    } else {
        [NSTouchBar presentSystemModalFunctionBar:self.touchBar
                         systemTrayItemIdentifier:kjumpCutIdentifier];
    }
}

- (NSTouchBarItem *)touchBar:(NSTouchBar *)touchBar makeItemForIdentifier:(NSTouchBarItemIdentifier)identifier {
    if ([identifier isEqualToString:kjumpCutIdentifier]) {
        NSCustomTouchBarItem *jumpcutButton = [[NSCustomTouchBarItem alloc] initWithIdentifier:kjumpCutIdentifier];
        jumpcutButton.view = [NSButton buttonWithTitle:@"✂" target:self action:@selector(expandBar:)];
        return jumpcutButton;
    }
    else if ([identifier isEqualToString:kClipItemIdentifier]) {
        return [self pasteboardItem];
    }
    else {
        return nil;
    }
}

- (NSString*)shorten:(NSString*)string {
    NSRange stringRange = {0, MIN([string length], 30)};
    stringRange = [string rangeOfComposedCharacterSequencesForRange:stringRange];
    NSString *shortString = [string substringWithRange:stringRange];
    return shortString;
}

- (void)pasteItemFromTouchIndex:(NSButton*)button {
    int index = button.property.intValue;
    [controller pasteIndexTouch:index];
}

@end
