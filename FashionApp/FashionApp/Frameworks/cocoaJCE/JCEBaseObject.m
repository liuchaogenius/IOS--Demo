
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wbuiltin-macro-redefined"
#define __FILE__ "JCEBaseObject"
#pragma clang diagnostic pop

//
//  JCEBaseObject.m
//  QQMSFContact
//
//  Created by Derek on 4/1/15.
//
//

#import "JCEBaseObject.h"

#import "JCEPair.h"
#import "JceObjectV2.h"
#import "JCEPropertyInfo.h"
#import <pthread.h>
#import <CoreGraphics/CoreGraphics.h>



#pragma mark - Macros

#ifdef DEBUG

#define ASSIGN_GETTER_IMP(type) \
    imp_implementationWithBlock(^(id receiver) { \
        JCEWhileLocked(^{ \
            NSMutableSet *properties = gAccessedProperties[NSStringFromClass(dynamicClass)] ?: [NSMutableSet set]; \
            [properties addObject:NSStringFromSelector(info.getter)]; \
            gAccessedProperties[NSStringFromClass(dynamicClass)] = properties; \
        }); \
        char *ptr = ((char *)(__bridge void *)receiver) + offset; \
        type value; \
        memcpy(&value, ptr, sizeof(value)); \
        return value; \
})

#else

#define ASSIGN_GETTER_IMP(type) \
    imp_implementationWithBlock(^(id receiver) { \
    char *ptr = ((char *)(__bridge void *)receiver) + offset; \
    type value; \
    memcpy(&value, ptr, sizeof(value)); \
    return value; \
})

#endif



#define ASSIGN_SETTER_IMP(type) \
    imp_implementationWithBlock(^(id receiver, type value) { \
        char *ptr = ((char *)(__bridge void *)receiver) + offset; \
        memcpy(ptr, (void *)&value, sizeof(value)); \
    })

#define SETTER_ENCODING(type) \
    CZ_NSString_stringWithFormat_c("%s%s%s%s", @encode(void), @encode(id), @encode(SEL), @encode(type));

#define GETTER_ENCODING(type) \
    CZ_NSString_stringWithFormat_c("%s%s%s", @encode(type), @encode(id), @encode(SEL));

NSString *JCEDynamicSubclassPrefix = @"JCEBaseObject_";

static pthread_mutex_t gMutex;

static void JCEWhileLocked(void (^block)(void)) {
    pthread_mutex_lock(&gMutex);
    block();
    pthread_mutex_unlock(&gMutex);
}

static NSMutableDictionary *gAccessedProperties = nil;

@implementation JCEBaseObject

#ifdef DEBUG

+ (void)load {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        gAccessedProperties = [[NSMutableDictionary dictionary] retain];
    });
}

+ (NSArray *)dumpUnusedProperties {
    NSSet *accessedProperties = gAccessedProperties[[NSString stringWithFormat:@"JCEBaseObject_%@", NSStringFromClass([self class])]];
    NSMutableArray *result = [NSMutableArray new];
    [self.class.propertyInfos enumerateObjectsUsingBlock:^(JCEPropertyInfo *info, NSUInteger idx, BOOL * _Nonnull stop) {
        if (![accessedProperties containsObject:NSStringFromSelector(info.getter)] && info.isJCE) {
            [result addObject:NSStringFromSelector(info.getter)];
        }
    }];
    
    return result;
}

#endif

+ (void)enumeratePropertiesUsingBlock:(void (^)(objc_property_t property, BOOL *stop))block
{
    Class cls = self;
    BOOL stop = NO;

    while (!stop && ![cls isEqual:JCEBaseObject.class]) {
        unsigned count = 0;
        objc_property_t *properties = class_copyPropertyList(cls, &count);

        cls = cls.superclass;
        if (properties == NULL) continue;

        for (unsigned i = 0; i < count; i++) {
            block(properties[i], &stop);
            if (stop) break;
        }

        free(properties);
    }
}

+ (void)initialize
{
    if (self == [JCEBaseObject class]) {
        pthread_mutexattr_t mutexattr;
        pthread_mutexattr_init(&mutexattr);
        pthread_mutexattr_settype(&mutexattr, PTHREAD_MUTEX_RECURSIVE);
        pthread_mutex_init(&gMutex, &mutexattr);
        pthread_mutexattr_destroy(&mutexattr);
    }
}

