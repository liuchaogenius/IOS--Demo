//
//  JceInputStreamV2.h
//
//  Created by 壬俊 易 on 12-1-13.
//  Copyright (c) 2012年 Tencent. All rights reserved.
//

#import "JceStream.h"

@class JCEPair;

@interface JceInputStreamV2 : JceStream
{
	int	_headType;
	int	_headTag;
}

@property (nonatomic, assign) int headType;
@property (nonatomic, readonly) int	headTag;

+ (JceInputStreamV2 *)streamWithData:(NSData *)data;

- (BOOL)readHead;
- (BOOL)peakHead;

- (char)readInt1;
- (short)readInt2;
- (int)readInt4;
- (long long)readInt8;
- (float)readFloat;
- (double)readDouble;
- (unsigned char *)readBytes:(unsigned int)length;
- (void)skip:(unsigned int)lenght;

// for alickwang
- (NSData *)readDataWithSize:(int)size;

- (long long)readInt:(int)tag;
- (float)readFloat:(int)tag;
- (double)readDouble:(int)tag;

- (NSNumber *)readNumber:(int)tag required:(BOOL)required;
- (NSString *)readString:(int)tag required:(BOOL)required;
- (NSData *)readData:(int)tag required:(BOOL)required;
- (id)readObject:(int)tag required:(BOOL)required description:(Class)theClass;
- (NSArray *)readArray:(int)tag required:(BOOL)required description:(id)description;
- (NSDictionary *)readDictionary:(int)tag required:(BOOL)required description:(JCEPair *)description;
- (id)readAnything:(int)tag required:(BOOL)required description:(id)description;

@end
