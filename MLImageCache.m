//
//  MLImageCache.m
//

/*  Copyright (c) 2014 Marek Lipert <marek.lipert@gmail.com>
 
Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is furnished
to do so, subject to the following conditions:
 
The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.
 
THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
THE SOFTWARE. */


#import "MLImageCache.h"
#import <ASIHttpRequest.h>
#import <CommonCrypto/CommonDigest.h>
#import <objc/runtime.h>

@interface MLImageCache()

@property(nonatomic,strong) NSOperationQueue *downloadQueue;
@property(nonatomic,strong) NSMutableDictionary *cache;
@property(nonatomic,strong) NSString *cacheDir;
@property(nonatomic,strong) NSMutableDictionary *downloadReferences;


- (NSString *)MD5FromData:(NSData *)data;
- (NSString *)MD5FromString:(NSString *)string;

@end

static char associationKey;


@implementation MLImageCache


+ (MLImageCache *)sharedInstance {
    static dispatch_once_t onceToken;
    static MLImageCache *cache;
    dispatch_once(&onceToken, ^{
        cache = [[MLImageCache alloc] init];
    });
    return cache;
}

- (id)init {
    self = [super init];
    if(self) {
        NSAssert([NSThread isMainThread],@"Not on main thread");
        self.downloadQueue = [NSOperationQueue new];
        self.downloadQueue.maxConcurrentOperationCount = kNumberOfSimultaneousDownloads;
        self.cache = [NSMutableDictionary new];
        self.cacheDir = [NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) objectAtIndex:0];
        NSAssert(self.cacheDir,@"No caches directory");
        self.downloadReferences = [NSMutableDictionary dictionary];
        [[NSNotificationCenter defaultCenter] addObserverForName:UIApplicationDidReceiveMemoryWarningNotification object:nil queue:nil usingBlock:^(NSNotification *note) {
           dispatch_async(dispatch_get_main_queue(), ^{
               NSLog(@"Image cache cleared itself after memory warning");
               [self.cache removeAllObjects];
           });
        }];
    }
    return self;
}

- (BOOL) cacheImage:(UIImage *)image withUrl:(NSURL *)url
{
    return [self cacheData:UIImagePNGRepresentation(image) withUrl:url];
}


- (BOOL) cacheData:(NSData *)data withUrl:(NSURL *)url
{
    NSAssert([NSThread isMainThread],@"Not on main thread");
    NSString *md5 = [self MD5FromString:url.absoluteString];
    NSString *path = [self.cacheDir stringByAppendingPathComponent:[NSString stringWithFormat:@"%@.dat",md5]];
    [self.cache setObject:data forKey:md5];
    return [data writeToFile:path atomically:YES];
}



- (BOOL) prefetchFromURL: (NSURL *)url
{
    NSAssert([NSThread isMainThread],@"Not on main thread");
    NSParameterAssert(url.absoluteString.length);
    NSString *md5 = [self MD5FromString:url.absoluteString];
    NSData *retVal = [self.cache objectForKey:md5];
    NSString *path = [self.cacheDir stringByAppendingPathComponent:[NSString stringWithFormat:@"%@.dat",md5]];
    if(!retVal) {
        retVal = [NSData dataWithContentsOfFile:path];
        if(retVal) {
            [self.cache setObject:retVal forKey:md5];
        }
    }
    return nil != retVal;
}


- (void) getImageAtURL: (NSURL *)url withPriority:(NSOperationQueuePriority) priority completion:(void(^)(UIImage *image, id referenceObject,BOOL loadedFromCache)) completion referenceObject: (id) reference {
    [self getDataAtURL:url withPriority:priority completion:^(NSData *data, id referenceObject,BOOL loadedFromCache) {
        if(data) {
            UIImage *image = [UIImage imageWithData:data];
            if(completion) completion(image,reference,loadedFromCache);
        }
        
    } referenceObject:reference];
    
}




