//
// Copyright (c) 2013 Robert Wijas. All rights reserved.
//

#import <XCTest/XCTest.h>

#import "UISSAppearance.h"
#import "UISSPropertySetter.h"

@interface UISSPropertySetterTests : XCTestCase

@end

@implementation UISSPropertySetterTests

- (void)testAccessingSelectorWithoutAxisParameters; {
    UISSPropertySetter *propertySetter = [[UISSPropertySetter alloc] init];
    propertySetter.appearanceClass = [UIToolbar class];

    UISSProperty *property = [[UISSProperty alloc] init];
    property.name = @"tintColor";
    propertySetter.property = property;

    XCTAssertEqual(propertySetter.selector, @selector(setTintColor:));
}

- (void)testAccessingSelectorWithOneAxisParameter; {
    UISSPropertySetter *propertySetter = [[UISSPropertySetter alloc] init];
    propertySetter.appearanceClass = [UIButton class];

    UISSProperty *property = [[UISSProperty alloc] init];
    property.name = @"titleColor";
    propertySetter.property = property;

    UISSAxisParameter *axisParameter = [[UISSAxisParameter alloc] init];
    propertySetter.axisParameters = @[axisParameter];

    XCTAssertEqual(propertySetter.selector, @selector(setTitleColor:forState:));
}

- (void)testAccessingSelectorWithTwoAxisParameters; {
    UISSPropertySetter *propertySetter = [[UISSPropertySetter alloc] init];
    propertySetter.appearanceClass = [UIBarButtonItem class];

    UISSProperty *property = [[UISSProperty alloc] init];
    property.name = @"backgroundImage";
    propertySetter.property = property;

    UISSAxisParameter *axisParameter1 = [[UISSAxisParameter alloc] init];
    UISSAxisParameter *axisParameter2 = [[UISSAxisParameter alloc] init];

    propertySetter.axisParameters = @[axisParameter1, axisParameter2];

    XCTAssertEqual(propertySetter.selector, @selector(setBackgroundImage:forState:barMetrics:));
}

- (void)testShouldFailToRecognizeSelectorIfThereAreToManyAxisParameters; {
    UISSPropertySetter *propertySetter = [[UISSPropertySetter alloc] init];
    propertySetter.appearanceClass = [UIButton class];

    UISSProperty *property = [[UISSProperty alloc] init];
    property.name = @"titleColor";
    propertySetter.property = property;

    UISSAxisParameter *axisParameter1 = [[UISSAxisParameter alloc] init];
    UISSAxisParameter *axisParameter2 = [[UISSAxisParameter alloc] init];

    propertySetter.axisParameters = @[axisParameter1, axisParameter2];

    XCTAssertEqual(propertySetter.selector, (SEL) NULL);
}

#pragma mark - Code Generation & Invocations

- (void)testSimplePropertyWithoutContainment; {
    UISSPropertySetter *propertySetter = [[UISSPropertySetter alloc] init];
    propertySetter.appearanceClass = [UIToolbar class];

    UISSProperty *tintColorProperty = [[UISSProperty alloc] init];
    tintColorProperty.name = @"tintColor";
    tintColorProperty.value = @"white";

    propertySetter.property = tintColorProperty;

    XCTAssertEqualObjects(propertySetter.generatedCode, @"[[UIToolbar appearance] setTintColor:[UIColor whiteColor]];");

    NSInvocation *invocation = propertySetter.invocation;
    XCTAssertNotNil(invocation);
}

- (void)testSimplePropertyWithIdentifier;
{
    UISSPropertySetter *propertySetter = [[UISSPropertySetter alloc] init];
    propertySetter.appearanceClass = [UIToolbar class];
    propertySetter.identifier = @"special";
    propertySetter.usesUISSAppearance = YES;

    UISSProperty *tintColorProperty = [[UISSProperty alloc] init];
    tintColorProperty.name = @"tintColor";
    tintColorProperty.value = @"white";

    propertySetter.property = tintColorProperty;

    XCTAssertEqualObjects(propertySetter.generatedCode, @"[[UIToolbar appearanceWithUISSIdentifier:@\"special\"] setTintColor:[UIColor whiteColor]];");

    NSInvocation *invocation = propertySetter.invocation;
    XCTAssertNotNil(invocation);
    XCTAssertEqual(invocation.target, [UIToolbar appearanceWithUISSIdentifier:propertySetter.identifier]);
}

