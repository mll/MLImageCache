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
#import <CommonCrypto/CommonDigest.h>
#import <objc/runtime.h>

@interface MLImageCache()

@property(nonatomic,strong) NSOperationQueue *downloadQueue;
@property(nonatomic,strong) NSMutableDictionary *cache;
@property(nonatomic,strong) NSString *cacheDir;
@property(nonatomic,strong) NSMutableDictionary *downloadReferences;
@property(nonatomic,strong) NSURLSession *downloadSession;

@property(nonatomic, strong) NSLock *mutabilityLock;


- (NSString *)MD5FromData:(NSData *)data;
- (NSString *)MD5FromString:(NSString *)string;

@end

static char revisionAssociationKey;

@implementation MLImageCache

+ (MLImageCache *)sharedInstance 
{
    static dispatch_once_t onceToken;
    static MLImageCache *cache;
    dispatch_once(&onceToken, ^
    {
        cache = [[MLImageCache alloc] init];
    });
    return cache;
}

- (id)init 
{
    self = [super init];
    if(self) 
    {
        __weak MLImageCache *weakSelf = self;
        NSAssert([NSThread isMainThread],@"Not on main thread");
        self.downloadQueue = [NSOperationQueue new];
        self.numberOfSimultaneousDownloads = kNumberOfSimultaneousDownloads;
        self.cache = [NSMutableDictionary new];
        self.mutabilityLock = [NSLock new];
        self.cacheDir = [[NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) objectAtIndex:0] stringByAppendingPathComponent:@"image-cache"];
        self.downloadSession = [NSURLSession sessionWithConfiguration:[NSURLSessionConfiguration ephemeralSessionConfiguration]];
        NSAssert(self.cacheDir,@"No caches directory");
        [[NSFileManager defaultManager] createDirectoryAtPath:self.cacheDir withIntermediateDirectories:YES attributes:nil error:NULL];

        self.downloadReferences = [NSMutableDictionary dictionary];
        [[NSNotificationCenter defaultCenter] addObserverForName:UIApplicationDidReceiveMemoryWarningNotification object:nil queue:nil usingBlock:^(NSNotification *note) 
        {
           dispatch_async(dispatch_get_main_queue(), ^
           {
               MLImageCache *strongSelf = weakSelf;
               NSLog(@"Image cache cleared itself after memory warning");
               [strongSelf.mutabilityLock lock];
               [strongSelf.cache removeAllObjects];
               [strongSelf.mutabilityLock unlock];
           });
        }];
    }
    return self;
}

- (void) setNumberOfSimultaneousDownloads: (NSInteger) downloads {
    self.downloadQueue.maxConcurrentOperationCount = downloads;
}

- (NSInteger) numberOfSimulatenousDownloads {
    return self.downloadQueue.maxConcurrentOperationCount;
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
    [self.mutabilityLock lock];
    [self.cache setObject:data forKey:md5];
    [self.mutabilityLock unlock];
    return [data writeToFile:path atomically:YES];
}

- (BOOL) prefetchFromURL: (NSURL *)url
{
    NSAssert([NSThread isMainThread],@"Not on main thread");
    NSParameterAssert(url.absoluteString.length);
    NSString *md5 = [self MD5FromString:url.absoluteString];
    [self.mutabilityLock lock];
    NSData *retVal = [self.cache objectForKey:md5];
    [self.mutabilityLock unlock];
    if(!retVal) 
    {
        NSString *path = [self.cacheDir stringByAppendingPathComponent:[NSString stringWithFormat:@"%@.dat",md5]];
        retVal = [NSData dataWithContentsOfFile:path];
        if(retVal) 
        {
            [self.mutabilityLock lock];
            [self.cache setObject:retVal forKey:md5];
            [self.mutabilityLock unlock];
        }
    }
    
    return nil != retVal;
}


