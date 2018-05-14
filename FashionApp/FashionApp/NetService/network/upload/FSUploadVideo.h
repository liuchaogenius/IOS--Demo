//
//  FSUploadNetWorkService.h
//  FashionApp
//
//  Created by 1 on 2018/4/23.
//  Copyright © 2018年 1. All rights reserved.
//

#import "FSBaseNetworkService.h"

@interface FSUploadVideo : FSBaseNetworkService

- (NSString *)getVideoPath;

- (UIImage *)coverImage;

- (BOOL)enableHTTPS;

- (BOOL)enableResume;

- (void)signatureInfo:(NSDictionary *)aDict;

- (void)upLoadVideoPath:(NSString *)videoPath
                 result:(void(^)(NSDictionary *result, NSError *error))resultBlock
                 procee:(void(^)(NSInteger bytesUpload, NSInteger bytesTotal))processBlock;

- (void)cancelUpload;

@end
