//
//  NSObject_HAH.m
//  HomeassistantHelper
//
//  Created by TozyZuo on 2017/9/28.
//  Copyright © 2017年 TozyZuo. All rights reserved.
//

#import "NSObject_HAH.h"
#import "HAHSOStructDefine.h"
#import <objc/objc-runtime.h>
#import <pthread.h>


NSString * const HAHSOClassPrefix = @"HAHSONotifying_";


id   HAHSOTransmissionFunction(id self, SEL _cmd, ...);
void HAHSOSetArguments(NSInvocation *invocation, NSMethodSignature *signature, NSUInteger startIndex, va_list *ap);

BOOL HAHSOIsObjectSelectorObserved(id self); // object 是否被 selector observed
BOOL HAHSOClassAddMethod(Class class, SEL sel, id imp);

Class HAHSOObjectGetOriginClass(id self);
Class HAHSOObjectGetSOClass(id self); // 防止KVO之后拿到的class不对
BOOL  HAHSOObjectSetSOClass(id self);
BOOL  HAHSOObjectSetMethodImplementation(id self, SEL _cmd, IMP imp);


@interface HAHObserveSelectorTableModel : NSObject
@property (nonatomic, strong) NSMutableArray *preprocessors;
@property (nonatomic, strong) NSMutableArray *postprocessors;
@end


@interface HAHSOController : NSObject
{
    pthread_mutex_t _lock;
}
@property (nonatomic,  weak ) NSObject *object;
@property (nonatomic, strong) NSMapTable<NSObject */* observers */, NSMutableDictionary<NSString */* selectors */, HAHObserveSelectorTableModel *> *> *observerTable;
@end

@implementation HAHSOController

- (void)dealloc
{
    pthread_mutex_destroy(&_lock);
}

- (instancetype)initWithObject:(NSObject *)object
{
    self = [super init];
    if (self) {
        self.object = object;
        self.observerTable = [NSMapTable weakToStrongObjectsMapTable];
        pthread_mutex_init(&_lock, NULL);
    }
    return self;
}

- (void)addObserver:(NSObject *)observer selector:(SEL)selector preprocessor:(id)block
{
    if (!block) {
        return;
    }

    pthread_mutex_lock(&_lock);

    HAHSOObjectSetSOClass(self.object);
    HAHSOObjectSetMethodImplementation(self.object, selector, (IMP)HAHSOTransmissionFunction);

    NSMutableDictionary *selectorTable = [self.observerTable objectForKey:observer];
    if (!selectorTable) {
        selectorTable = [[NSMutableDictionary alloc] init];
        [self.observerTable setObject:selectorTable forKey:observer];
    }
    HAHObserveSelectorTableModel *model = selectorTable[NSStringFromSelector(selector)];
    if (!model) {
        model = [[HAHObserveSelectorTableModel alloc] init];
        selectorTable[NSStringFromSelector(selector)] = model;
    }
    [model.preprocessors addObject:[block copy]];

    pthread_mutex_unlock(&_lock);
}

- (void)addObserver:(NSObject *)observer selector:(SEL)selector postprocessor:(id)block
{
    if (!block) {
        return;
    }

    pthread_mutex_lock(&_lock);
    
    HAHSOObjectSetSOClass(self.object);
    HAHSOObjectSetMethodImplementation(self.object, selector, (IMP)HAHSOTransmissionFunction);

    NSMutableDictionary *selectorTable = [self.observerTable objectForKey:observer];
    if (!selectorTable) {
        selectorTable = [[NSMutableDictionary alloc] init];
        [self.observerTable setObject:selectorTable forKey:observer];
    }
    HAHObserveSelectorTableModel *model = selectorTable[NSStringFromSelector(selector)];
    if (!model) {
        model = [[HAHObserveSelectorTableModel alloc] init];
        selectorTable[NSStringFromSelector(selector)] = model;
    }
    [model.postprocessors addObject:[block copy]];

    pthread_mutex_unlock(&_lock);
}

- (void)removeAllObserver
{
    pthread_mutex_lock(&_lock);
    [self.observerTable removeAllObjects];
    pthread_mutex_unlock(&_lock);
}

- (void)removeObserver:(NSObject *)observer
{
    pthread_mutex_lock(&_lock);
    [self.observerTable removeObjectForKey:observer];
    pthread_mutex_unlock(&_lock);
}

- (void)removeObserver:(NSObject *)observer selector:(SEL)selector
{
    pthread_mutex_lock(&_lock);
    [self.observerTable objectForKey:observer][NSStringFromSelector(selector)] = nil;
    pthread_mutex_unlock(&_lock);
}

- (void)removePreprocessorsWithObserver:(NSObject *)observer selector:(SEL)selector
{
    pthread_mutex_lock(&_lock);
    [[self.observerTable objectForKey:observer][NSStringFromSelector(selector)].preprocessors removeAllObjects];
    pthread_mutex_unlock(&_lock);
}

