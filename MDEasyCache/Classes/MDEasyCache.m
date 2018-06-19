//
//  MDEasyCache.m
//  Pods-MDProject
//
//  Created by lizitao on 2018/6/18.
//

#import "MDEasyCache.h"
#import "MDEasyCacheConfig.h"

#define MDDefaultCachePath      [((NSString *)NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES)[0]) stringByAppendingPathComponent:[NSString stringWithFormat:@"%@",MDEasyDefaultCachePrefix]]
//#define MDOnlyDiskCachePath     [((NSString *)NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES)[0]) stringByAppendingPathComponent:[NSString stringWithFormat:@"%@",MDEasyOnlyDiskCachePrefix]]
#define MDDefaultCacheKeyPath(key)   [MDDefaultCachePath stringByAppendingPathComponent:key]
//#define MDOnlyDiskCacheKeyPath(key)  [MDOnlyDiskCachePath stringByAppendingPathComponent:key]

NSString * const MDEasyDefaultCachePrefix = @"com.leon.mdeasycache.default";
NSString * const MDEasyOnlyDiskCachePrefix = @"com.leon.mdeasycache.onlydisk";

@interface MDAutoReleaseCache : NSMutableDictionary
@end

@implementation MDAutoReleaseCache

- (nonnull instancetype)init
{
    self = [super init];
    if (self) {
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(removeAllObjects) name:UIApplicationDidReceiveMemoryWarningNotification object:nil];
    }
    return self;
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIApplicationDidReceiveMemoryWarningNotification object:nil];
}
@end

@interface MDEasyCache ()
@property (strong, nonatomic, nonnull) NSMutableDictionary *cacheConfig;
@property (strong, nonatomic, nonnull) NSMutableDictionary *autoCache;
@property (strong, nonatomic, nonnull) NSMutableDictionary *memoryCache;
@property (strong, nonatomic, nonnull) MDEasyCacheConfig *config;
@property (strong, nonatomic, nonnull) NSFileManager *fm;
@end

@implementation MDEasyCache
static MDEasyCache *easyCache;
static dispatch_once_t onceToken;

+ (instancetype)easyCache
{
    return [[self alloc] init];
}

+ (instancetype)allocWithZone:(struct _NSZone *)zone
{
    dispatch_once(&onceToken, ^{
        easyCache = [super allocWithZone:zone];
    });
    return easyCache;
}

- (instancetype)copyWithZone:(NSZone *)zone
{
    return easyCache;
}

- (instancetype)mutableCopyWithZone:(NSZone *)zone
{
    return easyCache;
}

- (id)init
{
    if (self = [super init]) {
        _config = [[MDEasyCacheConfig alloc] init];
    }
    return self;
}

- (void)setObject:(id<NSCoding>)object forKey:(NSString *)key
{
    NSObject *obj = (NSObject *)object;
    if (!obj) return;
    MDEasyCacheConfig *config = self.config;
    config.key = key;
    config.object = object;
    config.pathURL = [NSURL fileURLWithPath:MDDefaultCacheKeyPath(key)];
    [self.cacheConfig setObject:config forKey:key];
    if (config.cacheType == MDEasyCacheTypeDefault) {
        [self.memoryCache setObject:object forKey:key];
        if (![self setObjectToDisk:object forKey:key]) {
            NSLog(@"!!!Warning: Disk cache fail!!!");
        }
    }
}

- (void)setObject:(id<NSCoding>)object forKey:(NSString *)key completion:(void (^)(MDEasyCacheConfig *config))completion
{
    NSObject *obj = (NSObject *)object;
    if (!obj) return;
    MDEasyCacheConfig *config = self.config;
    config.key = key;
    config.object = object;
    config.pathURL = [NSURL fileURLWithPath:MDDefaultCacheKeyPath(key)];
    if (completion) {
        completion(config);
    }
    [self.cacheConfig setObject:config forKey:key];
    if (config.cacheType == MDEasyCacheTypeDefault) {
        [self.memoryCache setObject:object forKey:key];
        if (![self setObjectToDisk:object forKey:key]) {
            NSLog(@"!!!Warning: Disk cache fail!!!");
        }
    }
}

