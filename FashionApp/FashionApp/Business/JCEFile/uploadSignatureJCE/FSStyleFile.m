// **********************************************************************
// This file was generated by a TAF parser!
// TAF version 3.0.0 by WSRD Tencent.
// Generated from `/Users/a1/newApp/ResStruct.jce'
// **********************************************************************

#import "FSStyleFile.h"

@implementation FSStyleFile

- (id)init
{
    if (self = [super init]) {
        JV2_PROP(suffix) = DefaultJceString;
        JV2_PROP(md5) = DefaultJceString;
    }
    return self;
}

+ (NSString*)jceType
{
    return @"Style.File";
}

@end