- (void)removePostprocessorsWithObserver:(NSObject *)observer selector:(SEL)selector
{
    pthread_mutex_lock(&_lock);
    [[self.observerTable objectForKey:observer][NSStringFromSelector(selector)].postprocessors removeAllObjects];
    pthread_mutex_unlock(&_lock);
}

- (NSString *)debugDescription
{
    NSMutableString *s = [NSMutableString stringWithFormat:@"<%@:%p", NSStringFromClass([self class]), self];
    [s appendFormat:@" object:<%@:%p>\n", HAHSOObjectGetOriginClass(self.object), self.object];

    pthread_mutex_lock(&_lock);

    [s appendFormat:@"%@", self.observerTable];

    pthread_mutex_unlock(&_lock);
    
    [s appendString:@">"];
    return s;
}

@end


@implementation NSObject (HAHObserve)

void *HAHSOControllerKey = &HAHSOControllerKey;

- (HAHSOController *)SOController
{
    HAHSOController *controller = objc_getAssociatedObject(self, HAHSOControllerKey);
    if (!controller) {
        controller = [[HAHSOController alloc] initWithObject:self];
        objc_setAssociatedObject(self, HAHSOControllerKey, controller, OBJC_ASSOCIATION_RETAIN);
    }
    return controller;
}

- (void)addObserver:(NSObject *)observer selector:(SEL)selector preprocessor:(id)block
{
    [self.SOController addObserver:observer selector:selector preprocessor:block];
}

- (void)addObserver:(NSObject *)observer selector:(SEL)selector postprocessor:(id)block
{
    [self.SOController addObserver:observer selector:selector postprocessor:block];
}

- (void)removeAllObserver
{
    [self.SOController removeAllObserver];
}

- (void)removeObserver:(NSObject *)observer
{
    [self.SOController removeObserver:observer];
}

- (void)removeObserver:(NSObject *)observer selector:(SEL)selector
{
    [self.SOController removeObserver:observer selector:selector];
}

- (void)removePreprocessorsWithObserver:(NSObject *)observer selector:(SEL)selector
{
    [self.SOController removePreprocessorsWithObserver:observer selector:selector];
}

- (void)removePostprocessorsWithObserver:(NSObject *)observer selector:(SEL)selector
{
    [self.SOController removePostprocessorsWithObserver:observer selector:selector];
}

@end


@implementation HAHObserveSelectorTableModel

- (void)dealloc
{

}

- (NSMutableArray *)preprocessors
{
    if (!_preprocessors) {
        _preprocessors = [[NSMutableArray alloc] init];
    }
    return _preprocessors;
}

- (NSMutableArray *)postprocessors
{
    if (!_postprocessors) {
        _postprocessors = [[NSMutableArray alloc] init];
    }
    return _postprocessors;
}

@end



id HAHSOTransmissionFunction(id self, SEL _cmd, ...)
{
    Class currentClass = object_getClass(self);
    Class originClass = HAHSOObjectGetOriginClass(self);

    NSMethodSignature *methodSignature = [NSMethodSignature signatureWithObjCTypes:method_getTypeEncoding(class_getInstanceMethod(originClass, _cmd))];

    va_list ap;
    va_start(ap, _cmd);

    // 构造blockInvocation，调用block
    NSInvocation *blockInvocation = [NSInvocation invocationWithMethodSignature:methodSignature];
    blockInvocation.selector = _cmd;
    HAHSOSetArguments(blockInvocation, methodSignature, 1, &ap);

    // 调用preprocessors
    for (NSDictionary *selectorTable in [[self SOController] observerTable].objectEnumerator) {
        HAHObserveSelectorTableModel *table = selectorTable[NSStringFromSelector(_cmd)];
        for (id block in table.preprocessors) {
            blockInvocation.target = block;
            [blockInvocation invoke];
        }
    }

    va_start(ap, _cmd);
    // 调用原方法
    NSInvocation *invocation = [NSInvocation invocationWithMethodSignature:methodSignature];
    invocation.selector = _cmd;
    HAHSOSetArguments(invocation, methodSignature, 2, &ap);

    object_setClass(self, originClass);
    invocation.target = self;
    [invocation invoke];
    object_setClass(self, currentClass);


    va_end(ap);
    // 调用postprocessors
    for (NSDictionary *selectorTable in [[self SOController] observerTable].objectEnumerator) {
        HAHObserveSelectorTableModel *table = selectorTable[NSStringFromSelector(_cmd)];
        for (id block in table.postprocessors) {
            blockInvocation.target = block;
            [blockInvocation invoke];
        }
    }

    id returnValue = nil;

    if (methodSignature.methodReturnLength) {
        [invocation getReturnValue:&returnValue];
    }

    return returnValue;
}

