//
// Copyright (c) 2013 Robert Wijas. All rights reserved.
//

#import "UISSParserContext.h"
#import "UISSAppearance.h"
#import "UISSError.h"

@implementation UISSParserContext {
    NSMutableArray<UISSAppearanceContainer *> *_containersStack;
    NSUInteger _identifiersCount;
}

@synthesize containersStack = _containersStack;

- (id)init
{
    self = [super init];
    if (self) {
        _containersStack = [NSMutableArray array];
        self.groupsStack = [NSMutableArray array];
        self.errors = [NSMutableArray array];
        self.propertySetters = [NSMutableArray array];
    }
    return self;
}

- (void)pushContainer:(Class<UIAppearanceContainer>)container withIdentifier:(NSString *)identifier
{
    [_containersStack addObject:[UISSAppearanceContainer containerWithClass:container identifier:identifier]];

    if (identifier) {
        _identifiersCount++;
    }
}

- (void)popContainer
{
    if (_containersStack.lastObject.identifier) {
        _identifiersCount--;
    }
    [_containersStack removeLastObject];
}

- (BOOL)UISSAppearanceEnabled
{
    return _identifiersCount > 0;
}

- (void)addErrorWithCode:(NSInteger)code object:(id)object key:(NSString *)key;
{
    NSDictionary *userInfo = nil;
    if (key) {
        userInfo = [NSDictionary dictionaryWithObject:object forKey:key];
    }

    [self.errors addObject:[UISSError errorWithCode:code
                                           userInfo:userInfo]];
}

@end