+ (id)allocWithZone:(NSZone*)zone
{
    __block Class dynamicClass = Nil;

    JCEWhileLocked(^{
        dynamicClass = [self setupDynamicClass];
    });

    if (!dynamicClass) {
        // QQ_EVENT("[JCEBaseObject] Faile to setup dynamic subclass for: %s. Retry!", class_getName(self.class));

        JCEWhileLocked(^{
            dynamicClass = [self setupDynamicClass];
        });

        if (!dynamicClass) {
            // QQ_EVENT("[JCEBaseObject] Faile to setup dynamic subclass for: %s", class_getName(self.class));
            @throw [NSException exceptionWithName:@"JCEBaseObjectException"
                                           reason:[NSString stringWithFormat:@"Faile to setup dynamic subclass for: %@", self.class]
                                         userInfo:nil];
        }
    }

    return NSAllocateObject(dynamicClass, 0, zone);
}

+ (instancetype)fromJCEObject:(JCEBaseObject *)obj {
    JCEBaseObject *clone = [[[self alloc] init] autorelease];
    
    [[self.class propertyInfos] enumerateObjectsUsingBlock:^(JCEPropertyInfo *info, NSUInteger idx, BOOL *stop) {
        if (!info.isJCE) return;

        NSString *key = info.name;
        id value = nil;
        @try {
            value = [obj valueForKey:key];
        }
        @catch (NSException *exception) {
            value = nil;
        }
        
        if (!value) {
            return;
        }
        
        [clone setValue:value forKey:key];
    }];
    
    return clone;
}

- (void)setDefaultValueForJCEProperty:(JCEPropertyInfo *)info {
    if (!info.isJCE) {
        return;
    }
    
    NSString *type = info.type;
    NSString *name = info.name;
    if ([type UTF8String][0] != _C_ID) {
        return;
    }
    
    if ([type isEqualToString:@"@\"NSString\""]) {
        [self setValue:DefaultJceString forKey:name];
        return;
    }
        
    if (!info.required || info.memoryManagementPolicy != QZPropertyMemoryManagementPolicyRetain) {
        return;
    }
    
    if ([type isEqualToString:@"@\"NSArray\""]) {
        [self setValue:DefaultJceArray forKey:name];
        return;
    }
    
    if ([type isEqualToString:@"@\"NSDictionary\""]) {
        [self setValue:DefaultJceDictionary forKey:info.name];
        return;
    }
    
    if ([type isEqualToString:@"@\"NSData\""]) {
        [self setValue:DefaultJceData forKey:info.name];
        return;
    }
    
    Class klass = NSClassFromString([type substringWithRange:NSMakeRange(2, [type length] - 3)]);
    id defaultValue = [[[klass alloc] init] autorelease];
    
    if (!defaultValue) {
        return;
    }
        
    [self setValue:defaultValue forKey:info.name];
}

#if JCE_USE_DYNAMIC_INITIALIZATION
- (instancetype)init
{
    if ((self = [super init])) {
        [[self.class propertyInfos] enumerateObjectsUsingBlock:^(JCEPropertyInfo *info, NSUInteger idx, BOOL *stop) {
            [self setDefaultValueForJCEProperty:info];
        }];
    }

    return self;
}
#endif

- (void)dealloc
{
    [self.class.propertyInfos enumerateObjectsUsingBlock:^(JCEPropertyInfo *info, NSUInteger idx, BOOL *stop) {
        BOOL copied   = info.memoryManagementPolicy == QZPropertyMemoryManagementPolicyCopy;
        BOOL retained = info.memoryManagementPolicy == QZPropertyMemoryManagementPolicyRetain;

        if (info.dynamic && (copied || retained)) {
            [self setValue:nil forKey:info.name];
        }
    }];

    [super dealloc];
}

#pragma mark -

static void *JCECachedPropertyInfosKey = &JCECachedPropertyInfosKey;

