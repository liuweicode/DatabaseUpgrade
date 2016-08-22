//
//  DBExecuter.m
//  DatabaseUpgrade
//
//  Created by 刘伟 on 16/5/19.
//  Copyright © 2016年 上海凌晋信息技术有限公司. All rights reserved.
//

#import "DBExecuter.h"
#import "FMDB.h"
#import "MTLFMDBAdapter.h"

static FMDatabaseQueue *_dn_db_manager_queue;
static NSOperationQueue *_dn_db_manager_writeQueue;
static NSRecursiveLock *_dn_db_manager_writeQueueLock;

@implementation DBExecuter

-(id)initWith:(NSString*)dbPath
{
    if(self == [super init] )
    {
        _dn_db_manager_queue = [FMDatabaseQueue databaseQueueWithPath:dbPath];
        _dn_db_manager_writeQueue = [NSOperationQueue new];
        [_dn_db_manager_writeQueue setMaxConcurrentOperationCount:1];
        _dn_db_manager_writeQueueLock = [NSRecursiveLock new];
    }
    return self;
}

/**
 *  数据库是否存在表
 *
 *  @param tableName 表名称
 *
 *  @return YES / NO
 */
- (BOOL)tableExistsWithName:(NSString *)tableName
{
    __block int exists = NO;

    NSString *sql = [NSString stringWithFormat:
                     @"SELECT COUNT(*) as 'COUNT' FROM SQLITE_MASTER \
                     WHERE TYPE = 'table' AND NAME = '%@'"
                     ,tableName];
    
    BOOL tryLock = NO;
    @try {
        [_dn_db_manager_writeQueueLock lock];
        tryLock = YES;
        [_dn_db_manager_queue inDatabase:^(FMDatabase *db) {
            
            FMResultSet *resultSet = nil;
            @try {
                db.logsErrors = YES;
                resultSet = [db executeQuery:sql];
                
                if (resultSet && [resultSet next]) {
                    
                    int count = [resultSet intForColumn:@"COUNT"];
                    if(count > 0) exists = YES;
                    
                }
            }
            @catch (NSException *exception) {
#ifdef DEBUG
                NSLog(@"%@",[exception description]);
#endif
            }
            @finally {
                if (resultSet) {
                    [resultSet close];
                    resultSet = nil;
                }
            }
            
        }];
    }
    @catch (NSException *exception) {
        NSLog(@"\r\n执行SQL:%@ 报错信息:%@\r\n",sql,[exception description]);
    }
    @finally {
        if (tryLock) {
            [_dn_db_manager_writeQueueLock unlock];
        }
    }
    
    return exists;
    
}

/**
 *  数据库表是否存在某字段
 *
 *  @param tableName  表明
 *  @param columnName 字段名
 *
 *  @return YES / NO
 */
- (BOOL)columnExistsWithTableName:(NSString *)tableName columnName:(NSString *)columnName
{
    __block NSMutableArray *allColumns = nil;
    
    NSString *sql = [NSString stringWithFormat:@"SELECT * FROM %@ LIMIT 0 OFFSET 0",tableName];
    
    BOOL tryLock = NO;
    @try {
        [_dn_db_manager_writeQueueLock lock];
        tryLock = YES;
        [_dn_db_manager_queue inDatabase:^(FMDatabase *db) {
            
            FMResultSet *resultSet = nil;
            @try {
                db.logsErrors = YES;
                resultSet = [db executeQuery:sql];
                
                if (resultSet) allColumns = [NSMutableArray arrayWithArray:resultSet.columnNameToIndexMap.allKeys];
            }
            @catch (NSException *exception) {
#ifdef DEBUG
                NSLog(@"%@",[exception description]);
#endif
            }
            @finally {
                if (resultSet) {
                    [resultSet close];
                    resultSet = nil;
                }
            }
            
        }];
    }
    @catch (NSException *exception) {
#ifdef DEBUG
        NSLog(@"\r\n执行SQL:%@ 报错信息:%@\r\n",sql,[exception description]);
#endif
    }
    @finally {
        if (tryLock) {
            [_dn_db_manager_writeQueueLock unlock];
        }
    }
    
    return [allColumns containsObject:columnName];
}

/**
 *  执行SQL语句
 *
 *  @param sql  sql语句
 *  @param args 参数
 *
 *  @return 执行成功与否
 */
-(void)executeUpdate:(NSString*)sql withArgumentsInArray:(NSArray*)args
{
    [_dn_db_manager_writeQueue addOperationWithBlock:^{
    
        BOOL tryLock = NO;
        @try {
            [_dn_db_manager_writeQueueLock lock];
            tryLock = YES;
            [_dn_db_manager_queue inDatabase:^(FMDatabase *db) {
                
                @try {
                    db.logsErrors = YES;
                    
                    BOOL excuteResult = [db executeUpdate:sql withArgumentsInArray:args];
                    
                    if (!excuteResult) {
#ifdef DEBUG
                        NSLog(@"\r\n执行SQL:%@ 参数:%@ 报错信息:%@\r\n",sql,args,[db lastError]);
#endif
                    }
                }
                @catch (NSException *exception) {
#ifdef DEBUG
                    NSLog(@"%@",[exception description]);
#endif
                }
                @finally {
                    
                }
                
            }];
        }
        @catch (NSException *exception) {
#ifdef DEBUG
            NSLog(@"\r\n执行SQL:%@ 参数:%@ 报错信息:%@\r\n",sql,args,[exception description]);
#endif
        }
        @finally {
            if (tryLock) {
                [_dn_db_manager_writeQueueLock unlock];
            }
        }
    }];
}

