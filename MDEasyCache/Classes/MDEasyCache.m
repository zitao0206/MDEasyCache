//
//  MDEasyCache.m
//  Pods-MDProject
//
//  Created by lizitao on 2018/6/18.
//

#import "MDEasyCache.h"
#import "MDEasyCacheConfig.h"

//普通数据缓存路径
#define MDDefaultCachePath      [((NSString *)NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES)[0]) stringByAppendingPathComponent:[NSString stringWithFormat:@"%@",MDEasyDefaultCachePrefix]]
//图片缓存路径
#define MDImageDiskCachePath     [((NSString *)NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES)[0]) stringByAppendingPathComponent:[NSString stringWithFormat:@"%@",MDEasyImageDiskCachePrefix]]
//普通缓存文件路径
#define MDDefaultCacheKeyPath(key)   [MDDefaultCachePath stringByAppendingPathComponent:key]
//图片缓存文件路径
#define MDImageDiskCacheKeyPath(key)  [MDImageDiskCachePath stringByAppendingPathComponent:key]

NSString * const MDEasyDefaultCachePrefix = @"com.leon.mdeasycache.default";
NSString * const MDEasyImageDiskCachePrefix = @"com.leon.mdeasycache.imagedisk";

@interface MDEasyCache ()
@property (strong, nonatomic, nonnull) NSMutableDictionary *cacheConfig;
@property (strong, nonatomic, nonnull) NSMutableDictionary *memoryCache;
@property (strong, nonatomic, nonnull) MDEasyCacheConfig *config;
@property (strong, nonatomic, nonnull) NSFileManager *fm;
@property (strong, nonatomic, nonnull) dispatch_queue_t cacheQueue;
@end

@implementation MDEasyCache

static MDEasyCache *easyCache;

+ (instancetype)easyCache
{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        easyCache = [[self alloc] init];
    });
    return easyCache;
}

- (id)init
{
    if (self = [super init]) {
        _config = [[MDEasyCacheConfig alloc] init];
        _cacheQueue = dispatch_queue_create("com.leon.mdeasycache", DISPATCH_QUEUE_SERIAL);
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(clearMemory) name:UIApplicationDidReceiveMemoryWarningNotification object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(clearMemory) name:UIApplicationDidEnterBackgroundNotification object:nil];
    }
    return self;
}

- (void)setObject:(id<NSCoding>)object forKey:(NSString *)key
{
    @synchronized(self) {
        NSObject *obj = (NSObject *)object;
        if (!obj) return;
        if (![self isConformToCodingProtocol:obj]) return;
        MDEasyCacheConfig *config = self.config;
        config.key = key;
        config.object = object;
        if ([obj isKindOfClass:[UIImage class]] || [obj isMemberOfClass:[UIImage class]]) {
            config.isImage = YES;
            config.pathURL = [NSURL fileURLWithPath:MDImageDiskCacheKeyPath(key)];
        } else {
            config.pathURL = [NSURL fileURLWithPath:MDDefaultCacheKeyPath(key)];
        }
        [self.cacheConfig setObject:config forKey:key];
        [self.memoryCache setObject:object forKey:key];
        dispatch_async(self.cacheQueue, ^{
            @synchronized(self) {
                if (![self setObjectToDisk:object forKey:key]) {
                    config.pathURL = nil;
                    NSLog(@"!!!Warning: Disk cache fail!!!");
                } else {
                    NSLog(@"Disk cache success: %@",config.pathURL);
                }
            }
        });
    }
}

- (void)setObject:(id<NSCoding>)object forKey:(NSString *)key completion:(void (^)(MDEasyCacheConfig *config))completion
{
    @synchronized(self) {
        NSObject *obj = (NSObject *)object;
        if (!obj) return;
        if (![self isConformToCodingProtocol:obj]) return;
        __block MDEasyCacheConfig *config = self.config;
        config.key = key;
        config.object = object;
        if ([obj isKindOfClass:[UIImage class]] || [obj isMemberOfClass:[UIImage class]]) {
            config.isImage = YES;
            config.pathURL = [NSURL fileURLWithPath:MDImageDiskCacheKeyPath(key)];
        } else {
            config.pathURL = [NSURL fileURLWithPath:MDDefaultCacheKeyPath(key)];
        }
        [self.cacheConfig setObject:config forKey:key];
        [self.memoryCache setObject:object forKey:key];
    
        dispatch_async(self.cacheQueue, ^{
            @synchronized(self) {
                if (![self setObjectToDisk:object forKey:key]) {
                    config.pathURL = nil;
                    NSLog(@"!!!Warning: Disk cache fail!!!");
                    dispatch_async(dispatch_get_main_queue(), ^{
                        if (completion) {
                            completion(config);
                        }
                    });
                } else {
                    NSLog(@"Disk cache success: %@",config.pathURL);
                }
            }
        });
    }
}