+ (NSOrderedSet *)propertyInfos
{
    NSOrderedSet *cachedInfos = objc_getAssociatedObject(self, JCECachedPropertyInfosKey);

    if (cachedInfos) return cachedInfos;

    NSMutableOrderedSet *infos = [NSMutableOrderedSet orderedSet];

    [self enumeratePropertiesUsingBlock:^(objc_property_t property, BOOL *stop) {
        QZPropertyAttributes *attributes = QZCopyPropertyAttributes(property);

        if (!attributes) {
            return;
        }

        if (attributes->readonly && attributes->ivar == NULL) {
            free(attributes);
            return;
        }

        JCEPropertyInfo *info       = [[[JCEPropertyInfo alloc] init] autorelease];
        info.name                   = @(property_getName(property) ?: "");
        info.type                   = @(attributes->type ?: "");
        info.readonly               = attributes->readonly;
        info.ivar                   = attributes->ivar ? @(attributes->ivar) : nil;
        info.dynamic                = attributes->dynamic;
        info.weak                   = attributes->weak;
        info.getter                 = attributes->getter;
        info.setter                 = attributes->setter;
        info.memoryManagementPolicy = attributes->memoryManagementPolicy;
        info.isJCE                  = [info.name hasPrefix:JV2_PROP_LFX_STR];

        if (info.isJCE) {
            NSString *propertyName = info.name;
            NSRange range = [propertyName rangeOfString:JCEV2_PROPERTY_NAME_SP];

            if (range.location != NSNotFound) {
                info.ext = [JCEPair pairFromExtString:[propertyName substringFromIndex:(range.location + range.length)]];
                propertyName = [propertyName substringToIndex:range.location];
            }

            NSArray *components = [propertyName componentsSeparatedByString:@"_"];

            if (components.count < 5) {
                // QQ_EVENT("[JCEBaseObject] Invalid JCE ext string: %s", [propertyName UTF8String]);
                @throw [NSException exceptionWithName:@"JCEBaseObjectException"
                                               reason:[NSString stringWithFormat:@"Invalid JCE ext string: %@", propertyName]
                                             userInfo:nil];
            }

            info.tag      = [components[2] intValue];
            info.required = [components[3] isEqualToString:@"r"];
        }

        [infos addObject:info];

        free(attributes);
    }];

    [infos sortUsingComparator:^NSComparisonResult(JCEPropertyInfo *obj1, JCEPropertyInfo *obj2) {
        if (obj1.tag < obj2.tag)
            return NSOrderedAscending;
        else if (obj1.tag == obj2.tag)
            return NSOrderedSame;
        else
            return NSOrderedDescending;
    }];

    objc_setAssociatedObject(self, JCECachedPropertyInfosKey, infos, OBJC_ASSOCIATION_COPY);
    
    return infos;
}

