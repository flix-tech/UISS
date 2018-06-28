#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface UISSAppearanceProxy : NSProxy

+ (instancetype)proxyForObjectsOfClass:(Class)targetClass;

- (void)applyInvocationsToTarget:(id)target;

@end

NS_ASSUME_NONNULL_END
