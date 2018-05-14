//
//  JceOutputStreamV2.h
//
//  Created by 壬俊 易 on 12-1-13.
//  Copyright (c) 2012年 Tencent. All rights reserved.
//

#import "JceStream.h"

@class JCEPair;
@interface JceOutputStreamV2 : JceStream

+ (JceOutputStreamV2 *)stream;
+ (JceOutputStreamV2 *)streamWithCapability:(int)capability;

- (void)writeTag:(int)tag type:(int)type;
- (void)writeInt1:(char)val;
- (void)writeInt2:(short)val;
- (void)writeInt4:(int)val;
- (void)writeInt8:(long long)val;
- (void)writeBytes:(const void *)data size:(int)size;

- (void)writeInt:(long long)val tag:(int)tag;
- (void)writeFloat:(float)val tag:(int)tag;
- (void)writeDouble:(double)val tag:(int)tag;

- (void)writeDictionary:(NSDictionary *)dictionary tag:(int)tag required:(BOOL)required ext:(JCEPair *)ext;
- (void)writeArray:(NSArray *)array tag:(int)tag required:(BOOL)required ext:(JCEPair *)ext;
- (void)writeNumber:(NSNumber *)number tag:(int)tag required:(BOOL)required;
- (void)writeObject:(JceObject *)object tag:(int)tag required:(BOOL)required;
- (void)writeString:(NSString *)string tag:(int)tag required:(BOOL)required;
- (void)writeData:(NSData *)data tag:(int)tag required:(BOOL)required;
- (void)writeAnything:(id)anything tag:(int)tag required:(BOOL)required ext:(JCEPair *)ext;

@end
