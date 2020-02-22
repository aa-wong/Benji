![Benji - Developer's Best Friend in Fetch Requests](https://raw.githubusercontent.com/aa-wong/Benji/master/Benji-logo.png)

Benji is a lightweight HTTP networking library written in Swift for simple HTTP requests and uploading/downloading files.


## Philosophy

A simple interface for making RESTful HTTP requests.

## Requirements

- iOS 8.0+ / macOS 10.10+ / tvOS 9.0+ / watchOS 2.0+
- Xcode 11+
- Swift 4.2+

## Installation

### CocoaPods

[CocoaPods](https://cocoapods.org) is a dependency manager for Cocoa projects. You can install it with the following command:

```bash
$ gem install cocoapods
```

> CocoaPods 1.1+ is required to build Benji 1.0+.

To integrate Benji into your Xcode project using CocoaPods, specify it in your `Podfile`:

```ruby
platform :ios, '10.0'
use_frameworks!

target '<Your Target Name>' do
pod 'Benji'
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

## API Documentation

### Create Instance
Import the framework into the file you wish to use in.
```swift
import Benji
```
Regular initialization or singleton reference is supported for global use.
```swift
let benji = Benji() // init
// or
let benji = Benji.shared // singleton
```
### Base parameters
Base parameters can be set per instance to be used for all requests made by Benij.

optional baseURL parameter takes in a string URL to be a referenced for all calls with concatenated URIs.
```swift
self.benji.baseURL : String = "https://api.<domain>.com/v2"
```

optional baseHeaders parameter takes in a dictionary of header parameters to be applied to all http requests.
```swift
self.benji.baseHeaders : [String : String] = [
   "<header Key>" : "<header value>"
]

```

### HTTP Requests
All HTTP request methods below. Each method contains a callback with optional parameters that will return if they are available. The following parameters return are below:

```swift
error: Error? // returns when requests errors out
response: HTTPURLResponse? // returns with http response details
data: Any? // returns data when request is successful
```

If baseURL is set, applied url strings to the methods below will append to the baseURL.

baseURL + applied url

if baseHeaders are set, any headers that are applied to the methods below will be append to the baseHeaders for the request.

```swift
// GET
self.benji.GET(url: String,
               headers: [String : String]?,
               completion: (Error?, HTTPURLResponse?, Any?) -> Void)

// POST
self.benji.POST(url: String,
                headers: [String : String]?,
                body: Any,
                completion: (Error?, HTTPURLResponse?, Any?) -> Void)

// PUT
self.benji.PUT(url: String,
               headers: [String : String]?,
               body: Any,
               completion: (Error?, HTTPURLResponse?, Any?) -> Void)

// PATCH
self.benji.PATCH(url: String,
                 headers: [String : String]?,
                 body: Any,
                 completion: (Error?, HTTPURLResponse?, Any?) -> Void)

// DELETE
self.benji.DELETE(url: String,
                  headers: [String : String]?,
                  completion: (Error?, HTTPURLResponse?, Any?) -> Void)
```

FETCH is a super function that is an alternative way to execute all the requests above. All that is required is to apply the BenjiRequestType.

```swift
self.benji.FETCH(type: BenjiRequestType,
                 url: String,
                 headers: [String : String]?,
                 body: Any?,
                 completion: (Error?, HTTPURLResponse?, Any?) -> Void)
```

#### Benji Fetch Delegate
if monitoring of errors or logs are required through RESTful fetch requests. Set the following:
```swift
BenjiFetchDelegate // Set BenjiFetchDelegate to the delegate class
self.benji.fetchDelegate = self // Assign the fetchDelegate on the Benji instance

// Set the following optional delegate methods
func benjiDidGetError(_ error: Error) // returns when error occurs during fetch requests

func benjiLogRequest(_ log: [String : Any]) // returns log details of the fetch requests
```

### HTTP File Downloader
When using the Benji File Downloader like the Fetch requests, all baseURLs and baseHeaders if set will be applied.

```swift
self.benji.DOWNLOAD(url:String,
                    headers: [String : String]?,
                    completion: (Error?, HTTPURLResponse?, Any?) -> Void)
```
#### Benji Download Delegate
The BenjiDownloadDelegate can be used to monitor download progress and to retrieve the file location when download is complete.

```swift
BenjiDownloadDelegate // Set BenjiDownloadDelegate to the delegate class
self.benji.downloadDelegate = self // Assign the downloadDelegate on the Benji instance

// Set the following optional delegate methods
func benjiDidGetDownloadProgress(_ progress:Float, percentage:Int) // returns download progress values.
func benjiDownloadComplete(_ location: URL) // returns location url on device for the completed file downloaded.
```

### HTTP File Uploader
When using the Benji File Uploader like the Fetch requests, all baseURLs and baseHeaders if set will be applied.
Required parameters are fileName and filePath.
```swift
self.benji.UPLOAD(url:String,
                  type: BenjiRequestType,
                  headers: [String : String]?,
                  body:[String : Any]?,
                  fileName:String, // Name of file to upload
                  filePath: String, // location path of the file to upload
                  completion: (Error?, HTTPURLResponse?, Any?) -> Void)
```
#### Benji Upload Delegate
The BenjiUploadDelegate can be used to monitor upload progress.

```swift
BenjiUploadDelegate // Set BenjiUploadDelegate to the delegate class
self.benji.uploadDelegate = self // Assign the uploadDelegate on the Benji instance

// Set the following optional delegate methods
func benjiDidGetUploadProgress(_ progress:Float, percentage:Int) // returns upload progress values.
func benjiUploadComplete() // executed when file upload completes.
```

### Static Download Methods
Static downloaders do not support baseURL or baseHeaders. When requesting for data with the following functions, be sure to supply the full URL.
```swift
// SYNCHRONOUS DOWNLOAD REQUEST
Benji.syncFileDownload(url: String) -> Data?

// ASYNCHRONOUS DOWNLOAD REQUEST
Benji.asyncFileDownload(url: String, completion: (Error?, Data?) -> Void)
```

### Static Benji Parser
The following functions below are helper functions for JSON parsing. Use dataFromObject to parse swift objects to Data and objectFromData when wanting to parse an object from valid JSON data.
```swift
// parse object into JSON data
BenjiParser.dataFromObject(object: Any,
                           completion: (Error?, Data?) -> Void)

// parse object from JSON data
BenjiParser.objectFromData(data: Data,
                           completion: (Error?, Any?) -> Void)
```
