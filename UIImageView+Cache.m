#import "UIImageView+Cache.h"
#import "objc/runtime.h"
#import "MLImageCache.h"




@implementation UIImageView (MLImageCache)


- (void)setImageWithURL:(NSURL *)url
{
    [self setImageWithURL:url placeholderImage:nil options:0 progress:nil completed:nil];
}

- (void)setImageWithURL:(NSURL *)url placeholderImage:(UIImage *)placeholder
{
    [self setImageWithURL:url placeholderImage:placeholder options:0 progress:nil completed:nil];
}

- (void)setImageWithURL:(NSURL *)url placeholderImage:(UIImage *)placeholder options:(SDWebImageOptions)options
{
    [self setImageWithURL:url placeholderImage:placeholder options:options progress:nil completed:nil];
}

- (void)setImageWithURL:(NSURL *)url completed:(SDWebImageCompletedBlock)completedBlock
{
    [self setImageWithURL:url placeholderImage:nil options:0 progress:nil completed:completedBlock];
}

- (void)setImageWithURL:(NSURL *)url placeholderImage:(UIImage *)placeholder completed:(SDWebImageCompletedBlock)completedBlock
{
    [self setImageWithURL:url placeholderImage:placeholder options:0 progress:nil completed:completedBlock];
}

- (void)setImageWithURL:(NSURL *)url placeholderImage:(UIImage *)placeholder options:(SDWebImageOptions)options completed:(SDWebImageCompletedBlock)completedBlock
{
    [self setImageWithURL:url placeholderImage:placeholder options:options progress:nil completed:completedBlock];
}

- (void)setImageWithURL:(NSURL *)url placeholderImage:(UIImage *)placeholder options:(SDWebImageOptions)options progress:(SDWebImageDownloaderProgressBlock)progressBlock completed:(SDWebImageCompletedBlock)completedBlock
{
    self.image = placeholder; /* nil if nil */

    
    if(url.absoluteString.length == 0) return;
    
    [[MLImageCache sharedInstance] getImageAtURL:url withPriority:NSOperationQueuePriorityNormal completion:^(UIImage *image, id referenceObject,BOOL loadedFromCache) {
        UIImageView *strongSelf = referenceObject;
        if(!strongSelf || !image) {
            return;
        }

        strongSelf.image = image;
        if(loadedFromCache == NO)
        {
          strongSelf.alpha = 0.0;
          [UIView animateWithDuration:0.2 animations:^{
            strongSelf.alpha = 1.0;
          }];
        }
      
        if(completedBlock) completedBlock(image,nil,SDImageCacheTypeMemory);
    } referenceObject:self];
}

- (void) cancelCurrentImageLoad
{
    
}


+ (void) cacheImage:(UIImage*)image forUrl:(NSURL*)forUrl {
    [[MLImageCache sharedInstance] cacheImage:image withUrl:forUrl];
}

@end