- (BOOL)setObjectToDisk:(id<NSCoding>)object forKey:(NSString *)key
{
    NSObject *obj = (NSObject *)object;
    if (!obj) return NO;
    //UIImage or subClass of UIImage
    BOOL written = NO;
    if ([obj isKindOfClass:[UIImage class]] || [obj isMemberOfClass:[UIImage class]]) {
        if (![self.fm fileExistsAtPath:MDDefaultCachePath]) {
         written = [self.fm createDirectoryAtPath:MDDefaultCachePath withIntermediateDirectories:YES attributes:nil error:NULL];
        }
        NSData *imageData = [self md_imageData:(UIImage *)object];
        written = [self.fm createFileAtPath:MDDefaultCacheKeyPath(key) contents:imageData attributes:nil];
        
    } else {
        written = [NSKeyedArchiver archiveRootObject:object toFile:MDDefaultCacheKeyPath(key)];
    }
    return written;
}

- (id)objectForKey:(NSString *)key
{
    if (key.length < 1) return nil;
    id object = nil;
    object = [self.memoryCache objectForKey:key];
    if (!object) {
        object = [self objectFromDiskForKey:key];
        if (object) {
            [self.memoryCache setObject:object forKey:key];
        }
    }
    return object;
}

- (id)objectForKey:(NSString *)key completion:(void (^)(MDEasyCacheConfig *config))completion
{
    id object = [self objectForKey:key];
    MDEasyCacheConfig *config = [self.cacheConfig objectForKey:key];
    if (object) {
        if (config) {
            if (completion) {
                completion(config);
            }
        } else {
            MDEasyCacheConfig *config = [MDEasyCacheConfig new];
            config.cacheType = MDEasyCacheTypeDefault;
            config.key = key;
            config.object = [self objectFromDiskForKey:key];
            config.pathURL = [NSURL fileURLWithPath:MDDefaultCacheKeyPath(key)];
            if (config.object) {
                if (completion) {
                    completion(config);
                }
            }
        }
    }
    return object;
}

- (id)objectFromDiskForKey:(NSString *)key
{
    if (key.length < 1) return nil;
    id object = nil;
    if ([[NSFileManager defaultManager] fileExistsAtPath:MDDefaultCachePath]) {
        @try {
            object = [NSKeyedUnarchiver unarchiveObjectWithFile:MDDefaultCacheKeyPath(key)];
        }
        @catch (NSException *exception) {
            NSError *error = nil;
            [[NSFileManager defaultManager] removeItemAtPath:MDDefaultCacheKeyPath(key) error:&error];
            NSLog(@"%@",error);
        }
    }
    return object;
}

- (void)removeObjectForKey:(nonnull NSString *)key
{
    if (key.length < 1) return;
    [self.memoryCache removeObjectForKey:key];
    [self removeObjectFromDiskForKey:key];
    [self.cacheConfig removeObjectForKey:key];
}

- (void)removeObjectFromDiskForKey:(NSString *)key
{
    if (key.length < 1) return;
    NSError *error = nil;
    [[NSFileManager defaultManager] removeItemAtPath:MDDefaultCacheKeyPath(key) error:&error];
    NSLog(@"%@",error);
}

- (nullable NSData *)md_imageData:(UIImage *)image
{
    NSData *imageData = nil;
    int alphaInfo = CGImageGetAlphaInfo(image.CGImage);
    BOOL hasAlpha = !(alphaInfo == kCGImageAlphaNone ||
                      alphaInfo == kCGImageAlphaNoneSkipFirst ||
                      alphaInfo == kCGImageAlphaNoneSkipLast);
    if (hasAlpha) {
        imageData = UIImagePNGRepresentation(image);
    } else {
        imageData = UIImageJPEGRepresentation(image, (CGFloat)1.0);
    }
    return imageData;
}

- (NSMutableDictionary *)cacheConfig
{
    if (!_cacheConfig) {
        _cacheConfig = [[NSMutableDictionary alloc]init];
    }
    return _cacheConfig;
}

- (NSMutableDictionary *)memoryCache
{
    if (!_memoryCache) {
        _memoryCache = [[NSMutableDictionary alloc]init];
    }
    return _memoryCache;
}

- (NSFileManager *)fm
{
    if (!_fm) {
        _fm = [NSFileManager defaultManager];
    }
    return _fm;
}

@end
