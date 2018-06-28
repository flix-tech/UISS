//
// Copyright (c) 2013 Robert Wijas. All rights reserved.
//

#import "UISSParser.h"

#import "UISSAppearance.h"
#import "UISSConfig.h"
#import "UISSDictionaryPreprocessor.h"
#import "UISSError.h"
#import "UISSParserContext.h"
#import "UISSPropertySetter.h"

static NSString *const AppearanceIdentifierDelimiter = @"#";

@implementation UISSParser

- (id)init {
    self = [super init];
    if (self) {
        self.config = [UISSConfig sharedConfig];
        self.userInterfaceIdiom = [UIDevice currentDevice].userInterfaceIdiom;
        self.groupPrefix = UISS_PARSER_DEFAULT_GROUP_PREFIX;
    }

    return self;
}

- (id)propertySetterForKey:(NSString *)key withValue:(id)value context:(UISSParserContext *)context {
    UISSPropertySetter *propertySetter = [[UISSPropertySetter alloc] init];

    __auto_type container = context.containersStack.lastObject;

    propertySetter.appearanceClass = container.containerClass;
    propertySetter.identifier = container.identifier;
    propertySetter.usesUISSAppearance = context.UISSAppearanceEnabled;
    propertySetter.containment = [context.containersStack subarrayWithRange:NSMakeRange(0, context.containersStack.count - 1)];

    NSArray *keyParts = [key componentsSeparatedByString:@":"];

    NSString *name = [keyParts objectAtIndex:0];

    UISSProperty *property = [[UISSProperty alloc] init];
    property.name = name;
    property.value = value == [NSNull null] ? nil : value;

    propertySetter.property = property;
    propertySetter.group = context.groupsStack.lastObject;

    NSMutableArray *axisParameters = [NSMutableArray array];

    for (NSUInteger idx = 1; idx < keyParts.count; idx++) {
        UISSAxisParameter *axisParameter = [[UISSAxisParameter alloc] init];
        axisParameter.value = [keyParts objectAtIndex:idx];
        [axisParameters addObject:axisParameter];
    }

    propertySetter.axisParameters = axisParameters;

    return propertySetter;
}

- (void)processClass:(Class)containerClass withIdentifier:(NSString *)identifier object:(id)object context:(UISSParserContext *)context;
{
    if ([containerClass conformsToProtocol:@protocol(UIAppearance)] || [containerClass conformsToProtocol:@protocol(UIAppearanceContainer)]) {
        Class currentContainer = context.containersStack.lastObject.containerClass;

        if (currentContainer == nil || [currentContainer conformsToProtocol:@protocol(UIAppearanceContainer)]) {
            UISS_LOG(@"component: %@", NSStringFromClass(containerClass));

            if ([object isKindOfClass:[NSDictionary class]]) {
                [context pushContainer:containerClass withIdentifier:identifier];
                [self parseDictionary:object context:context];
                [context popContainer];
            } else {
                [context addErrorWithCode:UISSInvalidAppearanceDictionaryError
                                   object:[NSDictionary dictionaryWithObject:object forKey:NSStringFromClass(containerClass)]
                                      key:UISSInvalidAppearanceDictionaryErrorKey];
            }
        } else {
            [context addErrorWithCode:UISSInvalidAppearanceContainerClassError
                               object:NSStringFromClass(currentContainer)
                                  key:UISSInvalidClassNameErrorKey];
        }
    } else {
        [context addErrorWithCode:UISSInvalidAppearanceClassError
                           object:NSStringFromClass(containerClass)
                              key:UISSInvalidClassNameErrorKey];
    }
}

- (void)processPropertyWithKey:(NSString *)key value:(id)value context:(UISSParserContext *)context; {
    if ([[NSCharacterSet uppercaseLetterCharacterSet] characterIsMember:[key characterAtIndex:0]]) {
        // first letter capitalized so I guess this supposed to be a class
        [context addErrorWithCode:UISSUnknownClassError object:key key:UISSInvalidClassNameErrorKey];
    } else {
        Class currentClass = context.containersStack.lastObject.containerClass;

        if (currentClass == nil) {
            [context addErrorWithCode:UISSUnknownClassError object:key key:UISSInvalidClassNameErrorKey];
        } else if (![currentClass conformsToProtocol:@protocol(UIAppearance)]) {
            [context addErrorWithCode:UISSInvalidAppearanceClassError object:NSStringFromClass(currentClass)
                                  key:UISSInvalidClassNameErrorKey];
        } else {
            UISS_LOG(@"property: %@", key);
            [context.propertySetters addObject:[self propertySetterForKey:key withValue:value context:context]];
        }
    }
}

- (void)processKey:(NSString *)key object:(id)object context:(UISSParserContext *)context; {
    if ([key hasPrefix:self.groupPrefix]) {
        [context.groupsStack addObject:[key substringFromIndex:[self.groupPrefix length]]];
        [self parseDictionary:object context:context];
        [context.groupsStack removeLastObject];
        return;
    }

    NSArray *components = [key componentsSeparatedByString:AppearanceIdentifierDelimiter];

    if (components.count > 1) {
        Class class = NSClassFromString(components[0]);
        [self processClass:class withIdentifier:components[1] object:object context:context];
        return;
    }

    Class class = NSClassFromString(key);

    if (class) {
        [self processClass:class withIdentifier:nil object:object context:context];
    } else {
        [self processPropertyWithKey:key value:object context:context];
    }
}

- (void)parseDictionary:(NSDictionary *)dictionary context:(UISSParserContext *)context; {
    [dictionary enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
        [self processKey:key object:obj context:context];
    }];
}

#pragma mark - Public

- (NSArray *)parseDictionary:(NSDictionary *)dictionary errors:(NSMutableArray *)errors; {
    UISSParserContext *context = [[UISSParserContext alloc] init];

    for (id <UISSDictionaryPreprocessor> preprocessor in self.config.preprocessors) {
        dictionary = [preprocessor preprocess:dictionary userInterfaceIdiom:self.userInterfaceIdiom];
    }

    [self parseDictionary:dictionary context:context];

    [errors addObjectsFromArray:context.errors];

    return context.propertySetters;
}

- (NSArray *)parseDictionary:(NSDictionary *)dictionary; {
    return [self parseDictionary:dictionary errors:nil];
}

@end
