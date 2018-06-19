//
//  MDEasyCacheConfig.m
//  MDEasyCache
//
//  Created by lizitao on 2018/6/18.
//

#import "MDEasyCacheConfig.h"

@implementation MDEasyCacheConfig

- (instancetype)init
{
    if (self = [super init]) {
        _cacheType = MDEasyCacheTypeDefault;
        _pathURL = nil;
        _key = nil;
        _object = nil;
        _isImage = NO;
    }
    return self;
}

@end
