#import "UISSAppearanceProxy.h"

@implementation UISSAppearanceProxy {
    Class _targetClass;
    NSMutableArray<NSInvocation *> *_invocations;
}

+ (instancetype)proxyForObjectsOfClass:(Class)targetClass
{
    NSCParameterAssert(targetClass != Nil);

    UISSAppearanceProxy *proxy = [self alloc];

    proxy->_targetClass = targetClass;
    proxy->_invocations = [NSMutableArray new];

    return proxy;
}

- (void)applyInvocationsToTarget:(id)target
{
    for (NSInvocation *invocation in _invocations) {
        [invocation invokeWithTarget:target];
    }
}

#pragma mark - NSProxy Methods

- (NSMethodSignature *)methodSignatureForSelector:(SEL)sel
{
    return [_targetClass instanceMethodSignatureForSelector:sel];
}

- (void)forwardInvocation:(NSInvocation *)invocation
{
    [invocation retainArguments];
    [_invocations addObject:invocation];
}

@end
