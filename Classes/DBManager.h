//
//  DBManager.h
//  DatabaseUpgrade
//
//  Created by 刘伟 on 8/19/16.
//  Copyright © 2016 Linkim. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "DBExecuter.h"

@interface DBManager : NSObject

@property(nonatomic,strong)NSString* databaseName;

@property(nonatomic,strong,readonly)DBExecuter* executer;

/**
 *  单例类
 *
 *  @return DBManager
 */
+(DBManager *)sharedInstance;

/**
 *  删除数据库
 *
 *  @param databaseName 数据库名称
 *
 *  @return 是否删除成功
 */
-(BOOL)deleteDatabaseWithPath:(NSString*)databaseName;

@end
