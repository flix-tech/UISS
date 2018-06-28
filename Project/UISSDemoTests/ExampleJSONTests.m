//
// Copyright (c) 2013 Robert Wijas. All rights reserved.
//

#import "UISS.h"
#import <XCTest/XCTest.h>

@interface TestLabel : UILabel
@end

@implementation TestLabel
@end


@interface ExampleJSONTests : XCTestCase

@property(nonatomic, strong) UISS *uiss;

@end

@implementation ExampleJSONTests

- (void)setUp {
    [super setUp];

    NSString *jsonFilePath = [[NSBundle bundleForClass:[self class]] pathForResource:@"example" ofType:@"json"];
    self.uiss = [UISS configureWithJSONFilePath:jsonFilePath];
}

- (void)testGeneratedCodeForPad; {
    [self.uiss generateCodeForUserInterfaceIdiom:UIUserInterfaceIdiomPad
                                     codeHandler:^(NSString *code, NSArray *errors) {
                                         XCTAssertTrue(errors.count == 0, @"errors are unexpected");
                                         XCTAssertNotNil(code);
                                         XCTAssertTrue([code rangeOfString:@"[[UINavigationBar appearance] setTintColor:[UIColor greenColor]];"].location != NSNotFound);
                                     }];
}

- (void)testGeneratedCodeForPhone; {
    [self.uiss generateCodeForUserInterfaceIdiom:UIUserInterfaceIdiomPhone
                                     codeHandler:^(NSString *code, NSArray *errors) {
                                         XCTAssertTrue(errors.count == 0, @"errors are unexpected");
                                         XCTAssertNotNil(code);
                                         XCTAssertTrue([code rangeOfString:@"[[UINavigationBar appearance] setTintColor:[UIColor redColor]];"].location != NSNotFound);
                                     }];
}

- (void)testToolbarTintColor; {
    XCTAssertEqualObjects([[UIToolbar appearance] tintColor], [UIColor yellowColor]);
}

- (void)testToolbarBackgroundImage; {
    UIImage *backgroundImage = [[UIToolbar appearance] backgroundImageForToolbarPosition:UIToolbarPositionAny
                                                                              barMetrics:UIBarMetricsDefault];
    XCTAssertNotNil(backgroundImage);
    XCTAssertEqualObjects([backgroundImage class], [UIImage class], @"bad property class", nil);
}

- (void)testTabBarItemTitlePositionAdjustment; {
    UIOffset titlePositionAdjustment = [[UITabBarItem appearance] titlePositionAdjustment];
    XCTAssertTrue(UIOffsetEqualToOffset(titlePositionAdjustment, UIOffsetMake(10, 10)));
}

- (void)testNavigationBarTitleVerticalPositionAdjustment; {
    XCTAssertEqual([[UINavigationBar appearance] titleVerticalPositionAdjustmentForBarMetrics:UIBarMetricsDefault], 10.0f);
}

- (void)testNavigationBarBackgroundImageForBarMetricsLandscapePhone; {
    XCTAssertNotNil([[UINavigationBar appearance] backgroundImageForBarMetrics:UIBarMetricsCompact]);
}

- (void)testTabBarItemTitleTextAttributes; {
    UIFont *font = [[UITabBarItem appearance] titleTextAttributesForState:UIControlStateNormal][NSFontAttributeName];
    XCTAssertNotNil(font);
    if (font) {
        XCTAssertEqualObjects(font, [UIFont systemFontOfSize:24]);
    }
}

- (void)testToolbarWithIdentifierOnMovingToWindow;
{
    UIToolbar *toolbar = [UIToolbar new];
    toolbar.UISSIdentifier = @"magenta";

    UIView *simpleView = [UIView new];
    [toolbar addSubview:simpleView];

    UILabel *label = [UILabel new];
    [simpleView addSubview:label];

    UILabel *redLabel = [UILabel new];
    redLabel.UISSIdentifier = @"red";
    [toolbar addSubview:redLabel];

    TestLabel *magentaLabel = [TestLabel new];
    magentaLabel.UISSIdentifier = @"magenta";
    [toolbar addSubview:magentaLabel];

    TestLabel *nestedLabel = [TestLabel new];
    nestedLabel.UISSIdentifier = @"overridden";
    [toolbar addSubview:nestedLabel];

    UIWindow *window = [UIWindow new];

    [window addSubview:toolbar];

    XCTAssertEqualObjects(toolbar.barTintColor, UIColor.magentaColor);
    XCTAssertEqualObjects(toolbar.tintColor, UIColor.whiteColor);

    XCTAssertEqualObjects(label.textColor, UIColor.cyanColor);
    XCTAssertEqualObjects(redLabel.textColor, UIColor.redColor);
    XCTAssertEqualObjects(magentaLabel.textColor, UIColor.magentaColor);
    XCTAssertEqualObjects(nestedLabel.textColor, UIColor.purpleColor);
}

- (void)testToolbarWithIdentifierOnAddingDescendants;
{
    UIToolbar *toolbar = [UIToolbar new];
    toolbar.UISSIdentifier = @"magenta";

    UIWindow *window = [UIWindow new];
    [window addSubview:toolbar];

    UIView *simpleView = [UIView new];
    [toolbar addSubview:simpleView];

    UILabel *label = [UILabel new];
    [simpleView addSubview:label];

    UILabel *redLabel = [UILabel new];
    redLabel.UISSIdentifier = @"red";
    [toolbar addSubview:redLabel];

    TestLabel *magentaLabel = [TestLabel new];
    magentaLabel.UISSIdentifier = @"magenta";
    [toolbar addSubview:magentaLabel];

    TestLabel *nestedLabel = [TestLabel new];
    nestedLabel.UISSIdentifier = @"overridden";
    [toolbar addSubview:nestedLabel];

    XCTAssertEqualObjects(toolbar.barTintColor, UIColor.magentaColor);
    XCTAssertEqualObjects(toolbar.tintColor, UIColor.whiteColor);

    XCTAssertEqualObjects(label.textColor, UIColor.cyanColor);
    XCTAssertEqualObjects(redLabel.textColor, UIColor.redColor);
    XCTAssertEqualObjects(magentaLabel.textColor, UIColor.magentaColor);
    XCTAssertEqualObjects(nestedLabel.textColor, UIColor.purpleColor);
}

@end