- (void) getImageAtURL: (NSURL *)url withPriority:(NSOperationQueuePriority) priority completion:(void(^)(UIImage *image, id referenceObject,BOOL loadedFromCache)) completion referenceObject: (id) reference {
    [self getDataAtURL:url withPriority:priority postProcessingBlock:^NSData *(NSData *data, id referenceObject) {
        UIImage *image = [UIImage imageWithData:data];
        double ratio = kMaximumImageWidth / image.size.width;
        
        if (ratio < 1.0) {
            
            if (@available(iOS 10.0, *)) {
                CGSize newSize = CGSizeMake(image.size.width * ratio, image.size.height * ratio);
                UIGraphicsImageRenderer *renderer = [[UIGraphicsImageRenderer alloc] initWithSize:newSize];
                UIImage *newImage = [renderer imageWithActions: ^(UIGraphicsImageRendererContext*_Nonnull myContext) {
                        [image drawInRect:(CGRect) {.origin = CGPointZero, .size = newSize}];
                    }];
                return UIImagePNGRepresentation(newImage);
            }
        }
        return data;
    } completion:^(NSData *data, id referenceObject, BOOL loadedFromCache) {
        if(data && completion)
        {
            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^ {
                UIImage *image = [UIImage imageWithData:data];
                UIGraphicsBeginImageContext(CGSizeMake(1,1));
                CGContextRef context = UIGraphicsGetCurrentContext();
                CGContextDrawImage(context, CGRectMake(0, 0, 1, 1), [image CGImage]);
                UIGraphicsEndImageContext();
                
                dispatch_async(dispatch_get_main_queue(), ^{
                    completion(image, reference, loadedFromCache);
                });
            });
        }
    } referenceObject:reference];
}

