//
//  MDEasyCacheConfig.h
//  MDEasyCache
//
//  Created by lizitao on 2018/6/18.
//

#import <Foundation/Foundation.h>
@interface MDEasyCacheConfig : NSObject
@property (nonatomic, strong) NSURL *pathURL;
@property (nonatomic, copy) NSString *key;
@property (nonatomic, weak) id object;
@property (nonatomic, assign) BOOL isImage;
@end
