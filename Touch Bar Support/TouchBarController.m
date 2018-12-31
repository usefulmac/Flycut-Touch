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
    }
    return self;
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
    NSMutableArray *itemIdentifiers = [NSMutableArray new];
    for (int i = 0; i < [self clipboardItems].count; i++) {
        [itemIdentifiers addObject:[NSString stringWithFormat:@"com.jumpcut.clipItem%d", i]];
    }
    return itemIdentifiers;
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
    } else {
        int index = [[identifier substringFromIndex:identifier.length-1] integerValue];
        NSCustomTouchBarItem *item = [[NSCustomTouchBarItem alloc] initWithIdentifier:[NSString stringWithFormat:@"com.jumpcut.clipItem%d", index]];
        NSButton *button = [NSButton buttonWithTitle:[self shorten:[self clipboardItems][index]] target:self action:@selector(pasteItemFromTouchIndex:)];
        button.property = [NSNumber numberWithInt:index];
        item.view = button;
        return item;
    }
}

- (NSString*)shorten:(NSString*)string {
    NSRange stringRange = {0, MIN([string length], 20)};
    stringRange = [string rangeOfComposedCharacterSequencesForRange:stringRange];
    NSString *shortString = [string substringWithRange:stringRange];
    return shortString;
}

- (void)pasteItemFromTouchIndex:(NSButton*)button {
    int index = button.property.intValue;
    NSString *pasteboardItem = [self clipboardItems][index];
    [controller pasteIndexTouch:index];
}

@end
