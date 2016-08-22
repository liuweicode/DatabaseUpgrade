//
//  DBManger.m
//  DatabaseUpgrade
//
//  Created by 刘伟 on 8/19/16.
//  Copyright © 2016 Linkim. All rights reserved.
//

#import "DBManager.h"

@interface DBManager()
@property (nonatomic,strong,readonly)NSString *libraryCachesPath;
@end

@implementation DBManager
@synthesize databaseName = _databaseName;
@synthesize executer = _executer;
@synthesize libraryCachesPath = _libraryCachesPath;

+(DBManager *)sharedInstance
{
    static DBManager *sharedSingleton = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken,^(void) {
        sharedSingleton = [[self alloc] init];
    });
    return sharedSingleton;
}

- (NSString *)libraryCachesPath
{
    if(_libraryCachesPath == nil)
    {
        NSArray * paths = NSSearchPathForDirectoriesInDomains(NSLibraryDirectory, NSUserDomainMask, YES);
        NSString * path = [[paths objectAtIndex:0] stringByAppendingFormat:@"/Caches"];
        
        if ( NO == [[NSFileManager defaultManager] fileExistsAtPath:path] )
        {
            [[NSFileManager defaultManager] createDirectoryAtPath:path
                                             withIntermediateDirectories:YES
                                                              attributes:nil
                                                                   error:NULL];
        }
        _libraryCachesPath = path;
    }
    return _libraryCachesPath;
}

/**
 *  数据库路径
 *
 *  @return
 */
- (NSString *)databasePath:(NSString*)databseName
{
    NSString *cachePath = self.libraryCachesPath;
    return [cachePath stringByAppendingPathComponent:databseName];
}

/**
 *  删除数据库
 *
 *  @param databaseName 数据库名称
 *
 *  @return 是否删除成功
 */
-(BOOL)deleteDatabaseWithPath:(NSString*)databaseName
{
    NSString* filePath = [self databasePath:databaseName];
    NSFileManager *fileManager = [NSFileManager defaultManager];
    // 如果文件存在, 则删除文件
    if([fileManager fileExistsAtPath:filePath])
    {
        return [fileManager removeItemAtPath:filePath error:nil];
    }
    return false;
}

-(DBExecuter*)executer
{
    if (!_executer) {
        _executer = [[DBExecuter alloc] initWith:_databaseName];
    }
    return _executer;
}

-(void)setDatabaseName:(NSString *)databaseName
{
    if ([databaseName isEqualToString:_databaseName])return;
    
    _databaseName = databaseName;
    
    if (_executer) {
        _executer = nil;
    }
}

-(NSString*)databaseName
{
    return _databaseName;
}

@end