- (void) getDataAtURL: (NSURL *)url withPriority:(NSOperationQueuePriority) priority completion:(void(^)(NSData *data, id referenceObject,BOOL loadedFromCache)) completion referenceObject: (id) reference
{
    NSAssert([NSThread isMainThread],@"Not on main thread");
    NSParameterAssert(url.absoluteString.length);
    NSParameterAssert(completion);
    NSString *md5 = [self MD5FromString:url.absoluteString];
    NSAssert(md5.length,@"No md5");
    
    if(!reference) reference = @"dummy reference";

    NSNumber *revision = objc_getAssociatedObject(reference, &associationKey);
    if(revision) {
        revision = @(revision.integerValue+1);
    } else {
        revision = @0;
    }
    objc_setAssociatedObject(reference, &associationKey, revision, OBJC_ASSOCIATION_RETAIN);

    __block NSData *retVal = [self.cache objectForKey:md5];
    NSString *path = [self.cacheDir stringByAppendingPathComponent:[NSString stringWithFormat:@"%@.dat",md5]];
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
        BOOL readFromFile = NO;
        if(!retVal) {
            //NSLog(@"L1 Cache miss, trying L2");
            retVal = [NSData dataWithContentsOfFile:path];
            if(retVal) {
              readFromFile = YES;
            }
        }
        __weak id weakReference = reference;
        dispatch_async(dispatch_get_main_queue(), ^{
            if(retVal) {
                if(readFromFile) [self.cache setObject:retVal forKey:md5];
                completion(retVal,weakReference,YES);
                return; /* we assume that image at url never changes */
            }
           // NSLog(@"L2 Cache miss, trying download");
            
            NSMutableArray *referenceArray = self.downloadReferences[url];
            
            if(referenceArray.count) {
                //NSLog(@"---> Adding additional reference");
                [referenceArray addObject:@{@"reference" : reference, @"revision" : [revision copy],@"completion":[completion copy]}];
                return;
            }
            
            referenceArray = [NSMutableArray array];
            self.downloadReferences[url] = referenceArray;
            
            [referenceArray addObject:@{@"reference" : reference, @"revision" : [revision copy], @"completion":[completion copy]}];
            
            
            [self downloadDataAtUrl:url withPriority:priority completion:^(NSData *data, id referenceObject) {
                
                if(data) {
                    [self.cache setObject:data forKey:md5];
                    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
                        BOOL success = NO;
                        NSString *path = [self.cacheDir stringByAppendingPathComponent:[NSString stringWithFormat:@"%@.dat",md5]];
                        success = [data writeToFile:path atomically:YES];
                        NSAssert(success, @"An error occurred when writing the image into the file path");
                    });
                }
                
                NSMutableArray *internalReferences = self.downloadReferences[url];
                NSParameterAssert(internalReferences);
                for(NSDictionary *d in internalReferences) {
                    id object = d[@"reference"];
                    NSNumber *internal = objc_getAssociatedObject(object, &associationKey);
                    NSNumber *rev = d[@"revision"];
                    void(^internalCompletion)(NSData *data, id referenceObject,BOOL loadedFromCache) = d[@"completion"];
                    
                    if([internal isEqual:rev]) {
                        objc_setAssociatedObject(object, &associationKey, nil, OBJC_ASSOCIATION_RETAIN);
                        internalCompletion(data,object,NO);
                    }
                }
                [self.downloadReferences removeObjectForKey:url];
            } referenceObject:weakReference];
        });
       
    });
}


#pragma mark - Utilities

- (void) downloadDataAtUrl: (NSURL *)url withPriority: (NSOperationQueuePriority) priority completion: (void(^)(NSData *data, id referenceObject)) completion referenceObject: (id) reference {
    NSParameterAssert(url);
    NSParameterAssert(completion);
    __weak id weakReference = reference;
    NSOperation *op = [NSBlockOperation blockOperationWithBlock:^{
        ASIHTTPRequest *request = [ASIHTTPRequest requestWithURL:url];
        [request startSynchronous];
        NSError *error = [request error];
        NSData *data = error?nil:request.responseData;
        dispatch_sync(dispatch_get_main_queue(), ^{
            id strongReference = weakReference;
            completion(data,strongReference);
        });
    }];
    op.queuePriority = priority;
    [self.downloadQueue addOperation:op];
}


- (NSString*)MD5FromData:(NSData *)data
{
    // Create byte array of unsigned chars
    unsigned char md5Buffer[CC_MD5_DIGEST_LENGTH];
    
    // Create 16 byte MD5 hash value, store in buffer
    CC_MD5(data.bytes, data.length, md5Buffer);
    
    // Convert unsigned char buffer to NSString of hex values
    NSMutableString *output = [NSMutableString stringWithCapacity:CC_MD5_DIGEST_LENGTH * 2];
    for(int i = 0; i < CC_MD5_DIGEST_LENGTH; i++)
        [output appendFormat:@"%02x",md5Buffer[i]];
    
    return output;
}

- (NSString*)MD5FromString:(NSString *)string
{
    // Create pointer to the string as UTF8
    const char *ptr = [string UTF8String];
    
    // Create byte array of unsigned chars
    unsigned char md5Buffer[CC_MD5_DIGEST_LENGTH];
    
    // Create 16 byte MD5 hash value, store in buffer
    CC_MD5(ptr, strlen(ptr), md5Buffer);
    
    // Convert MD5 value in the buffer to NSString of hex values
    NSMutableString *output = [NSMutableString stringWithCapacity:CC_MD5_DIGEST_LENGTH * 2];
    for(int i = 0; i < CC_MD5_DIGEST_LENGTH; i++)
        [output appendFormat:@"%02x",md5Buffer[i]];
    
    return output;
}


@end