- (void) getDataAtURL: (NSURL *)url withPriority:(NSOperationQueuePriority) priority postProcessingBlock: (NSData *(^)(NSData *data, id referenceObject)) postProcessingBlock completion:(void(^)(NSData *data, id referenceObject,BOOL loadedFromCache)) completion referenceObject: (id) reference
{
    NSAssert([NSThread isMainThread],@"Not on main thread");
    NSParameterAssert(url.absoluteString.length);
    NSParameterAssert(completion);
    NSParameterAssert(postProcessingBlock);
    NSString *md5 = [self MD5FromString:url.absoluteString];
    NSAssert(md5.length,@"No md5");
     
    if(!reference) reference = [NSNull null];
    
    NSNumber *revision = @(((NSNumber *)objc_getAssociatedObject(reference, &revisionAssociationKey)).integerValue + 1);

    objc_setAssociatedObject(reference, &revisionAssociationKey, revision, OBJC_ASSOCIATION_RETAIN);
    //NSLog(@"!!!! %p, %@, %@: Starting acquisition of data at URL: %@", reference, revision, [md5 substringToIndex:4], url.absoluteString);

    [self.mutabilityLock lock];
    NSData *retVal = [self.cache objectForKey:md5];
    [self.mutabilityLock unlock];
    
    if(retVal)
    {
        //NSLog(@"---> %p, %@, %@: Found in memory cache, completing.", reference, revision, [md5 substringToIndex:4]);
        completion(retVal, reference, YES);
        return;
    }
    
    __weak MLImageCache *weakSelf = self;
    NSString *cacheDir = self.cacheDir;
    __weak id weakReference = reference;
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^
    {
        MLImageCache *strongSelf = weakSelf;
        NSString *path = [cacheDir stringByAppendingPathComponent:[NSString stringWithFormat:@"%@.dat", md5]];
    
        NSData *retVal = [NSData dataWithContentsOfFile:path];
        
        if(retVal) {
            [strongSelf.mutabilityLock lock];
            [strongSelf.cache setObject:retVal forKey:md5];
            [strongSelf.mutabilityLock unlock];
        }
        
        dispatch_async(dispatch_get_main_queue(), ^
        {
            id strongReference = weakReference;
            if (!strongReference) {
                //NSLog(@"!!!! %p, %@, %@: Deallocated, ignoring.", strongReference, revision, [md5 substringToIndex:4]);
                return;
            }
            
            if(retVal) 
            {
                
                NSNumber *currentRevision = objc_getAssociatedObject(strongReference, &revisionAssociationKey);
                NSAssert(currentRevision, @"Current revision must be present.");
                if([currentRevision isEqualToNumber:revision] || [strongReference isKindOfClass:[NSNull class]])
                {
                    //NSLog(@"!!!! %p, %@, %@: Found in disk cache, completing.", weakReference, revision, [md5 substringToIndex:4]);
                    /* If current revision is higher than revision we have been called with, we do not call completion as only the newest file needs to be presented. */
                    completion(retVal, strongReference, YES);
                } else {
                    //NSLog(@"!!!! %p, %@, %@: Found in disk cache, but another download underway (%@).", strongReference, revision, [md5 substringToIndex:4], currentRevision);
                    
                }
                return;
            }
            
            [strongSelf.mutabilityLock lock];
            NSMutableArray *referenceArray = weakSelf.downloadReferences[md5];
            
            if(referenceArray.count) 
            {
                [referenceArray addObject:@{@"reference" : strongReference, @"revision" : [revision copy],@"completion":[completion copy]}];
                [strongSelf.mutabilityLock unlock];
                return;
            }
            
            referenceArray = [NSMutableArray array];
            weakSelf.downloadReferences[md5] = referenceArray;
            
            [referenceArray addObject:@{@"reference" : strongReference, @"revision" : [revision copy], @"completion":[completion copy]}];
            [strongSelf.mutabilityLock unlock];
            
            [weakSelf downloadDataAtUrl:url withPriority:priority queue: dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0) completion:^(NSData *data, id referenceObject) {
                //NSLog(@"---> %p, %@, %@: Download done, downloaded %lu bytes.", weakReference, revision, [md5 substringToIndex:4], (unsigned long)[data length]);
                NSData *processedData = postProcessingBlock(data, referenceObject);
                //NSLog(@"---> %p, %@, %@: Post-processing done, size %lu bytes.", weakReference, revision, [md5 substringToIndex:4], (unsigned long)[data length]);
                
                MLImageCache *strongSelf = weakSelf;
                if(processedData) 
                {
                    [strongSelf.mutabilityLock lock];
                    [strongSelf.cache setObject:processedData forKey:md5];
                    [strongSelf.mutabilityLock unlock];
                    BOOL success = NO;
                    NSString *path = [weakSelf.cacheDir stringByAppendingPathComponent:[NSString stringWithFormat:@"%@.dat",md5]];
                    success = [processedData writeToFile:path atomically:YES];
                    NSAssert(success, @"An error occurred when writing the image into the file path");
                }
                dispatch_async(dispatch_get_main_queue(), ^{
                    [strongSelf.mutabilityLock lock];
                    NSArray *internalReferences = self.downloadReferences[md5];
                    [self.downloadReferences removeObjectForKey:md5];
                    [strongSelf.mutabilityLock unlock];
                    NSParameterAssert(internalReferences);
                    for(NSDictionary *d in internalReferences) 
                    {
                        id object = d[@"reference"];
                        
                        NSNumber *rev = d[@"revision"];
                        
                        void(^internalCompletion)(NSData *data, id referenceObject,BOOL loadedFromCache) = d[@"completion"];
                        
                        NSNumber *internal = objc_getAssociatedObject(object, &revisionAssociationKey);
                        NSAssert(internal, @"reference must be present!");
                        if([internal isEqual:rev] || [object isKindOfClass:[NSNull class]]) 
                        {
                            //NSLog(@"!!!! %p, %@, %@: Downloaded, completing.", object, rev, [md5 substringToIndex:4]);
                            internalCompletion(processedData,object,NO);
                        } else {
                            //NSLog(@"!!!! %p, %@, %@: Downloaded, but another download underway (%@).", object, rev, [md5 substringToIndex:4], internal);
                        }
                    }
                });
            } referenceObject:strongReference];
        });
       
    });
}

- (void) getDataAtURL: (NSURL *)url withPriority:(NSOperationQueuePriority) priority completion:(void(^)(NSData *data, id referenceObject,BOOL loadedFromCache)) completion referenceObject: (id) reference
{
   [self getDataAtURL: url withPriority: priority postProcessingBlock: ^(NSData *data, id referenceObject) { return data; } completion: completion referenceObject: reference];
}

