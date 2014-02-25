# MLImageCache
## Simple yet powerful asynchronous image cache

MLImageCache has been written as an alternative to clumsy SDWebCache. It is based on NSOperation / NSOperationQueue combo, which gives it additional features and safety. 

The highlights:

* Two .m files and .h files. Just drag to your project and go. You can also use CocoaPods.
* Asynchronous download and disk read gives it an unmatched speed. It does not interfere with scrolling.
* Uses ARC and is carefully engineered not to induce strong reference cycles. It's memory reliability is thoroughly tested.
* It downloads only one copy of an image no matter how many times has it been requested.
* It can download arbitrary data, not only images.
* It supports prioritization and simultaneous downloads based on NSOperationQueue priority system.

## Installation
  
Use CocoaPods or copy those 4 files directly into the project. In the latter case you alos have to install ASIHTTPRequest. 

If you wonder why do I use this seemingly obsolete library compare its stability and functionality to AFNetworking. It does not change interface every few months and is super-stable and tested. 
