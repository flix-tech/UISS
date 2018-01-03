//
// Copyright (c) 2013 Robert Wijas. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "UISSParser.h"
#import "UISSPropertySetter.h"
#import "UISSError.h"

@interface UISSParserTests : XCTestCase

@property(nonatomic, strong) UISSParser *parser;

@end

@implementation UISSParserTests

#pragma mark - Groups

- (void)testGroups; {
    NSDictionary *dictionary = @{@"UIToolbar" : @{@"tintColor" : @"yellow"}};
    dictionary = @{@"@Group" : dictionary};

    NSMutableArray *errors = [NSMutableArray array];

    NSArray *propertySetters = [self.parser parseDictionary:dictionary errors:errors];

    XCTAssertEqual(errors.count, (NSUInteger) 0, @"expected no errors");
    XCTAssertEqual(propertySetters.count, (NSUInteger) 1, @"expected one property setter");

    UISSPropertySetter *propertySetter = [propertySetters lastObject];
    XCTAssertEqualObjects(propertySetter.group, @"Group");
    XCTAssertEqual(propertySetter.containment.count, (NSUInteger) 0);
}

#pragma mark - Errors

- (void)testInvalidAppearanceDictionary; {
    NSDictionary *dictionary = @{@"UIToolbar" : @"Invalid dictionary"};
    NSMutableArray *errors = [NSMutableArray array];

    [self.parser parseDictionary:dictionary errors:errors];

    XCTAssertEqual(errors.count, (NSUInteger) 1, @"expected one error");
    NSError *error = errors.lastObject;
    XCTAssertEqual(error.code, UISSInvalidAppearanceDictionaryError);
    XCTAssertEqualObjects((error.userInfo)[UISSInvalidAppearanceDictionaryErrorKey], dictionary);
}

- (void)testUnknownClassNameWithoutContainment; {
    NSDictionary *dictionary = @{@"UnknownClass" : @{@"tintColor" : @"yellow"}};
    NSMutableArray *errors = [NSMutableArray array];

    [self.parser parseDictionary:dictionary errors:errors];

    XCTAssertEqual(errors.count, (NSUInteger) 1, @"expected one error");
    NSError *error = errors.lastObject;
    XCTAssertEqual(error.code, UISSUnknownClassError);
    XCTAssertEqualObjects((error.userInfo)[UISSInvalidClassNameErrorKey], @"UnknownClass");
}

- (void)testInvalidAppearanceContainerClass; {
    NSDictionary *dictionary = @{@"UIToolbar" : @{@"tintColor" : @"yellow"}};
    dictionary = @{@"UIBarButtonItem" : dictionary};
    NSMutableArray *errors = [NSMutableArray array];

    [self.parser parseDictionary:dictionary errors:errors];

    XCTAssertEqual(errors.count, (NSUInteger) 1, @"expected one error");
    NSError *error = errors.lastObject;
    XCTAssertEqual(error.code, UISSInvalidAppearanceContainerClassError);
    XCTAssertEqualObjects((error.userInfo)[UISSInvalidClassNameErrorKey], @"UIBarButtonItem");
}

- (void)testInvalidAppearanceClass; {
    NSDictionary *dictionary = @{@"NSString" : @{@"tintColor" : @"yellow"}};
    NSMutableArray *errors = [NSMutableArray array];

    [self.parser parseDictionary:dictionary errors:errors];

    XCTAssertEqual(errors.count, (NSUInteger) 1, @"expected one error");
    NSError *error = errors.lastObject;
    XCTAssertEqual(error.code, UISSInvalidAppearanceClassError);
    XCTAssertEqualObjects((error.userInfo)[UISSInvalidClassNameErrorKey], @"NSString");
}

- (void)testInvalidAppearanceClassInContainer; {
    NSDictionary *dictionary = @{@"UIBadToolbar" : @{@"tintColor" : @"yellow"}};
    dictionary = @{@"UIPopoverController" : dictionary};
    NSMutableArray *errors = [NSMutableArray array];

    [self.parser parseDictionary:dictionary errors:errors];

    XCTAssertEqual(errors.count, (NSUInteger) 1, @"expected one error");
    NSError *error = errors.lastObject;
    XCTAssertEqual(error.code, UISSUnknownClassError);
    XCTAssertEqualObjects((error.userInfo)[UISSInvalidClassNameErrorKey], @"UIBadToolbar");
}