+ (Class)setupDynamicClass
{
    NSString *className = NSStringFromClass(self);

    if ([className hasPrefix:JCEDynamicSubclassPrefix]) {
        return objc_getClass([className UTF8String]);
    }

//    const char *dynamicClassName = [[NSString stringWithFormat:@"%@%@", JCEDynamicSubclassPrefix, className] UTF8String];
    char dynamicClassName[200];
    sprintf(dynamicClassName, "%s%s",[JCEDynamicSubclassPrefix UTF8String],[className UTF8String]);
    Class dynamicClass = objc_getClass(dynamicClassName);

    if (dynamicClass) {
        return dynamicClass;
    }

    dynamicClass = objc_allocateClassPair(self, dynamicClassName, 0);

    if (dynamicClass == Nil) {
        // 可能类名已经被使用了，重新获取一次
        dynamicClass = objc_getClass(dynamicClassName);
        if (dynamicClass == Nil) {
            return Nil;
        }
    }

    [[self propertyInfos] enumerateObjectsUsingBlock:^(JCEPropertyInfo *info, NSUInteger idx, BOOL *stop) {
        // 只有声明为 @dynamic 的 property 才需要动态添加 accessors
        if (!info.dynamic) {
            return;
        }

        if (info.type.length == 0) {
            return;
        }

        NSUInteger propertySize = 0;
        NSUInteger propertyAlignment = 0;

        const char *type = [info.type UTF8String];

        NSGetSizeAndAlignment(type, &propertySize, &propertyAlignment);
        
        NSString *ivarName = [NSString stringWithFormat:@"_%@", info.name];

		const BOOL didAddIvar = class_addIvar(dynamicClass, [ivarName UTF8String],
                                              propertySize, log2(propertyAlignment), type);
        if (!didAddIvar) {
            return;
        }

        // Add getter & setter implementation
        Ivar ivar         = class_getInstanceVariable(dynamicClass, [ivarName UTF8String]);
        ptrdiff_t offset  = ivar_getOffset(ivar);

        if (info.getter) {
            if (class_getInstanceMethod(self, info.getter)) {
                return;
            }
            
            IMP imp = NULL;

            switch (type[0]) {
                case _C_ID: {
                    if (info.weak) {
                        imp = imp_implementationWithBlock(^(id receiver) {
#ifdef DEBUG
                            JCEWhileLocked(^{
                                NSMutableSet *properties = gAccessedProperties[NSStringFromClass(dynamicClass)] ?: [NSMutableSet set];
                                [properties addObject:NSStringFromSelector(info.getter)];
                                gAccessedProperties[NSStringFromClass(dynamicClass)] = properties;
                            });
#endif
                            char *ptr = ((char *)(void *)receiver) + offset;
                            return objc_loadWeak((id *)(void *)ptr);
                        });
                    } else {
                        imp = imp_implementationWithBlock(^(id receiver) {
#ifdef DEBUG
                            JCEWhileLocked(^{
                                NSMutableSet *properties = gAccessedProperties[NSStringFromClass(dynamicClass)] ?: [NSMutableSet set];
                                [properties addObject:NSStringFromSelector(info.getter)];
                                gAccessedProperties[NSStringFromClass(dynamicClass)] = properties;
                            });
#endif
                            
                            Ivar ivar = class_getInstanceVariable(dynamicClass, [ivarName UTF8String]);
                            return object_getIvar(receiver, ivar);
                        });
                    }
                } break;

                case _C_CHR:      { imp = ASSIGN_GETTER_IMP(char);               } break;
                case _C_INT:      { imp = ASSIGN_GETTER_IMP(int);                } break;
                case _C_SHT:      { imp = ASSIGN_GETTER_IMP(short);              } break;
                case _C_LNG:      { imp = ASSIGN_GETTER_IMP(long);               } break;
                case _C_LNG_LNG:  { imp = ASSIGN_GETTER_IMP(long long);          } break;
                case _C_UCHR:     { imp = ASSIGN_GETTER_IMP(unsigned char);      } break;
                case _C_UINT:     { imp = ASSIGN_GETTER_IMP(unsigned int);       } break;
                case _C_USHT:     { imp = ASSIGN_GETTER_IMP(unsigned short);     } break;
                case _C_ULNG:     { imp = ASSIGN_GETTER_IMP(unsigned long);      } break;
                case _C_ULNG_LNG: { imp = ASSIGN_GETTER_IMP(unsigned long long); } break;
                case _C_FLT:      { imp = ASSIGN_GETTER_IMP(float);              } break;
                case _C_DBL:      { imp = ASSIGN_GETTER_IMP(double);             } break;
                case _C_BOOL:     { imp = ASSIGN_GETTER_IMP(bool);               } break;
                case _C_STRUCT_B: {
                    if (strcmp(type, @encode(CGRect)) == 0)  { imp = ASSIGN_GETTER_IMP(CGRect);  break;  }
                    if (strcmp(type, @encode(CGSize)) == 0)  { imp = ASSIGN_GETTER_IMP(CGSize);  break;  }
                    if (strcmp(type, @encode(CGPoint)) == 0) { imp = ASSIGN_GETTER_IMP(CGPoint); break; }
                    if (strcmp(type, @encode(NSRange)) == 0) { imp = ASSIGN_GETTER_IMP(NSRange); break; }
                }; // Don't break here

                default: {
                    @throw [NSException exceptionWithName:@"JCEBaseObjectException"
                                                   reason:[NSString stringWithFormat:@"[%@ - %@]Type %@ hasn't implemented yet", self.class, ivarName, @(type)]
                                                 userInfo:nil];
                } break;
            }

            // http://stackoverflow.com/a/11527925
            NSString *encoding = nil;
            if (type[0] != _C_STRUCT_B) {
                encoding = [NSString stringWithFormat:@"%c@:", type[0]];
            } else {
                encoding = [NSString stringWithFormat:@"%s@:", type];
            }

            class_addMethod(dynamicClass, info.getter, imp, [encoding UTF8String]);
        }

        if (info.setter) {
            IMP imp = NULL;
            
            if (class_getInstanceMethod(self, info.setter)) {
                return;
            }

            switch (type[0]) {
                case _C_ID: {
                    // assign or weak
                    if (info.memoryManagementPolicy == QZPropertyMemoryManagementPolicyAssign) {
                        if (info.weak) {
                            imp = imp_implementationWithBlock(^(id receiver, id value) {
                                char *ptr = ((char *)(__bridge void *)receiver) + offset;
                                objc_storeWeak((__autoreleasing id *)(void *)ptr, value);
                            });
                        } else {
                            imp = ASSIGN_SETTER_IMP(id);
                        }

                        break;
                    }

                    // storng or copy
                    BOOL needsCopy = (info.memoryManagementPolicy == QZPropertyMemoryManagementPolicyCopy);
                            //leak--
                    imp = imp_implementationWithBlock(^(id receiver, id value) {
                        Ivar ivar = class_getInstanceVariable([receiver class], [ivarName UTF8String]);
                        id oldValue = object_getIvar(receiver, ivar);
                        if (oldValue == value) return;
                        object_setIvar(receiver, ivar, needsCopy ? [value copy] : [value retain]);
                        [oldValue release];
                    });
                } break;

                case _C_CHR:      { imp = ASSIGN_SETTER_IMP(char);               } break;
                case _C_INT:      { imp = ASSIGN_SETTER_IMP(int);                } break;
                case _C_SHT:      { imp = ASSIGN_SETTER_IMP(short);              } break;
                case _C_LNG:      { imp = ASSIGN_SETTER_IMP(long);               } break;
                case _C_LNG_LNG:  { imp = ASSIGN_SETTER_IMP(long long);          } break;
                case _C_UCHR:     { imp = ASSIGN_SETTER_IMP(unsigned char);      } break;
                case _C_UINT:     { imp = ASSIGN_SETTER_IMP(unsigned int);       } break;
                case _C_USHT:     { imp = ASSIGN_SETTER_IMP(unsigned short);     } break;
                case _C_ULNG:     { imp = ASSIGN_SETTER_IMP(unsigned long);      } break;
                case _C_ULNG_LNG: { imp = ASSIGN_SETTER_IMP(unsigned long long); } break;
                case _C_FLT:      { imp = ASSIGN_SETTER_IMP(float);              } break;
                case _C_DBL:      { imp = ASSIGN_SETTER_IMP(double);             } break;
                case _C_BOOL:     { imp = ASSIGN_SETTER_IMP(bool);               } break;
                case _C_STRUCT_B: {
                    if (strcmp(type, @encode(CGRect)) == 0)  { imp = ASSIGN_SETTER_IMP(CGRect);  break; }
                    if (strcmp(type, @encode(CGSize)) == 0)  { imp = ASSIGN_SETTER_IMP(CGSize);  break; }
                    if (strcmp(type, @encode(CGPoint)) == 0) { imp = ASSIGN_SETTER_IMP(CGPoint); break; }
                    if (strcmp(type, @encode(NSRange)) == 0) { imp = ASSIGN_SETTER_IMP(NSRange); break; }
                }; // Don't break here!

                default: {
                    @throw [NSException exceptionWithName:@"JCEBaseObjectException"
                                                   reason:[NSString stringWithFormat:@"[%@ - %@]Type %@ hasn't implemented yet", self.class, ivarName, @(type)]
                                                 userInfo:nil];
                } break;
            }

            NSString *encoding = NULL;
            if (type[0] != _C_STRUCT_B) {
                encoding = [NSString stringWithFormat:@"v@:%c", type[0]];
            } else {
                encoding = [NSString stringWithFormat:@"v@:%s", type];
            }

            class_addMethod(dynamicClass, info.setter, imp, [encoding UTF8String]);
        }
    }];

    objc_registerClassPair(dynamicClass);

    return dynamicClass;
}

@end
