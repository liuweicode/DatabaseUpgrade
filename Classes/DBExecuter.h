//
//  DBExecuter.h
//  DatabaseUpgrade
//
//  Created by 刘伟 on 16/5/19.
//  Copyright © 2016年 上海凌晋信息技术有限公司. All rights reserved.
//

#import <Foundation/Foundation.h>

@class FMDatabase;

typedef BOOL(^DNDBInTransaction)(FMDatabase* db);

@interface DBExecuter : NSObject

/**
 *  初始化数据库操作对象
 *
 *  @param databaseName 数据库路径
 *
 *  @return DBExecuter
 */
-(id)initWith:(NSString*)dbPath;

/**
 *  数据库是否存在表
 *
 *  @param tableName 表名称
 *
 *  @return YES / NO
 */
- (BOOL)tableExistsWithName:(NSString *)tableName;

/**
 *  数据库表是否存在某字段
 *
 *  @param tableName  表明
 *  @param columnName 字段名
 *
 *  @return YES / NO
 */
- (BOOL)columnExistsWithTableName:(NSString *)tableName columnName:(NSString *)columnName;

/**
 *  执行SQL语句
 *
 *  @param sql  sql语句
 *  @param args 参数
 *
 *  @return 执行成功与否
 */
-(void)executeUpdate:(NSString*)sql withArgumentsInArray:(NSArray*)args;

/**
 *  在事务中之行SQL语句
 *
 *  @param transactionBlock 回调
 *
 *  @return 执行成功与否
 */
-(void)executeUpdate:(DNDBInTransaction)transactionBlock;

/**
 *  查询数据库
 *
 *  @param sql  sql语句
 *  @param args 参数
 *  @param cls  映射的类
 *
 *  @return 查后后的数组
 */
-(NSMutableArray*)executeQuery:(NSString*)sql withArgumentsInArray:(NSArray*)args withClass:(Class)cls;

/**
 *  查询数量
 *
 *  @param sql  sql语句
 *  @param args 参数
 *
 *  @return 数量
 */
-(NSInteger)count:(NSString*)sql withArgumentsInArray:(NSArray*)args;

@end
