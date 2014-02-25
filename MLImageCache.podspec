#
#  Be sure to run `pod spec lint MLImageCache.podspec' to ensure this is a
#  valid spec and to remove all comments including this before submitting the spec.
#
#  To learn more about Podspec attributes see http://docs.cocoapods.org/specification.html
#  To see working Podspecs in the CocoaPods repo see https://github.com/CocoaPods/Specs/
#

Pod::Spec.new do |s|

  # ―――  Spec Metadata  ―――――――――――――――――――――――――――――――――――――――――――――――――――――――――― #
  #
  #  These will help people to find your library, and whilst it
  #  can feel like a chore to fill in it's definitely to your advantage. The
  #  summary should be tweet-length, and the description more in depth.
  #

  s.name         = "MLImageCache"
  s.version      = "1.0.0"
  s.summary      = "Simple yet powerful and fast image cache."

  s.description  = <<-DESC
                 # MLImageCache
                 ## Simple yet powerful asynchronous image cache
                 
                 MLImageCache has been written as an alternative to clumsy [SDWebCache](https://github.com/rs/SDWebImage). It is based on NSOperation / NSOperationQueue combo, which gives it additional features and safety. 
                 
                 The highlights:
                 
                 * Two .m files and .h files. Just drag to your project and go. You can also use CocoaPods.
                 * Asynchronous download and disk read gives it an unmatched speed. It does not interfere with scrolling.
                 * Uses ARC and is carefully engineered not to induce strong reference cycles. It's memory reliability is thoroughly tested.
                 * It downloads only one copy of an image no matter how many times has it been requested.
                 * It can download arbitrary data, not only images.
                 * It supports prioritization and simultaneous downloads based on NSOperationQueue priority system.
                 
                 ## Installation
                   
                 Use CocoaPods or copy those 4 files directly into the project. In the latter case you also have to install [ASIHTTPRequest](http://allseeing-i.com/ASIHTTPRequest/). 
                   
                 If you wonder why do I use this seemingly obsolete library compare its stability and functionality to [AFNetworking](https://github.com/AFNetworking/AFNetworking). It does not change interface every few months and is super-stable and tested. 
                   
                 ## How to use it?
                   
                     #import "UIImageView+Cache.h"
                     ...
                     [self.imageView setImageWithURL: self.urlToImage ];
                 And that's it! You can replace SDImageCache instantly. For more advanced features see MLImageCache.h
                                       
                   DESC

  s.homepage     = "https://github.com/mll/MLImageCache"
  # s.screenshots  = "www.example.com/screenshots_1", "www.example.com/screenshots_2"


  # ―――  Spec License  ――――――――――――――――――――――――――――――――――――――――――――――――――――――――――― #
  #
  #  Licensing your code is important. See http://choosealicense.com for more info.
  #  CocoaPods will detect a license file if there is a named LICENSE*
  #  Popular ones are 'MIT', 'BSD' and 'Apache License, Version 2.0'.
  #

  s.license      = 'MIT'
  # s.license      = { :type => 'MIT', :file => 'FILE_LICENSE' }


  # ――― Author Metadata  ――――――――――――――――――――――――――――――――――――――――――――――――――――――――― #
  #
  #  Specify the authors of the library, with email addresses. Email addresses
  #  of the authors by using the SCM log. E.g. $ git log. If no email can be
  #  found CocoaPods accept just the names.
  #

  s.author             = { "Marek Lipert" => "marek.lipert@gmail.com" }
  # s.authors          = { "Marek Lipert" => "marek.lipert@gmail.com", "other author" => "email@address.com" }
  # s.author           = 'Marek Lipert', 'other author'
  # s.social_media_url = "http://twitter.com/Marek Lipert"

  # ――― Platform Specifics ――――――――――――――――――――――――――――――――――――――――――――――――――――――― #
  #
  #  If this Pod runs only on iOS or OS X, then specify the platform and
  #  the deployment target. You can optionally include the target after the platform.
  #

  # s.platform     = :ios
  # s.platform     = :ios, '4.0'

  #  When using multiple platforms
   s.ios.deployment_target = '4.0'
   s.osx.deployment_target = '10.6'


  # ――― Source Location ―――――――――――――――――――――――――――――――――――――――――――――――――――――――――― #
  #
  #  Specify the location from where the source should be retrieved.
  #  Supports git, hg, bzr, svn and HTTP.
  #

  s.source       = { :git => "http://github.com/mll/MLImageCache.git", :tag => "1.0.0" }


  # ――― Source Code ―――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――― #
  #
  #  CocoaPods is smart about how it includes source code. For source files
  #  giving a folder will include any h, m, mm, c & cpp files. For header
  #  files it will include any header in the folder.
  #  Not including the public_header_files will make all headers public.
  #

  s.source_files  = 'Classes', 'Classes/**/*.{h,m}'
  s.exclude_files = 'Classes/Exclude'

  # s.public_header_files = 'Classes/**/*.h'


  # ――― Resources ―――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――― #
  #
  #  A list of resources included with the Pod. These are copied into the
  #  target bundle with a build phase script. Anything else will be cleaned.
  #  You can preserve files from being cleaned, please don't preserve
  #  non-essential files like tests, examples and documentation.
  #

  # s.resource  = "icon.png"
  # s.resources = "Resources/*.png"

  # s.preserve_paths = "FilesToSave", "MoreFilesToSave"


  # ――― Project Linking ―――――――――――――――――――――――――――――――――――――――――――――――――――――――――― #
  #
  #  Link your library with frameworks, or libraries. Libraries do not include
  #  the lib prefix of their name.
  #

  # s.framework  = 'SomeFramework'
  # s.frameworks = 'SomeFramework', 'AnotherFramework'

  # s.library   = 'iconv'
  # s.libraries = 'iconv', 'xml2'


  # ――― Project Settings ――――――――――――――――――――――――――――――――――――――――――――――――――――――――― #
  #
  #  If your library depends on compiler flags you can set them in the xcconfig hash
  #  where they will only apply to your library. If you depend on other Podspecs
  #  you can include multiple dependencies to ensure it works.

   s.requires_arc = true

  # s.xcconfig = { 'HEADER_SEARCH_PATHS' => '$(SDKROOT)/usr/include/libxml2' }
   s.dependency 'ASIHTTPRequest', '~> 1.8'

end
