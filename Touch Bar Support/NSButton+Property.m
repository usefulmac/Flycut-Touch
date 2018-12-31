//
//  UIButton+Property.m
//
//  Created by Chris Galzerano on 5/28/14.
//  Copyright (c) 2014 chrisgalz. All rights reserved.
//

#import "NSButton+Property.h"
#import <objc/runtime.h>

@implementation NSButton (Property)

static char UIB_PROPERTY_KEY;

@dynamic property;

-(void)setProperty:(NSNumber *)property
{
    objc_setAssociatedObject(self, &UIB_PROPERTY_KEY, property, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

-(NSNumber*)property
{
    return (NSNumber*)objc_getAssociatedObject(self, &UIB_PROPERTY_KEY);
}

@end

