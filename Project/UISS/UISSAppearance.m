#import <Foundation/Foundation.h>
#import <objc/message.h>

#import "UISSAppearance.h"
#import "UISSAppearanceProxy.h"

@implementation UISSAppearanceContainer

+ (instancetype)containerWithClass:(Class)containerClass identifier:(NSString *)identifier
{
    return [[self alloc] initWithClass:containerClass identifier:identifier];
}

- (instancetype)initWithClass:(Class)containerClass identifier:(NSString *)identifier
{
    NSCParameterAssert(containerClass != Nil);
    self = [super init];
    if (self) {
        _containerClass = containerClass;
        _identifier = [identifier copy];
    }
    return self;
}

- (BOOL)isEqual:(UISSAppearanceContainer *)other
{
    if (self == other) {
        return YES;
    }

    if (_containerClass != other->_containerClass) {
        return NO;
    }

    return _identifier == other->_identifier || [_identifier isEqualToString:other->_identifier];
}

- (NSUInteger)hash
{
    return [_containerClass hash] ^ _identifier.hash;
}

#pragma mark - NSCopying Methods

- (id)copyWithZone:(NSZone *)zone
{
    return self;
}

@end


@protocol UISSAppearance_Private
@property (nonatomic, readonly) id<UISSAppearance, UISSAppearance_Private> UISS_appearanceContainer;
@end

@interface UISSAppearanceRegistryNode : NSObject

@end

@implementation UISSAppearanceRegistryNode {
    NSMutableDictionary<UISSAppearanceContainer *, UISSAppearanceRegistryNode *> *_children;
    UISSAppearanceProxy *_appearance;
}

- (UISSAppearanceProxy *)registerAppearanceForPath:(NSArray<UISSAppearanceContainer *> *)containerPath atIndex:(NSUInteger)index
{
    if (index == containerPath.count) {
        if (!_appearance) {
            _appearance = [UISSAppearanceProxy proxyForObjectsOfClass:containerPath[0].containerClass];
        }
        return _appearance;
    }

    if (!_children) {
        _children = [NSMutableDictionary new];
    }

    __auto_type key = containerPath[index];

    __auto_type child = _children[key];

    if (!child) {
        _children[key] = child = [UISSAppearanceRegistryNode new];
    }

    return [child registerAppearanceForPath:containerPath atIndex:index + 1];
}

static UISSAppearanceProxy *AppearanceForObjectTraversingHierarchy(UISSAppearanceRegistryNode *node, id<UISSAppearance, UISSAppearance_Private> object)
{
    if (!node) {
        return nil;
    }

    if ([object isKindOfClass:UIWindow.class]) {
        return node->_appearance;
    }

    UISSAppearanceProxy *appearance;

    do {
        appearance = AppearanceForObject(node, object);
        object = object.UISS_appearanceContainer;
    } while (!appearance && object != nil && ![object isKindOfClass:UIWindow.class]);

    return appearance ?: node->_appearance;
}

static UISSAppearanceProxy *AppearanceForObject(UISSAppearanceRegistryNode *node, id<UISSAppearance, UISSAppearance_Private> object)
{
    UISSAppearanceProxy *appearance;

    Class aClass = object.class;

    UISSAppearanceRegistryNode *childNode;

    do {
        __auto_type key = [UISSAppearanceContainer containerWithClass:aClass identifier:object.UISSIdentifier];
        childNode = node->_children[key];
        appearance = AppearanceForObjectTraversingHierarchy(childNode, object.UISS_appearanceContainer);
        aClass = [aClass superclass];
    } while (!appearance && aClass != nil);

    return appearance ?: node->_appearance;
}

@end


static IMP ClassSetMethodImplementation(Class class, SEL sel, id implemetationBlock)
{
    Method method = class_getInstanceMethod(class, sel);

    NSCParameterAssert(method != nil);

    const char *methodEncoding = method_getTypeEncoding(method);

    IMP implementation = imp_implementationWithBlock(implemetationBlock);

    if (!class_addMethod(class, sel, implementation, methodEncoding)) {
        return method_setImplementation(method, implementation);
    }

    return NULL;
}

static UISSAppearanceRegistryNode *Appearances;

static id ClassRegisterAppearanceProxy(Class class, NSString *identifier, NSArray<UISSAppearanceContainer *> *containers)
{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        Appearances = [UISSAppearanceRegistryNode new];
    });

    __auto_type path = [NSMutableArray new];
    [path addObject:[UISSAppearanceContainer containerWithClass:class identifier:identifier]];
    [path addObjectsFromArray:containers];

    return [Appearances registerAppearanceForPath:path atIndex:0];
}

static void ObjectApplyAppearance(id<UISSAppearance, UISSAppearance_Private> object)
{
    if (Appearances) {
        [AppearanceForObject(Appearances, object) applyInvocationsToTarget:object];
    }
}

static void *UISSIdentifierKey = &UISSIdentifierKey;

@interface UIView (UISSAppearance_Private) <UISSAppearance_Private>
@end

@implementation UIView (UISSAppearance_Private)

- (id<UIAppearance>)UISS_appearanceContainer
{
    return self.superview;
}

@end


@implementation UIView (UISSAppearance)

+ (instancetype)appearanceWithUISSIdentifier:(NSString *)identifier
{
    return [self appearanceWithUISSIdentifier:identifier
                                 inContainers:@[]];
}

+ (instancetype)appearanceWithUISSIdentifier:(NSString *)identifier
                                inContainers:(NSArray<UISSAppearanceContainer *> *)containers
{
    return ClassRegisterAppearanceProxy(self, identifier, containers);
}

- (NSString *)UISSIdentifier
{
    return objc_getAssociatedObject(self, UISSIdentifierKey);
}

- (void)setUISSIdentifier:(NSString *)identifier
{
    objc_setAssociatedObject(self, UISSIdentifierKey, identifier, OBJC_ASSOCIATION_COPY_NONATOMIC);

    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        SEL selector = @selector(didMoveToWindow);

        __block void (*originalDidMoveToWindow)(__unsafe_unretained id, SEL) = NULL;

        originalDidMoveToWindow = (void (*)(__unsafe_unretained id, SEL)) ClassSetMethodImplementation(UIView.class, selector, ^(__unsafe_unretained UIView *self) {
            originalDidMoveToWindow(self, selector);

            if (!self.window) {
                return;
            }

            ObjectApplyAppearance(self);
        });
    });
}

@end
