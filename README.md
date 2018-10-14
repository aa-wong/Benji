![Benji - Developer's Best Friend in Fetch Requests](https://raw.githubusercontent.com/aa-wong/Benji/master/Benji-logo.png)

Benji is a lightweight HTTP networking library written in Swift for simple HTTP API requests using JSON and uploading/downloading files.


## Philosophy

A simple interface for making RESTful HTTP with JSON.

## Requirements

- iOS 8.0+ / macOS 10.10+ / tvOS 9.0+ / watchOS 2.0+
- Xcode 8.3+
- Swift 3.1+

## Installation

### CocoaPods

[CocoaPods](https://cocoapods.org) is a dependency manager for Cocoa projects. You can install it with the following command:

```bash
$ gem install cocoapods
```

> CocoaPods 1.1+ is required to build Benji 1.0+.

To integrate Benji into your Xcode project using CocoaPods, specify it in your `Podfile`:

```ruby
source 'https://github.com/CocoaPods/Specs.git'
platform :ios, '10.0'
use_frameworks!

target '<Your Target Name>' do
pod 'Benji', '~> 1.0'
end
```

Then, run the following command:

```bash
$ pod install
```

### Manually

If you prefer not to use any of the aforementioned dependency managers, you can integrate Benji into your project manually.

#### Embedded Framework

- Clone the Benji repo. 
- Open Benji.xcodeproj and build the Benji Framework
- Import the Benji Framework into you .xcodeproj
