//
//  MDEasyCache.h
//  Pods-MDProject
//
//  Created by lizitao on 2018/6/18.
//

#import <Foundation/Foundation.h>
#import "MDEasyCacheConfig.h"

@interface MDEasyCache : NSObject

+ (nonnull instancetype)easyCache;

- (void)setObject:(id<NSCoding>)object forKey:(NSString *)key;

- (void)setObject:(id<NSCoding>)object forKey:(NSString *)key completion:(void(^)(MDEasyCacheConfig *config))completion;

- (id)objectForKey:(NSString *)key;

- (id)objectForKey:(NSString *)key completion:(nonnull void (^)(MDEasyCacheConfig *config))completion;

- (void)removeObjectForKey:(NSString *)key;


@end