- (void)testSimplePropertyWithIdentifierInDeepContainment;
{
    UISSPropertySetter *propertySetter = [[UISSPropertySetter alloc] init];
    propertySetter.appearanceClass = [UILabel class];
    propertySetter.identifier = @"special";
    propertySetter.usesUISSAppearance = YES;
    propertySetter.containment = @[
        [UISSAppearanceContainer containerWithClass:UIToolbar.class
                                         identifier:nil],
        [UISSAppearanceContainer containerWithClass:UIButton.class
                                         identifier:@"btn"],
    ];

    UISSProperty *tintColorProperty = [[UISSProperty alloc] init];
    tintColorProperty.name = @"tintColor";
    tintColorProperty.value = @"white";

    propertySetter.property = tintColorProperty;

    XCTAssertEqualObjects(propertySetter.generatedCode, @"[[UILabel appearanceWithUISSIdentifier:@\"special\" inContainers:@[[UISSAppearanceContainer containerWithClass:UIButton.class identifier:@\"btn\"], [UISSAppearanceContainer containerWithClass:UIToolbar.class identifier:nil]]] setTintColor:[UIColor whiteColor]];");

    NSInvocation *invocation = propertySetter.invocation;
    XCTAssertNotNil(invocation);

    id expectedTarget = [UILabel appearanceWithUISSIdentifier:propertySetter.identifier
                                                 inContainers:@[
                                                     [UISSAppearanceContainer containerWithClass:UIButton.class
                                                                                      identifier:@"btn"],
                                                     [UISSAppearanceContainer containerWithClass:UIToolbar.class
                                                                                      identifier:nil],
                                                 ]];
    XCTAssertEqual(invocation.target, expectedTarget);
}

- (void)testSimplePropertyWithContainment; {
    UISSPropertySetter *propertySetter = [[UISSPropertySetter alloc] init];
    propertySetter.appearanceClass = [UIToolbar class];
    propertySetter.containment = @[ [UISSAppearanceContainer containerWithClass:[UINavigationController class] identifier:nil] ];

    UISSProperty *tintColorProperty = [[UISSProperty alloc] init];
    tintColorProperty.name = @"tintColor";
    tintColorProperty.value = @"white";

    propertySetter.property = tintColorProperty;

    XCTAssertEqualObjects(propertySetter.generatedCode, @"[[UIToolbar appearanceWhenContainedInInstancesOfClasses:@[[UINavigationController class], ]] setTintColor:[UIColor whiteColor]];");
}

- (void)testSimplePropertyWithDeepContainment; {
    UISSPropertySetter *propertySetter = [[UISSPropertySetter alloc] init];
    propertySetter.appearanceClass = [UIToolbar class];
    propertySetter.containment = @[
        [UISSAppearanceContainer containerWithClass:[UINavigationController class]
                                         identifier:nil],
        [UISSAppearanceContainer containerWithClass:[UIView class]
                                         identifier:nil]
    ];

    UISSProperty *tintColorProperty = [[UISSProperty alloc] init];
    tintColorProperty.name = @"tintColor";
    tintColorProperty.value = @"white";

    propertySetter.property = tintColorProperty;

    XCTAssertEqualObjects(propertySetter.generatedCode, @"[[UIToolbar appearanceWhenContainedInInstancesOfClasses:@[[UIView class], [UINavigationController class], ]] setTintColor:[UIColor whiteColor]];");
}

- (void)testPropertyWithAxisParameter; {
    UISSPropertySetter *propertySetter = [[UISSPropertySetter alloc] init];
    propertySetter.appearanceClass = [UIBarButtonItem class];

    UISSProperty *tintColorProperty = [[UISSProperty alloc] init];
    tintColorProperty.name = @"titlePositionAdjustment";
    tintColorProperty.value = @10.0f;

    UISSAxisParameter *axisParameter = [[UISSAxisParameter alloc] init];
    axisParameter.value = @"default";

    propertySetter.property = tintColorProperty;
    propertySetter.axisParameters = @[axisParameter];

    XCTAssertEqualObjects(propertySetter.generatedCode, @"[[UIBarButtonItem appearance] setTitlePositionAdjustment:UIOffsetMake(10.0, 10.0) forBarMetrics:UIBarMetricsDefault];");
}

@end
