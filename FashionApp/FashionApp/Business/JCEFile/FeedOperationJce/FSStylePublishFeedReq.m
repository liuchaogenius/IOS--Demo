// **********************************************************************
// This file was generated by a TAF parser!
// TAF version 3.0.0 by WSRD Tencent.
// Generated from `/Users/a1/newApp/FeedOperation.jce'
// **********************************************************************

#import "FSStylePublishFeedReq.h"

@implementation FSStylePublishFeedReq

- (id)init
{
    if (self = [super init]) {
        JV2_PROP(upload_id) = DefaultJceString;
    }
    return self;
}

+ (NSString*)jceType
{
    return @"Style.PublishFeedReq";
}

@end
