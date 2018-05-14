//
//  JceObjectV2+JceType.m
//  QQMSFContact
//
//  Created by Derek on 16/06/2017.
//
//

#import "JceObjectV2+JceType.h"

#import <dlfcn.h>
#import <mach-o/dyld.h>
#import <mach-o/getsect.h>

@implementation JceObjectV2 (JceType)

static bool is_all_upper(const char *input) {
    if (!input) return false;
    
    bool result = true;
    for (size_t i = 0; i < strlen(input); i++) {
        if (isalpha(input[i])) {
            result = result && isupper(input[i]);
            if (!result) break;
        }
    }
    
    return result;
}

#if defined(__has_feature)
#if __has_feature(address_sanitizer)
#define JCE_NO_ASAN __attribute__((no_sanitize("address")))
#else
#define JCE_NO_ASAN
#endif
#else
#define JCE_NO_ASAN
#endif

static NSDictionary * JCETypeInSection(const char *sectionName, NSMutableDictionary *outJCETypes, BOOL requireNamespace) JCE_NO_ASAN {
    if (!sectionName) {
        return nil;
    }
    
    Dl_info info;
    dladdr(&JCETypeInSection, &info);
    
#ifdef __LP64__
    typedef uint64_t ExportValue;
    typedef struct section_64 ExportSection;
#define GetSectByNameFromHeader getsectbynamefromheader_64
#else
    typedef uint32_t ExportValue;
    typedef struct section ExportSection;
#define GetSectByNameFromHeader getsectbynamefromheader
#endif
    
    const ExportValue mach_header = (ExportValue)info.dli_fbase;
    const ExportSection *section = GetSectByNameFromHeader((void *)mach_header, "__DATA", sectionName);
    
    if (section == NULL) {
        return nil;
    }
    
    for (ExportValue addr = section->offset; addr < (section->offset + section->size); addr += sizeof(const char **)) {
        const char **entries = (const char **)(mach_header + addr);
        
        if (!entries[0] || strlen(entries[0]) == 0) {
            continue;
        }
        
        char *dup = NULL;
        char *to_free = NULL;
        char *namespace = NULL;
        char *struct_name = NULL;
        char *namespace_to_free = NULL;
        
        dup = to_free = strdup(entries[0]);
        
        namespace = strsep(&dup, ".");
        struct_name = dup;
        
        NSMutableString *className = [NSMutableString stringWithString:@"QZJ"];
        
        if (!requireNamespace) {
            namespace = strdup([[[NSString stringWithUTF8String:namespace]
                                 stringByReplacingOccurrencesOfString:@"NS_MOBILE"
                                 withString:@""] UTF8String]);
            namespace_to_free = namespace;
        }
        
        if (namespace) {
            char *token = NULL;
            bool all_upper = is_all_upper(namespace);
            
            while ((token = strsep(&namespace, "_")) != NULL) {
                for (size_t i = 0; i < strlen(token); i++) {
                    if (all_upper) token[i] = tolower(token[i]);
                }
                
                token[0] = toupper(token[0]);
                [className appendFormat:@"%s", token];
            }
        }
        
        if (struct_name) {
            char *token = NULL;
            bool all_upper = is_all_upper(struct_name);
            
            while ((token = strsep(&struct_name, "_")) != NULL) {
                for (size_t i = 0; i < strlen(token); i++) {
                    if (all_upper) token[i] = tolower(token[i]);
                }
                
                token[0] = toupper(token[0]);
                [className appendFormat:@"%s", token];
            }
        }
        
        free(to_free);
        if (namespace_to_free) {
            free(namespace_to_free);
        }
        
#ifdef DEBUG
        assert(NSClassFromString(className));
#endif
        
        outJCETypes[className] = @(entries[0]);
    }
    
    return outJCETypes;
}

static NSDictionary *JCETypes(void) {
    static NSMutableDictionary *types = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        types = [NSMutableDictionary dictionary];
        JCETypeInSection("JCEType", types, NO);
        JCETypeInSection("JCETypeNS", types, YES);
    });
    
    return types;
}

+ (NSString *)jceType
{
    NSString *className = [NSStringFromClass(self) stringByReplacingOccurrencesOfString:@"JCEBaseObject_" withString:@""];
    NSString *typeName = [JCETypes() objectForKey:className];
    if (!typeName) {
#ifdef DEBUG
        assert(0);
#endif
    }
    
    return typeName;
}

- (NSString *)jceType
{
    return [[self class] jceType];
}


@end