- (BOOL)setObjectToDisk:(id<NSCoding>)object forKey:(NSString *)key
{
    NSObject *obj = (NSObject *)object;
    if (!obj) return NO;
    //UIImage or subClass of UIImage
    BOOL written = NO;
    if ([obj isKindOfClass:[UIImage class]] || [obj isMemberOfClass:[UIImage class]]) {
        if (![self.fm fileExistsAtPath:MDImageDiskCachePath]) {
            written = [self.fm createDirectoryAtPath:MDImageDiskCachePath withIntermediateDirectories:YES attributes:nil error:NULL];
        }
        NSData *imageData = [self md_imageData:(UIImage *)object];
        written = [self.fm createFileAtPath:MDImageDiskCacheKeyPath(key) contents:imageData attributes:nil];
        //由于图片和文件存储在不同的目录，需要保持key值的互斥
        if ([[NSFileManager defaultManager] fileExistsAtPath:MDDefaultCacheKeyPath(key)]) {
            NSError *error = nil;
            [[NSFileManager defaultManager] removeItemAtPath:MDDefaultCacheKeyPath(key) error:&error];
            NSLog(@"%@",error);
        }
        
    } else {
        if (![self.fm fileExistsAtPath:MDDefaultCachePath]) {
            written = [self.fm createDirectoryAtPath:MDDefaultCachePath withIntermediateDirectories:YES attributes:nil error:NULL];
        }
        written = [NSKeyedArchiver archiveRootObject:object toFile:MDDefaultCacheKeyPath(key)];
        //由于图片和文件存储在不同的目录，需要保持key值的互斥
        if ([[NSFileManager defaultManager] fileExistsAtPath:MDImageDiskCacheKeyPath(key)]) {
            NSError *error = nil;
            [[NSFileManager defaultManager] removeItemAtPath:MDImageDiskCacheKeyPath(key) error:&error];
            NSLog(@"%@",error);
        }
    }
    return written;
}

- (BOOL)isConformToCodingProtocol:(NSObject *)obj
{
    if ([obj conformsToProtocol:@protocol(NSCoding)] && [obj respondsToSelector:@selector(encodeWithCoder:)] && [obj respondsToSelector:@selector(initWithCoder:)]) {
        return YES;
    }
    NSLog(@"！！！Warning: not conform NSCoding！！！");
    return NO;
}

- (id)objectForKey:(NSString *)key
{
    if (key.length < 1) return nil;
    id object = nil;
    @synchronized(self) {
        object = [self.memoryCache objectForKey:key];
        if (!object) {
            object = [self objectFromDiskForKey:key];
            if (object) {
                [self.memoryCache setObject:object forKey:key];
            }
        }
    }
    return object;
}

- (id)objectForKey:(NSString *)key completion:(void (^)(MDEasyCacheConfig *config))completion
{
    id object = [self objectForKey:key];
    @synchronized(self) {
        if (object) {
            MDEasyCacheConfig *config = [self.cacheConfig objectForKey:key];
            if (config) {
                if (completion) {
                    completion(config);
                }
            } else {
                MDEasyCacheConfig *config = [MDEasyCacheConfig new];
                config.key = key;
                config.object = object;
                config.pathURL = [NSURL fileURLWithPath:MDDefaultCacheKeyPath(key)];
                if (config.object) {
                    if (completion) {
                        completion(config);
                    }
                }
            }
        } else {
            if (completion) {
                completion(nil);
            }
        }
    }
    return object;
}

- (id)objectFromDiskForKey:(NSString *)key
{
    if (key.length < 1) return nil;
    id object = nil;
    if ([[NSFileManager defaultManager] fileExistsAtPath:MDDefaultCacheKeyPath(key)]) {
        @try {
            object = [NSKeyedUnarchiver unarchiveObjectWithFile:MDDefaultCacheKeyPath(key)];
        }
        @catch (NSException *exception) {
            NSError *error = nil;
            [[NSFileManager defaultManager] removeItemAtPath:MDDefaultCacheKeyPath(key) error:&error];
            NSLog(@"%@",error);
        }
    } else if ([[NSFileManager defaultManager] fileExistsAtPath:MDImageDiskCacheKeyPath(key)]) {
        @try {
            NSData *data = [NSData dataWithContentsOfFile:MDImageDiskCacheKeyPath(key)];
            if (data) {
               object = [UIImage imageWithData:data];
            }
        }
        @catch (NSException *exception) {
            NSError *error = nil;
            [[NSFileManager defaultManager] removeItemAtPath:MDImageDiskCacheKeyPath(key) error:&error];
            NSLog(@"%@",error);
        }
    }
    return object;
}

- (void)removeObjectForKey:(nonnull NSString *)key
{
    if (key.length < 1) return;
    @synchronized(self) {
        [self.memoryCache removeObjectForKey:key];
        [self removeObjectFromDiskForKey:key];
        [self.cacheConfig removeObjectForKey:key];
    }
}

- (void)removeObjectFromDiskForKey:(NSString *)key
{
    if (key.length < 1) return;
    NSError *error = nil;
    [[NSFileManager defaultManager] removeItemAtPath:MDDefaultCacheKeyPath(key) error:&error];
    NSLog(@"%@",error);
}

- (void)clearMemory
{
    @synchronized(self) {
        [self.memoryCache removeAllObjects];
        [self.cacheConfig removeAllObjects];
    }
}

- (void)clearDisk
{
    @synchronized(self) {
        NSError *error1 = nil;
        if ([self.fm fileExistsAtPath:MDDefaultCachePath]) {
            [[NSFileManager defaultManager] removeItemAtPath:MDDefaultCachePath error:&error1];
        }
        NSError *error2 = nil;
        if ([self.fm fileExistsAtPath:MDImageDiskCachePath]) {
            [[NSFileManager defaultManager] removeItemAtPath:MDImageDiskCachePath error:&error2];
        }
        if (error1 || error2 ) {
            NSLog(@"%@",error1);
            NSLog(@"%@",error2);
        }
    }
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
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