/**
 *  在事务中之行SQL语句
 *
 *  @param transactionBlock 回调
 *
 *  @return 执行成功与否
 */
-(void)executeUpdate:(DNDBInTransaction)transactionBlock
{
    [_dn_db_manager_writeQueue addOperationWithBlock:^{
    
        BOOL tryLock = NO;
        @try {
            [_dn_db_manager_writeQueueLock lock];
            tryLock = YES;
            [_dn_db_manager_queue inTransaction:^(FMDatabase *db, BOOL *rollback) {
                
                @try {
                    db.logsErrors = YES;
                    
                    BOOL excuteResult = transactionBlock(db);
                    
                    if (!excuteResult) {
#ifdef DEBUG
                       NSLog(@"\r\n报错信息:%@\r\n",[db lastError]);
#endif
                       *rollback = YES;
                    }
                }
                @catch (NSException *exception) {
#ifdef DEBUG
                    NSLog(@"%@",[exception description]);
#endif
                    *rollback = YES;
                }
                @finally {
                    
                }
                
            }];
        }
        @catch (NSException *exception) {
#ifdef DEBUG
            NSLog(@"%@",[exception description]);
#endif
        }
        @finally {
            if (tryLock) {
                [_dn_db_manager_writeQueueLock unlock];
            }
        }
    }];
}

/**
 *  查询数据库
 *
 *  @param sql  sql语句
 *  @param args 参数
 *  @param cls  映射的类
 *
 *  @return 查后后的数组
 */
-(NSMutableArray*)executeQuery:(NSString*)sql withArgumentsInArray:(NSArray*)args withClass:(Class)cls
{
    __block NSMutableArray *resultArray = nil;
    
        BOOL tryLock = NO;
        @try {
            [_dn_db_manager_writeQueueLock lock];
            tryLock = YES;
            [_dn_db_manager_queue inDatabase:^(FMDatabase *db) {
                
                FMResultSet *resultSet = nil;
                @try {
                    db.logsErrors = YES;
                    resultSet = [db executeQuery:sql withArgumentsInArray:args];
                    
                    if (resultSet) {
                        
                        resultArray = [NSMutableArray array];
                        
                        while([resultSet next]) {
                            
                            NSError *error = nil;
                            
                            id model = [MTLFMDBAdapter modelOfClass:cls fromFMResultSet:resultSet error:&error];
                            
                            if (error) {
#ifdef DEBUG
                                NSLog(@"\r\n执行SQL:%@ 参数:%@ 转换对象 报错信息:%@\r\n",sql,args,[error description]);
#endif
                            }else{
                                [resultArray addObject:model];
                            }
                        }
                    }else{
#ifdef DEBUG
                        NSLog(@"\r\n执行SQL:%@ 参数:%@ 报错信息:%@\r\n",sql,args,[db lastError]);
#endif

                    }
                }
                @catch (NSException *exception) {
#ifdef DEBUG
                    NSLog(@"%@",[exception description]);
#endif
                }
                @finally {
                    if (resultSet) {
                        [resultSet close];
                        resultSet = nil;
                    }
                }
                
            }];
        }
        @catch (NSException *exception) {
#ifdef DEBUG
            NSLog(@"查询失败:%@", [exception description]);
#endif
        }
        @finally {
            if (tryLock) {
                [_dn_db_manager_writeQueueLock unlock];
            }
        }
    return resultArray;
}

/**
 *  查询数量
 *
 *  @param sql  sql语句
 *  @param args 参数
 *
 *  @return 数量
 */
-(NSInteger)count:(NSString*)sql withArgumentsInArray:(NSArray*)args
{
    __block int count = 0;
    
        BOOL tryLock = NO;
        @try {
            [_dn_db_manager_writeQueueLock lock];
            tryLock = YES;
            [_dn_db_manager_queue inDatabase:^(FMDatabase *db) {
                
                FMResultSet *resultSet = nil;
                @try {
                    db.logsErrors = YES;
                    resultSet = [db executeQuery:sql withArgumentsInArray:args];
                    
                    if (resultSet && [resultSet next]) {
                        count = [resultSet intForColumnIndex:0];
                    }else{
#ifdef DEBUG
                        NSLog(@"\r\n执行SQL:%@ 参数:%@ 报错信息:%@\r\n",sql,args,[db lastError]);
#endif
                    }
                }
                @catch (NSException *exception) {
#ifdef DEBUG
                    NSLog(@"%@",[exception description]);
#endif
                }
                @finally {
                    if (resultSet) {
                        [resultSet close];
                        resultSet = nil;
                    }
                }
                
            }];
        }
        @catch (NSException *exception) {
#ifdef DEBUG
            NSLog(@"\r\n执行SQL:%@ 参数:%@ 报错信息:%@\r\n",sql,args,[exception description]);
#endif
        }
        @finally {
            if (tryLock) {
                [_dn_db_manager_writeQueueLock unlock];
            }
        }
    
    return count;
}

@end
