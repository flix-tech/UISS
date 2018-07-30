//
// Copyright (c) 2013 Robert Wijas. All rights reserved.
//

#import <UIKit/UIKit.h>

@class UISSAppearanceContainer;

@interface UISSParserContext : NSObject

@property (nonatomic, readonly) NSArray<UISSAppearanceContainer *> *containersStack;
@property (nonatomic, strong) NSMutableArray *groupsStack;
@property (nonatomic, strong) NSMutableArray *errors;
@property (nonatomic, strong) NSMutableArray *propertySetters;

- (void)pushContainer:(Class<UIAppearanceContainer>)container withIdentifier:(NSString *)identifier;
- (void)popContainer;

@property (nonatomic, readonly) BOOL UISSAppearanceEnabled;

- (void)addErrorWithCode:(NSInteger)code object:(id)object key:(NSString *)key;

@end
