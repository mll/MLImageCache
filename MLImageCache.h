//
//  MLImageCache.h
//  
//
//  Created by Marek Lipert on 01.01.2014.
//  Copyright (c) 2014 Marek Lipert. All rights reserved.
//

#import <Foundation/Foundation.h>

#define kNumberOfSimultaneousDownloads 1

@interface MLImageCache : NSObject

+ (MLImageCache *) sharedInstance;

/* This method gets an image from cache/downloads it. 
   It fires a background operation and fires completion
   
   referenceObject is a reference to object that can be passed to a block. It is a weak reference, though, so you may end up receiving nil even if you put sth there. */

- (void) getImageAtURL: (NSURL *)url withPriority:(NSOperationQueuePriority) priority completion:(void(^)(UIImage *image, id referenceObject,BOOL loadedFromCache)) completion referenceObject: (id) reference;

/* This does the same with data */

- (void) getDataAtURL: (NSURL *)url withPriority:(NSOperationQueuePriority) priority completion:(void(^)(NSData *data, id referenceObject,BOOL loadedFromCache)) completion referenceObject: (id) reference;

/* caches image with url */

- (BOOL) cacheImage: (UIImage *) image withUrl: (NSURL *)url;

/* caches NSData with url */

- (BOOL) cacheData: (NSData *) data withUrl: (NSURL *)url;


/* Tries to load url from disk to memory cache */

- (BOOL) prefetchFromURL: (NSURL *)url;


@end
