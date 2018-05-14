//
//  JCEObjectConverter.h
//  PayCenterSSO
//
//  Created by sfelixzhu(朱仕达) on 2017/4/17.
//  Copyright © 2017年 tencent. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "JceObjectV2.h"

extern NSDictionary* convertJceObjectToDic(JceObject *object);
extern JceObjectV2* convertDicToJceObject(NSDictionary *originDic,Class jceClass);
extern NSData *creatCommonPacketWithServantName(NSString *servantName, NSString *funcName, NSString *attrName, JceObjectV2 *attrValue);
extern NSDictionary* parseWUPData(NSData *data,NSString *attrName,NSString *jceClass);

