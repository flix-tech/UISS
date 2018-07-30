#import <Foundation/Foundation.h>

@interface UISSAppearanceContainer : NSObject <NSCopying>

+ (instancetype)new NS_UNAVAILABLE;
- (instancetype)init NS_UNAVAILABLE;

+ (instancetype)containerWithClass:(Class)containerClass identifier:(NSString *)identifier;

@property (nonatomic, readonly) Class containerClass;
@property (nonatomic, readonly) NSString *identifier;

@end

@protocol UISSAppearance <NSObject>

+ (instancetype)appearanceWithUISSIdentifier:(NSString *)identifier;

+ (instancetype)appearanceWithUISSIdentifier:(NSString *)identifier
                                inContainers:(NSArray<UISSAppearanceContainer *> *)containers;

@property (nonatomic, copy) IBInspectable NSString *UISSIdentifier;

@end

@interface UIView (UISSAppearance) <UISSAppearance>
@end