#pragma mark - Invocations

- (void)testToolbarTintColor; {
    NSDictionary *dictionary = @{@"UIToolbar" : @{@"tintColor" : @"yellow"}};

    [self parserTestWithDictionary:dictionary assertionsAfterInvoke:^(NSInvocation *invocation) {
        XCTAssertEqualObjects(invocation.target, [UIToolbar appearance], @"expected target to be UIToolbar appearance proxy");
        XCTAssertEqual(invocation.selector, @selector(setTintColor:));

        UIColor *color;
        [invocation getArgument:&color atIndex:2];
        XCTAssertEqualObjects(color, [UIColor yellowColor]);
    }];
}

- (void)testLabelShadowOffset; {
    NSDictionary *dictionary = @{@"UILabel" : @{@"shadowOffset" : @1.0f}};

    [self parserTestWithDictionary:dictionary assertionsAfterInvoke:^(NSInvocation *invocation) {
        XCTAssertEqualObjects(invocation.target, [UILabel appearance], @"expected target to be UILabel appearance proxy");
        XCTAssertEqual(invocation.selector, @selector(setShadowOffset:));

        CGSize shadowOffset;
        [invocation getArgument:&shadowOffset atIndex:2];
        XCTAssertTrue(CGSizeEqualToSize(shadowOffset, CGSizeMake(1, 1)));

        XCTAssertTrue(CGSizeEqualToSize([[UILabel appearance] shadowOffset], CGSizeMake(1, 1)));
    }];
}

- (void)testButtonTitleColorForState; {
    NSDictionary *dictionary = @{@"UIButton" : @{@"titleColor:highlighted" : @"green"}};


    [self parserTestWithDictionary:dictionary assertionsAfterInvoke:^(NSInvocation *invocation) {
        XCTAssertEqualObjects([[UIButton appearance] titleColorForState:UIControlStateHighlighted], [UIColor greenColor]);
    }];
}

- (void)testSimpleContainment; {
    NSDictionary *buttonDictionary = @{@"UIButton" : @{@"titleColor:highlighted" : @"green"}};
    NSDictionary *containmentDictionary = @{@"UINavigationController" : buttonDictionary};


    [self parserTestWithDictionary:containmentDictionary assertionsAfterInvoke:^(NSInvocation *invocation) {
        UIColor *buttonColor = [[UIButton appearanceWhenContainedInInstancesOfClasses:@[ [UINavigationController class] ]]
                                titleColorForState:UIControlStateHighlighted];
        XCTAssertEqualObjects(buttonColor, [UIColor greenColor]);
    }];
}

- (void)testContainment; {
    NSDictionary *dictionary = @{@"UIButton" : @{@"titleColor:highlighted" : @"yellow"}};
    dictionary = @{@"UIImageView" : dictionary};
    dictionary = @{@"UINavigationController" : dictionary};

    [self parserTestWithDictionary:dictionary assertionsAfterInvoke:^(NSInvocation *invocation) {
        UIColor *buttonColor = [[UIButton appearanceWhenContainedInInstancesOfClasses:@[ [UIImageView class], [UINavigationController class] ]]
                                titleColorForState:UIControlStateHighlighted];
        XCTAssertEqualObjects(buttonColor, [UIColor yellowColor]);
    }];
}

#pragma mark - Helper Methods

- (void)parserTestWithDictionary:(NSDictionary *)dictionary assertionsAfterInvoke:(void (^)(NSInvocation *))assertions; {
    UISSParser *parser = [[UISSParser alloc] init];

    NSMutableArray *invokedInvocations = [NSMutableArray array];

    NSArray *propertySetters = [parser parseDictionary:dictionary];
    for (UISSPropertySetter *propertySetter in propertySetters) {
        NSInvocation *invocation = propertySetter.invocation;
        if (invocation) {
            [invocation invoke];
            [invokedInvocations addObject:invocation];
            assertions(invocation);
        }
    }

    XCTAssertTrue([invokedInvocations count], @"expected at least one invocation");
}

#pragma mark - Setup

- (void)setUp; {
    self.parser = [[UISSParser alloc] init];
}

- (void)tearDown; {
    self.parser = nil;
}

@end

