[![CI Status](https://travis-ci.org/hectr/MROperation.svg)](https://travis-ci.org/hectr/MROperation)
[![Version](https://img.shields.io/cocoapods/v/MROperation.svg?style=flat)](http://cocoadocs.org/docsets/MROperation)
[![License](https://img.shields.io/cocoapods/l/MROperation.svg?style=flat)](http://cocoadocs.org/docsets/MROperation)
[![Platform](https://img.shields.io/cocoapods/p/MROperation.svg?style=flat)](http://cocoadocs.org/docsets/MROperation)

# MROperation

`NSOperation` subclass that manages the concurrent execution of a block.

## Usage

You can use `MROperation` objects directly:

```objc
MROperation *someOperation = [[MROperation  alloc] initWithBlock:^(id<MRExecutingOperation> *operation) {
    // long ruinning task...
    if (operation.isCancelled) return;
    // long ruinning task...
    if (!operation.isFinished) [operation finishWithError:nil];
};

[someOperation start];
```

But you can also implement your own subclasses. See, for instance, how you could create a custom subclass for performing reverse-geocoding requests:

```objc
// MROperation subclass that performs reverse-geocoding requests.
@interface GeocodingRequestOperation : MROperation

// Returns a reverse-geocoding request operation for the given location.
+ (instancetype)operationWithLocation:(CLLocation *)location;

// The result of the reverse-geocoding request.
@property (nonatomic, strong) CLPlacemark *placemark;

@end

@implementation GeocodingRequestOperation

+ (instancetype)operationWithLocation:(CLLocation *)location {
    return [[self alloc] initWithBlock:^(GeocodingRequestOperation<MRExecutingOperation> *operation) {
        [[[CLGeocoder alloc] init] reverseGeocodeLocation:location completionHandler:^(NSArray *placemarks, NSError *error) {
            operation.placemark = placemarks.firstObject;
            if (!operation.isFinished) [operation finishWithError:error];
        }];
    }];
}

@end
```

And here's how you would execute them:

```objc
// Set up a queue:
_geocodingQueue = [[NSOperationQueue alloc] init];
_geocodingQueue.maxConcurrentOperationCount = 1;

// Create and configure the reverse-geocoding request operation:
GeocodingRequestOperation *o = [GeocodingRequestOperation operationWithLocation:location];
[o setCompletionBlockWithSuccess:^(GeocodingRequestOperation *operation) {
    NSLog(@"Hello %@!", operation.placemark.country);
} failure:^{
    NSLog(@"%@", error);
}];

// Add the operation to the queue:
[_geocodingQueue addOperation:o];

```

For another example on how to subclass `MRoperation`, you can refer to the `MRDetectBpmOperation` [implementation](https://github.com/hectr/MRDetectBpmOperation/blob/master/MRDetectBpmOperation/MRDetectBpmOperation.m).

## Installation

### CocoaPods

**MROperation** is available through [CocoaPods](http://cocoapods.org). To install
it, simply add the following line to your *Podfile*:

```ruby
pod "MROperation"
```

### Manually

Drag the *MROperation* folder into your project.

## License

**MROperation** is available under the MIT license. See the *LICENSE* file for more info.

# Alternatives

- <https://github.com/splinesoft/SSOperations>
