//
//  MDEasyCacheConfig.h
//  MDEasyCache
//
//  Created by lizitao on 2018/6/18.
//

#import <Foundation/Foundation.h>
typedef NS_ENUM(NSInteger, MDEasyCacheType) {
    /**
     * The data will store in the memory and Disk, meanwhile the memory can be auto release
     */
    MDEasyCacheTypeDefault,
    /**
     * The data will store in the memory only and will not be auto release.
     */
    MDEasyCacheTypeOnlyMemory,
    /**
     * The data will store in the Disk only.
     */
    MDEasyCacheTypeOnlyDisk
};
@interface MDEasyCacheConfig : NSObject
@property (nonatomic, assign) MDEasyCacheType cacheType;
@property (nonatomic, strong) NSURL *pathURL;
@property (nonatomic, copy) NSString *key;
@property (nonatomic, assign) id object;
@property (nonatomic, assign) BOOL isImage;
@end
