//
//  MLImageCache.h
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

/* Invalidates the image/data cache for specific URL */

- (BOOL) removeImageForURL:(NSURL *)url;
- (BOOL) removeImageForURL:(NSURL *)url error: (NSError *__autoreleasing*) error;


@end
