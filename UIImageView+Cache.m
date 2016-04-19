
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



#import "UIImageView+Cache.h"
#import "objc/runtime.h"
#import "MLImageCache.h"


static int oldURLKey = 0;

@implementation UIImageView (MLImageCache)


- (void)setImageWithURL:(NSURL *)url
{
    [self mll_setImageWithURL:url placeholderImage:nil options:0 progress:nil completed:nil];
}

- (void)setImageWithURL:(NSURL *)url placeholderImage:(UIImage *)placeholder
{
    [self mll_setImageWithURL:url placeholderImage:placeholder options:0 progress:nil completed:nil];
}

- (void)setImageWithURL:(NSURL *)url placeholderImage:(UIImage *)placeholder options:(SDWebImageOptions)options
{
    [self mll_setImageWithURL:url placeholderImage:placeholder options:options progress:nil completed:nil];
}

- (void)setImageWithURL:(NSURL *)url completed:(SDWebImageCompletedBlock)completedBlock
{
    [self mll_setImageWithURL:url placeholderImage:nil options:0 progress:nil completed:completedBlock];
}

- (void)setImageWithURL:(NSURL *)url placeholderImage:(UIImage *)placeholder completed:(SDWebImageCompletedBlock)completedBlock
{
    [self mll_setImageWithURL:url placeholderImage:placeholder options:0 progress:nil completed:completedBlock];
}

- (void)setImageWithURL:(NSURL *)url placeholderImage:(UIImage *)placeholder options:(SDWebImageOptions)options completed:(SDWebImageCompletedBlock)completedBlock
{
    [self mll_setImageWithURL:url placeholderImage:placeholder options:options progress:nil completed:completedBlock];
}


- (void)mll_setImageWithURL:(NSURL *)url
{
    [self mll_setImageWithURL:url placeholderImage:nil options:0 progress:nil completed:nil];
}

- (void)mll_setImageWithURL:(NSURL *)url placeholderImage:(UIImage *)placeholder
{
    [self mll_setImageWithURL:url placeholderImage:placeholder options:0 progress:nil completed:nil];
}

- (void)mll_setImageWithURL:(NSURL *)url placeholderImage:(UIImage *)placeholder options:(SDWebImageOptions)options
{
    [self mll_setImageWithURL:url placeholderImage:placeholder options:options progress:nil completed:nil];
}

- (void)mll_setImageWithURL:(NSURL *)url completed:(SDWebImageCompletedBlock)completedBlock
{
    [self mll_setImageWithURL:url placeholderImage:nil options:0 progress:nil completed:completedBlock];
}

- (void)mll_setImageWithURL:(NSURL *)url placeholderImage:(UIImage *)placeholder completed:(SDWebImageCompletedBlock)completedBlock
{
    [self mll_setImageWithURL:url placeholderImage:placeholder options:0 progress:nil completed:completedBlock];
}

- (void)mll_setImageWithURL:(NSURL *)url placeholderImage:(UIImage *)placeholder options:(SDWebImageOptions)options completed:(SDWebImageCompletedBlock)completedBlock
{
    [self mll_setImageWithURL:url placeholderImage:placeholder options:options progress:nil completed:completedBlock];
}

- (void) setImageWithURL:(NSURL *)url placeholderImage:(UIImage *)placeholder options:(SDWebImageOptions)options progress:(SDWebImageDownloaderProgressBlock)progressBlock completed:(SDWebImageCompletedBlock)completedBlock
{
  [self mll_setImageWithURL:(NSURL *)url placeholderImage:placeholder options:options progress:progressBlock completed:completedBlock];
}

- (void)mll_setImageWithURL:(NSURL *)url placeholderImage:(UIImage *)placeholder options:(SDWebImageOptions)options progress:(SDWebImageDownloaderProgressBlock)progressBlock completed:(SDWebImageCompletedBlock)completedBlock
{
    NSURL *oldURL = objc_getAssociatedObject(self, &oldURLKey);
    
    
    if(![oldURL isEqual:url])
        self.image = placeholder; /* nil if nil */

    
    if(url.absoluteString.length == 0) return;
    
    [[MLImageCache sharedInstance] getImageAtURL:url withPriority:NSOperationQueuePriorityNormal completion:^(UIImage *image, id referenceObject,BOOL loadedFromCache) {
        UIImageView *strongSelf = referenceObject;
        if(!strongSelf || !image) {
            return;
        }
        if(![strongSelf.image isEqual:image])
        {
           strongSelf.image = image;
           if(loadedFromCache == NO)
           {
               CATransition *transition = [CATransition animation];
               transition.duration = 0.2f;
               transition.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut];
               transition.type = kCATransitionFade;
               
               [strongSelf.layer addAnimation:transition forKey:nil];
           }
        }
        objc_setAssociatedObject(strongSelf, &oldURLKey, url, OBJC_ASSOCIATION_COPY_NONATOMIC);
        if(completedBlock) completedBlock(image,nil,SDImageCacheTypeMemory);
    } referenceObject:self];
}

- (void) cancelCurrentImageLoad
{
    [self mll_cancelCurrentImageLoad];
}

- (void) mll_cancelCurrentImageLoad
{
    
}


+ (void) cacheImage:(UIImage*)image forUrl:(NSURL*)forUrl {
    [[MLImageCache sharedInstance] cacheImage:image withUrl:forUrl];
}

+ (void) mll_cacheImage:(UIImage*)image forUrl:(NSURL*)forUrl {
    [[MLImageCache sharedInstance] cacheImage:image withUrl:forUrl];
}


@end
