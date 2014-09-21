[![Build Status](https://travis-ci.org/hectr/MROperation.svg)](https://travis-ci.org/hectr/MROperation)

# MROperation

`NSOperation` subclass that manages the concurrent execution of a block.

## Installation

### From CocoaPods

Add `pod 'MROperation'` to your *Podfile*.

### Manually

Drag the *MROperation* folder into your project.

## Usage

You can use `MROperation` objects directly. But you can also implement your own subclasses. See, for instance, how you could create a custom subclass for performing reverse-geocoding requests:

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
[o setCompletionBlockWithSuccess:^(MROperation *operation) {
        NSLog(@"Hello %@!", [(GeocodingRequestOperation *)o placemark].country);
} failure:nil];

// Add the operation to the queue:
[_geocodingQueue addOperation:o];

```

## License

**MROperation** is available under the MIT license. See the *LICENSE* file for more info.
