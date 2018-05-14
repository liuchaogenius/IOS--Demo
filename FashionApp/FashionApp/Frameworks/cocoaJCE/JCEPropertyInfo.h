//
//  JCEPropertyInfo.h
//  QQMSFContact
//
//  Created by Derek on 4/2/15.
//
//

#import <Foundation/Foundation.h>
#import "QZPropertyReflection.h"

@class JCEPair;
@interface JCEPropertyInfo : NSObject

@property (nonatomic, assign) int       tag;         // index
@property (nonatomic, assign) BOOL      dynamic;
@property (nonatomic, assign) BOOL      weak;
@property (nonatomic, assign) SEL       getter;
@property (nonatomic, assign) SEL       setter;
@property (nonatomic, assign) BOOL      required;    // required
@property (nonatomic, assign) BOOL      readonly;
@property (nonatomic, strong) NSString  *ivar;
@property (nonatomic, strong) NSString  *name;
@property (nonatomic, strong) NSString  *type;
@property (nonatomic, strong) JCEPair   *ext;        // for vector & map
@property (nonatomic, assign) BOOL      isJCE;
@property (nonatomic, assign) QZPropertyMemoryManagementPolicy memoryManagementPolicy;

@end
