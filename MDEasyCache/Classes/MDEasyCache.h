//
//  MDEasyCache.h
//  Pods-MDProject
//
//  Created by lizitao on 2018/6/18.
//

#import <Foundation/Foundation.h>
#import "MDEasyCacheConfig.h"

@interface MDEasyCache : NSObject
/**
 easyCache：单例
 */
+ (nonnull instancetype)easyCache;
/**
 数据object的存储
 object：须遵守NSCoding协议
 */
- (void)setObject:(id<NSCoding>)object forKey:(NSString *)key;
/**
 数据object的存储，带XYEasyCacheConfig返回
 object：须遵守NSCoding协议
 */
- (void)setObject:(id<NSCoding>)object forKey:(NSString *)key completion:(void(^)(MDEasyCacheConfig *config))completion;
/**
 数据object的读取
 */
- (id)objectForKey:(NSString *)key;
/**
 数据object的读取，待XYEasyCacheConfig返回
 */
- (id)objectForKey:(NSString *)key completion:(void (^)(MDEasyCacheConfig *config))completion;
/**
 删除指定key的value缓存
 */
- (void)removeObjectForKey:(NSString *)key;
/**
 清除内存缓存
 */
- (void)clearMemory;
/**
 清除磁盘缓存，业务慎用！！！
 */
- (void)clearDisk;

@end
