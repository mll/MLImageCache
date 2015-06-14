# MLImageCache
## Simple yet powerful asynchronous image cache

MLImageCache has been written as an alternative to clumsy [SDWebCache](https://github.com/rs/SDWebImage). It is based on NSOperation / NSOperationQueue combo, which gives it additional features and safety. 

The highlights:

* Two .m files and .h files. Just drag to your project and go. You can also use CocoaPods.
* Asynchronous download and disk read gives it an unmatched speed. It does not interfere with scrolling.
* Uses ARC and is carefully engineered not to induce strong reference cycles. It's memory reliability is thoroughly tested.
* It downloads only one copy of an image no matter how many times has it been requested.
* If multiple downloads are initiated with the same image view, only the last one is processed (important for reusable cells in table views)
* It can download arbitrary data, not only images.
* It supports prioritization and simultaneous downloads based on NSOperationQueue priority system.

## Installation
  
Use CocoaPods or copy those 4 files directly into the project. 

    pod 'MLImageCache'

## How to use it?

    #import "UIImageView+Cache.h"
    
    ...
    
    [self.imageView mll_setImageWithURL: self.urlToImage ];
    
    or simply 
    
    [self.imageView setImageWithURL: self.urlToImage ];

    if it does not collide with other libs.

And that's it! You can replace SDImageCache instantly. For more advanced features see MLImageCache.h