void HAHSOSetArguments(NSInvocation *invocation, NSMethodSignature *signature, NSUInteger startIndex, va_list *ap)
{
    for (NSUInteger i = startIndex; i < signature.numberOfArguments; i++) {

        NSUInteger size;
        NSGetSizeAndAlignment([signature getArgumentTypeAtIndex:i], &size, NULL);


#define CaseSize1(aSize)\
        } else if (size <= aSize) {\
            HAHSOStruct##aSize s = va_arg(*ap, HAHSOStruct##aSize);\
            [invocation setArgument:&s atIndex:i];

#define CaseSize2(aSize)\
CaseSize1(aSize ## 0)\
CaseSize1(aSize ## 1)\
CaseSize1(aSize ## 2)\
CaseSize1(aSize ## 3)\
CaseSize1(aSize ## 4)\
CaseSize1(aSize ## 5)\
CaseSize1(aSize ## 6)\
CaseSize1(aSize ## 7)\
CaseSize1(aSize ## 8)\
CaseSize1(aSize ## 9)

#define CaseSize3(aSize)\
CaseSize2(aSize ## 0)\
CaseSize2(aSize ## 1)\
CaseSize2(aSize ## 2)\
CaseSize2(aSize ## 3)\
CaseSize2(aSize ## 4)\
CaseSize2(aSize ## 5)\
CaseSize2(aSize ## 6)\
CaseSize2(aSize ## 7)\
CaseSize2(aSize ## 8)\
CaseSize2(aSize ## 9)

        if (NO) {
        CaseSize1(1)
        CaseSize1(2)
        CaseSize1(3)
        CaseSize1(4)
        CaseSize1(5)
        CaseSize1(6)
        CaseSize1(7)
        CaseSize1(8)
        CaseSize1(9)
        CaseSize2(1)
        CaseSize2(2)
        CaseSize2(3)
        CaseSize2(4)
        CaseSize2(5)
        CaseSize2(6)
        CaseSize2(7)
        CaseSize2(8)
        CaseSize2(9)
        CaseSize3(1)
        CaseSize3(2)
        CaseSize3(3)
        CaseSize3(4)
        CaseSize3(5)
        CaseSize3(6)
        CaseSize3(7)
        CaseSize3(8)
        CaseSize3(9)
        CaseSize3(10)
        } else {
            HAHSOStruct1099 s = va_arg(*ap, HAHSOStruct1099);
            [invocation setArgument:&s atIndex:i];
        }
    }
}

BOOL HAHSOIsObjectSelectorObserved(id self)
{
    return HAHSOObjectGetSOClass(self) ? YES : NO;
}

BOOL HAHSOClassAddMethod(Class class, SEL sel, id imp)
{
    return class_addMethod(class, sel, imp_implementationWithBlock(imp), method_getTypeEncoding(class_getInstanceMethod(class_getSuperclass(class), sel)));
}

Class HAHSOObjectGetOriginClass(id self)
{
    Class soClass = HAHSOObjectGetSOClass(self);
    return soClass ? class_getSuperclass(soClass) : [self class];
}

Class HAHSOObjectGetSOClass(id self)
{
    Class class = object_getClass(self);
    while (![NSStringFromClass(class) hasPrefix:HAHSOClassPrefix]) {
        if (class == [NSObject class] || !class) {
            return nil;
        }
        class = class_getSuperclass(class);
    }
    return class;
}

BOOL HAHSOObjectSetSOClass(id self)
{
    if (!HAHSOIsObjectSelectorObserved(self)) {
        NSString *soClassString = [HAHSOClassPrefix stringByAppendingString:NSStringFromClass([self class])];
        Class soClass = NSClassFromString(soClassString);
        if (!soClass) {
            objc_registerClassPair(objc_allocateClassPair(object_getClass(self), soClassString.UTF8String, 0));
            soClass = NSClassFromString(soClassString);

            // FIXME
//            __weak typeof(self) weakSelf = self;
//            HAHSOClassAddMethod(soClass, @selector(class), ^Class(id self, SEL sel){
//                return HAHSOObjectGetOriginClass(weakSelf);
//            });
        }
        object_setClass(self, soClass);

        return YES;
    }
    return NO;
}

BOOL HAHSOObjectSetMethodImplementation(id self, SEL _cmd, IMP imp)
{
    Class originClass = HAHSOObjectGetOriginClass(self);

    NSAssert([originClass instancesRespondToSelector:_cmd], @"%@ does not response %@.", originClass, NSStringFromSelector(_cmd));

    Class soClass = HAHSOObjectGetSOClass(self);
    IMP originIMP = class_getMethodImplementation(originClass, _cmd);
    IMP soIMP = class_getMethodImplementation(soClass, _cmd);
    if (originIMP == soIMP) {
        class_addMethod(soClass, _cmd, imp, method_getTypeEncoding(class_getInstanceMethod(originClass, _cmd)));
        return YES;
    }

    return NO;
}