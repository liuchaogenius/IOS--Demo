//
//  FSUploadPictureService.h
//  FashionApp
//
//  Created by 1 on 2018/4/24.
//  Copyright © 2018年 1. All rights reserved.
//

#import "FSBaseNetworkService.h"

typedef  void(^UploadPicFinishBlock)(NSDictionary *dict, NSError *error);
typedef  void(^UploadPictProcessBlock)(long bytesSent, long totalBytesSent, long totalBytesExpectedToSend);

@interface FSUploadFile : FSBaseNetworkService

- (void)signatureInfo:(NSDictionary *)aDict fileMD5:(NSDictionary *)fileMD5Dict;

- (void)clearUploadFinishData;

- (void)uploadFilePath:(NSString *)filePath
                  process:(UploadPictProcessBlock)processBlock
                   finish:(UploadPicFinishBlock)finishBlock;

- (void)cancelUpload:(NSArray *)filePaths;

@end
