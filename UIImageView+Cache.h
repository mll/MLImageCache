//
//  RWImageView+Cache.h
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


typedef enum
{
    /**
     * By default, when a URL fail to be downloaded, the URL is blacklisted so the library won't keep trying.
     * This flag disable this blacklisting.
     */
    SDWebImageRetryFailed = 1 << 0,
    /**
     * By default, image downloads are started during UI interactions, this flags disable this feature,
     * leading to delayed download on UIScrollView deceleration for instance.
     */
    SDWebImageLowPriority = 1 << 1,
    /**
     * This flag disables on-disk caching
     */
    SDWebImageCacheMemoryOnly = 1 << 2,
    /**
     * This flag enables progressive download, the image is displayed progressively during download as a browser would do.
     * By default, the image is only displayed once completely downloaded.
     */
    SDWebImageProgressiveDownload = 1 << 3,
    /**
     * Even if the image is cached, respect the HTTP response cache control, and refresh the image from remote location if needed.
     * The disk caching will be handled by NSURLCache instead of SDWebImage leading to slight performance degradation.
     * This option helps deal with images changing behind the same request URL, e.g. Facebook graph api profile pics.
     * If a cached image is refreshed, the completion block is called once with the cached image and again with the final image.
     *
     * Use this flag only if you can't make your URLs static with embeded cache busting parameter.
     */
    SDWebImageRefreshCached = 1 << 4
} SDWebImageOptions;


enum SDImageCacheType
{
    /**
     * The image wasn't available the SDWebImage caches, but was downloaded from the web.
     */
    SDImageCacheTypeNone = 0,
    /**
     * The image was obtained from the disk cache.
     */
    SDImageCacheTypeDisk,
    /**
     * The image was obtained from the memory cache.
     */
    SDImageCacheTypeMemory
};
typedef enum SDImageCacheType SDImageCacheType;

typedef void(^SDWebImageDownloaderProgressBlock)(NSUInteger receivedSize, long long expectedSize);
typedef void(^SDWebImageDownloaderCompletedBlock)(UIImage *image, NSData *data, NSError *error, BOOL finished);

typedef void(^SDWebImageCompletedBlock)(UIImage *image, NSError *error, SDImageCacheType cacheType);
typedef void(^SDWebImageCompletedWithFinishedBlock)(UIImage *image, NSError *error, SDImageCacheType cacheType, BOOL finished);

@interface UIImageView (MLImageCache)

- (void)mll_setImageWithURL:(NSURL *)url;
- (void)mll_setImageWithURL:(NSURL *)url placeholderImage:(UIImage *)placeholder;
- (void)mll_setImageWithURL:(NSURL *)url placeholderImage:(UIImage *)placeholder options:(SDWebImageOptions)options;
- (void)mll_setImageWithURL:(NSURL *)url completed:(SDWebImageCompletedBlock)completedBlock;
- (void)mll_setImageWithURL:(NSURL *)url placeholderImage:(UIImage *)placeholder completed:(SDWebImageCompletedBlock)completedBlock;
- (void)mll_setImageWithURL:(NSURL *)url placeholderImage:(UIImage *)placeholder options:(SDWebImageOptions)options completed:(SDWebImageCompletedBlock)completedBlock;
- (void)mll_setImageWithURL:(NSURL *)url placeholderImage:(UIImage *)placeholder options:(SDWebImageOptions)options progress:(SDWebImageDownloaderProgressBlock)progressBlock completed:(SDWebImageCompletedBlock)completedBlock;
- (void)mll_cancelCurrentImageLoad;

- (void)setImageWithURL:(NSURL *)url;
- (void)setImageWithURL:(NSURL *)url placeholderImage:(UIImage *)placeholder;
- (void)setImageWithURL:(NSURL *)url placeholderImage:(UIImage *)placeholder options:(SDWebImageOptions)options;
- (void)setImageWithURL:(NSURL *)url completed:(SDWebImageCompletedBlock)completedBlock;
- (void)setImageWithURL:(NSURL *)url placeholderImage:(UIImage *)placeholder completed:(SDWebImageCompletedBlock)completedBlock;
- (void)setImageWithURL:(NSURL *)url placeholderImage:(UIImage *)placeholder options:(SDWebImageOptions)options completed:(SDWebImageCompletedBlock)completedBlock;
- (void)setImageWithURL:(NSURL *)url placeholderImage:(UIImage *)placeholder options:(SDWebImageOptions)options progress:(SDWebImageDownloaderProgressBlock)progressBlock completed:(SDWebImageCompletedBlock)completedBlock;
- (void)cancelCurrentImageLoad;


+ (void)mll_cacheImage:(UIImage*)image forUrl:(NSURL*)forUrl;
+ (void)cacheImage:(UIImage*)image forUrl:(NSURL*)forUrl;


@end
