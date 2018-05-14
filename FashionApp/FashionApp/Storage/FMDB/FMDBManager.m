//
//  FMDBManager.m
//  PayHousekeeper
//
//  Created by 1 on 2017/1/24.
//  Copyright © 2017年 striveliu. All rights reserved.
//

#import "FMDBManager.h"

#define DBNAME    @"FashionStyle.sqlite"

@interface FMDBManager()
{
    FMDatabase *db;
    NSString *database_path;
}

@end
@implementation FMDBManager
+ (FMDBManager *)shareInstance
{
    static FMDBManager *handle = nil;
    @synchronized(self)
    {
        if(!handle)
        {
            handle = [[FMDBManager alloc] init];
        }
        return handle;
    }
    return handle;
}


- (void)openDB
{
    if (db) {
        return;
    }
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documents = [paths objectAtIndex:0];
    database_path = [documents stringByAppendingPathComponent:DBNAME];
    
    db = [FMDatabase databaseWithPath:database_path];
}

- (void)createTable:(NSString *)sqlCreateTable
{
    if (db == nil) {
        [self openDB];
    }
    
    if ([db open]) {
        BOOL res = [db executeUpdate:sqlCreateTable];
        if (!res) {
            NSLog(@"error when creating db table with %@", sqlCreateTable);
        } else {
            NSLog(@"success to creating db table");
        }
        [db close];
        
    }
}

- (BOOL) insertData:(NSString *)sqlInsert
{
    if (db == nil) {
        [self openDB];
    }
    
    if ([db open])
    {
        BOOL res = [db executeUpdate:sqlInsert];
        [db close];
        if (!res)
        {
            NSLog(@"error when insert db table");
            return NO;
        } else
        {
            NSLog(@"success to insert db table");
            return YES;
        }
    }
    
    return NO;
}

- (BOOL)deleteData:(NSString *)sqlDelete
{
    if (db == nil) {
        [self openDB];
    }
    
    if ([db open])
    {
        BOOL res = [db executeUpdate:sqlDelete];
        [db close];
        if (!res) {
            NSLog(@"error when delete db table");
            return NO;
        } else {
            NSLog(@"success to delete db table");
            return YES;
        }
    }
    return NO;
}

- (NSMutableArray *)getBlackList:(NSString *)sqlSelect
{
    if (db == nil) {
        [self openDB];
    }
    
    NSMutableArray *tmpArr = [NSMutableArray array];
    if ([db open]) {
        FMResultSet * rs = [db executeQuery:sqlSelect];
        while ([rs next])
        {
            [tmpArr addObject:[rs stringForColumn:@"accid"]];
        }
        
        [db close];
    }
    
    return tmpArr;
}

@end
