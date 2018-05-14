//
//  FMDBManager.h
//  PayHousekeeper
//
//  Created by 1 on 2017/1/24.
//  Copyright © 2017年 striveliu. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "FMDatabase.h"
#import "FMDatabaseQueue.h"

#define CREATEBLACKLISTTAB [NSString stringWithFormat:@"create table if not exists 'blacklist_%@' ('accid' TEXT PRIMARY KEY)", [UserInfoData shareUserInfoData].strUserId]

#define ADDBLACKLIST(uid) [NSString stringWithFormat:@"insert or ignore into 'blacklist_%@' (accid) values ('%@')", [UserInfoData shareUserInfoData].strUserId, uid]

#define DELBLACKLIST(uid) [NSString stringWithFormat:@"delete from blacklist_%@ where accid = '%@'", [UserInfoData shareUserInfoData].strUserId, uid]

#define GETBLACKLIST [NSString stringWithFormat:@"select * from blacklist_%@", [UserInfoData shareUserInfoData].strUserId]

@interface FMDBManager : NSObject

+ (FMDBManager *)shareInstance;

- (void)createTable:(NSString *)sqlCreateTable;
- (BOOL)insertData:(NSString *)sqlInsert;
- (BOOL)deleteData:(NSString *)sqlDelete;

- (NSMutableArray *)getBlackList:(NSString *)sqlSelect;

@end