- (BOOL) removeImageForURL:(NSURL *)url 
{
    NSError *error = nil;
    return [self removeImageForURL:url error: &error];
}

- (BOOL) removeImageForURL:(NSURL *)url error: (NSError *__autoreleasing*) error
{
    NSString *md5 = [self MD5FromString:url.absoluteString];
    [self.mutabilityLock lock];
    NSData *retVal = [self.cache objectForKey:md5];
    if (retVal) 
    {
        [self.cache removeObjectForKey:md5];
        [self.mutabilityLock unlock];
        NSString *path = [self.cacheDir stringByAppendingPathComponent:[NSString stringWithFormat:@"%@.dat",md5]];
        BOOL success = [[NSFileManager defaultManager] removeItemAtPath:path error:error];
        if (error) {
            //NSLog(@"Error removing object: %@",*error);
        }
        return success;
    }
    [self.mutabilityLock unlock];
    return NO;
}

- (void) removeCache {
    [self.mutabilityLock lock];
    NSError *error;
    [[NSFileManager defaultManager] removeItemAtPath:self.cacheDir error:&error];
    //NSLog(@"ERROR: ", error.localizedDescription);
    [[NSFileManager defaultManager] createDirectoryAtPath:self.cacheDir withIntermediateDirectories:YES attributes:nil error: &error];
    //NSLog(@"ERROR: ", error.localizedDescription);
    [self.cache removeAllObjects];
    [self.mutabilityLock unlock];
}

#pragma mark - Utilities

- (void) downloadDataAtUrl: (NSURL *)url withPriority: (NSOperationQueuePriority) priority completion: (void(^)(NSData *data, id referenceObject)) completion referenceObject: (id) reference {
    [self downloadDataAtUrl: url withPriority: priority queue: dispatch_get_main_queue() completion: completion referenceObject: reference];
}

- (void) downloadDataAtUrl: (NSURL *)url withPriority: (NSOperationQueuePriority) priority queue: (dispatch_queue_t) queue completion: (void(^)(NSData *data, id referenceObject)) completion referenceObject: (id) reference {
    NSParameterAssert(url);
    NSParameterAssert(completion);
    __weak id weakReference = reference;
    NSURLSession *session = self.downloadSession;
        
    NSOperation *op = [NSBlockOperation blockOperationWithBlock:^{
        __block NSData *data;
        __block dispatch_semaphore_t semaphore = dispatch_semaphore_create(0);

        NSURLRequest *request = [NSURLRequest requestWithURL:url];
        
        NSURLSessionDataTask* task = [session dataTaskWithRequest:request completionHandler:^(NSData * _Nullable da, NSURLResponse * _Nullable response, NSError * _Nullable error) {
            data = da;
            dispatch_semaphore_signal(semaphore);
        }];
        
        [task resume];
        
        dispatch_semaphore_wait(semaphore, DISPATCH_TIME_FOREVER);
        id strongReference = weakReference;
        completion(data, strongReference);
    }];
    op.queuePriority = priority;
    [self.downloadQueue addOperation:op];
}

- (NSString*)MD5FromData:(NSData *)data
{
    // Create byte array of unsigned chars
    unsigned char md5Buffer[CC_MD5_DIGEST_LENGTH];
    
    // Create 16 byte MD5 hash value, store in buffer
    CC_MD5(data.bytes, (unsigned int)data.length, md5Buffer);
    
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
    CC_MD5(ptr, (unsigned int)strlen(ptr), md5Buffer);
    
    // Convert MD5 value in the buffer to NSString of hex values
    NSMutableString *output = [NSMutableString stringWithCapacity:CC_MD5_DIGEST_LENGTH * 2];
    for(int i = 0; i < CC_MD5_DIGEST_LENGTH; i++)
        [output appendFormat:@"%02x",md5Buffer[i]];
    
    return output;
}


@end
