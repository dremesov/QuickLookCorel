QuickLookCorel
==============

This is OS X QuickLook thumbnail generator for CorelDRAW Graphics Files (.CDR).

It does not render vector data in files **yet**, just uses embedded thumbnails

Also included small tool for exploring RIFF container files

Uses [ZipKit](https://github.com/kolpanic/ZipKit) from [CocoaPods](https://github.com/CocoaPods/CocoaPods)

[Get prebuilt installer package](http://charlieroot.github.io/files/QuickLookCorel.pkg)

Screenshot of icons

![Icons screenshot](http://charlieroot.github.io/images/shot1.png)

Screenshot of preview (automatically uses thumbnail for now)

![Preview screenshot](http://charlieroot.github.io/images/shot2.png)

#### Manual installation

* Prerequisites

  [Xcode](http://developer.apple.com), [CocoaPods](https://github.com/CocoaPods/CocoaPods)
  
* Build

  ```
  $ pod install
  $ xcodebuild -workspace QuickLookCorel.xcworkspace -scheme QuickLookCorel -configuration Release
  ```
  QuickLookCorel.qlgenerator then get installed in ~/Library/QuickLook