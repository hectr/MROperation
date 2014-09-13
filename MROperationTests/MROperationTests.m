
#import <XCTest/XCTest.h>
#import <QuartzCore/QuartzCore.h>
#import "MROperation.h"


// Exposes MROperation setters needed in some tests.
@interface MROperation (Internal) <MRExecutingOperation>
@property (readwrite, nonatomic, assign) NSInteger state;
@property (readwrite, nonatomic, strong) NSError *error;
@property (readwrite, nonatomic, assign) NSUInteger backgroundTaskIdentifier;
@property (readwrite, nonatomic, copy) void (^operationBlock)(id<MRExecutingOperation>);
@end


#pragma mark -
#pragma mark -


// Subclass used for testing `setShouldExecuteAsBackgroundTaskWithExpirationHandler:` method.
@interface MRBackgroundTaskIdentifierTestOperation : MROperation
@end


@implementation MRBackgroundTaskIdentifierTestOperation

- (void)setBackgroundTaskIdentifier:(NSUInteger)backgroundTaskIdentifier
{
    [super setBackgroundTaskIdentifier:(backgroundTaskIdentifier ?: NSUIntegerMax)];
}

@end


#pragma mark -
#pragma mark -


// MROperation tests.
@interface MROperationTests : XCTestCase
@end


@implementation MROperationTests

#if defined(COREANIMATION_H) & defined(__OBJC__)

- (void)testThatLayerOperationResturnsAnInstance
{
    MROperation *operation =
    [MROperation layerOperation:^(NSError **errorPtr) { }];
    XCTAssertNotNil(operation);
}

- (void)testThatLayerOperationInvokesOperationBlock
{
    __block BOOL invoked = NO;
    MROperation *operation =
    [MROperation layerOperation:^(NSError **errorPtr) {
        invoked = YES;
    }];
    [operation start];
    XCTAssertTrue(invoked);
}

- (void)testThatLayerOperationBlockSetsError
{
    NSError *error = NSError.new;
    MROperation *operation =
    [MROperation layerOperation:^(NSError **errorPtr) {
        *errorPtr = error;
    }];
    [operation start];
    dispatch_group_t dispatchGroup = dispatch_group_create();
    dispatch_group_async(dispatchGroup, operation.successCallbackQueue ?: dispatch_get_main_queue(), ^{
        XCTAssertEqual(operation.error, error);
    });
}

#endif

- (void)testThatInitWithBlockReturnsAnInstance
{
    MROperation *operation =
    [[MROperation alloc] initWithBlock:^(id<MRExecutingOperation> operation) { }];
    XCTAssertNotNil(operation);
}

- testThatInitWithBlockSetsOperationBlock
{
    void (^block)(id<MRExecutingOperation>) = ^(id<MRExecutingOperation> operation) {
        XCTFail();
    };
    MROperation *operation =
    [[MROperation alloc] initWithBlock:block];
    XCTAssertNotNil(operation.operationBlock);
}

- (void)testThatSetCompletionBlocksSetsSuccessBlock
{
    __block BOOL invoked = NO;
    MROperation *operation =
    [[MROperation alloc] initWithBlock:^(id<MRExecutingOperation> operation) { }];
    [operation setCompletionBlockWithSuccess:^(MROperation *operation) {
        XCTAssertNotNil(operation);
        invoked = YES;
    } failure:^(MROperation *operation, NSError *error) {
        XCTFail();
    }];
    operation.completionBlock();
    dispatch_group_t dispatchGroup = dispatch_group_create();
    dispatch_group_async(dispatchGroup, operation.successCallbackQueue ?: dispatch_get_main_queue(), ^{
        XCTAssertTrue(invoked);
    });
}

- (void)testThatSetCompletionBlocksSetsFailureBlock
{
    __block BOOL invoked = NO;
    MROperation *operation =
    [[MROperation alloc] initWithBlock:^(id<MRExecutingOperation> operation) { }];
    [operation setCompletionBlockWithSuccess:^(MROperation *operation) {
        XCTFail();
    } failure:^(MROperation *operation, NSError *error) {
        XCTAssertNotNil(operation);
        invoked = YES;
    }];
    operation.error = NSError.new;
    operation.completionBlock();
    dispatch_group_t dispatchGroup = dispatch_group_create();
    dispatch_group_async(dispatchGroup, operation.failureCallbackQueue ?: dispatch_get_main_queue(), ^{
        XCTAssertTrue(invoked);
    });
}

- (void)testThatSetOnCancelBlockSetsOnCancelBlock
{
    __block BOOL invoked = NO;
    MROperation *operation =
    [[MROperation alloc] initWithBlock:^(id<MRExecutingOperation> operation) { }];
    operation.onCancelBlock = ^(id<MRExecutingOperation> operation) {
        XCTAssertNotNil(operation);
        invoked = YES;
    };
    [operation cancel];
    dispatch_group_t dispatchGroup = dispatch_group_create();
    dispatch_group_async(dispatchGroup, operation.onCancelCallbackQueue ?: dispatch_get_main_queue(), ^{
        XCTAssertTrue(invoked);
    });
}

- (void)testThatCompletionBlockIsInvokedOnlyOnceWhenFinished
{
    __block BOOL invoked = NO;
    MROperation *operation =
    [[MROperation alloc] initWithBlock:^(id<MRExecutingOperation> operation) {
        [operation finishWithError:nil];
    }];
    operation.completionBlock = ^{
        XCTAssertFalse(invoked);
        invoked = YES;
    };
    [operation start];
    [operation finishWithError:nil];
    [NSRunLoop.mainRunLoop runUntilDate:[NSDate dateWithTimeIntervalSinceNow:0.05]];
}

- (void)testThatCompletionBlockIsInvokedOnlyOnceWhenCancelled
{
    __block BOOL invoked = NO;
    MROperation *operation =
    [[MROperation alloc] initWithBlock:^(id<MRExecutingOperation> operation) { }];
    operation.completionBlock = ^{
        XCTAssertFalse(invoked);
        invoked = YES;
    };
    [operation cancel];
    [operation cancel];
    [NSRunLoop.mainRunLoop runUntilDate:[NSDate dateWithTimeIntervalSinceNow:0.05]];
}

- (void)testThatOnCancelBlockIsInvokedOnlyOnceWhenCancelled
{
    __block BOOL invoked = NO;
    MROperation *operation =
    [[MROperation alloc] initWithBlock:^(id<MRExecutingOperation> operation) { }];
    operation.onCancelBlock = ^(id<MRExecutingOperation> operation) {
        XCTAssertFalse(invoked);
        invoked = YES;
    };
    [operation cancel];
    [operation cancel];
    [NSRunLoop.mainRunLoop runUntilDate:[NSDate dateWithTimeIntervalSinceNow:0.05]];
}

- (void)testThatBlockIsInvokedWhenStarted
{
    __block BOOL invoked = NO;
    MROperation *operation =
    [[MROperation alloc] initWithBlock:^(id<MRExecutingOperation> operation) {
        invoked = YES;
    }];
    [operation start];
    XCTAssertTrue(invoked);
}

- (void)testThatStateChangesToExecutingWhenStarted
{
    NSInteger executionState = 2;
    MROperation *operation =
    [[MROperation alloc] initWithBlock:^(id<MRExecutingOperation> operation) { }];
    [operation start];
    XCTAssertEqual(operation.state, executionState);
}

- (void)testThatStateChangesToFinishedWhenFinishedWithoutError
{
    NSInteger finishedState = 3;
    MROperation *operation =
    [[MROperation alloc] initWithBlock:^(id<MRExecutingOperation> operation) {
        [operation finishWithError:nil];
    }];
    [operation start];
    XCTAssertEqual(operation.state, finishedState);
}

- (void)testThatStateChangesToFinishedWhenFinishedWithError
{
    NSInteger finishedState = 3;
    MROperation *operation =
    [[MROperation alloc] initWithBlock:^(id<MRExecutingOperation> operation) {
        [operation finishWithError:NSError.new];
    }];
    [operation start];
    XCTAssertEqual(operation.state, finishedState);
}

- (void)testThatFinishWithErrorSetsError
{
    MROperation *operation =
    [[MROperation alloc] initWithBlock:^(id<MRExecutingOperation> operation) {
        [operation finishWithError:NSError.new];
    }];
    [operation start];
    XCTAssert([operation.error isKindOfClass:NSError.class]);
}

- (void)testThatCancelSetsUserCancelledError
{
    NSError * userCancelledError = [NSError errorWithDomain:NSCocoaErrorDomain code:NSUserCancelledError userInfo:nil];
    MROperation *operation =
    [[MROperation alloc] initWithBlock:^(id<MRExecutingOperation> operation) { }];
    [operation cancel];
    XCTAssertEqualObjects(operation.error, userCancelledError);
}

- (void)testThatCancelWithinBlockChangesToFinishedState
{
    MROperation *operation =
    [[MROperation alloc] initWithBlock:^(id<MRExecutingOperation> operation) {
        [operation cancel];
    }];
    [operation start];
    XCTAssertTrue(operation.isFinished);
}

- (void)testThatExecutingOperationsIsExecuting
{
    MROperation *operation =
    [[MROperation alloc] initWithBlock:^(id<MRExecutingOperation> operation) {
        XCTAssertTrue(operation.isExecuting);
    }];
    [operation start];
}

- (void)testThatSetStateChangesFromReadyToExecution
{
    NSInteger executionState = 2;
    MROperation *operation =
    [[MROperation alloc] initWithBlock:^(id<MRExecutingOperation> operation) { }];
    operation.state = executionState;
    XCTAssertEqual(operation.state, executionState);
}

- (void)testThatSetStateDoesNotChangeFromReadyToFinished
{
    NSInteger finishedState = 3;
    MROperation *operation =
    [[MROperation alloc] initWithBlock:^(id<MRExecutingOperation> operation) { }];
    operation.state = finishedState;
    XCTAssertNotEqual(operation.state, finishedState);
}

- (void)testThatSetStateChangesFromReadyToFinishedWhenCancelled
{
    NSInteger finishedState = 3;
    MROperation *operation =
    [[MROperation alloc] initWithBlock:^(id<MRExecutingOperation> operation) { }];
    [operation cancel];
    operation.state = finishedState;
    XCTAssertEqual(operation.state, finishedState);
}

- (void)testThatSetStateDoesNotChangeFromExecutingToReady
{
    NSInteger readyState = 1;
    MROperation *operation =
    [[MROperation alloc] initWithBlock:^(id<MRExecutingOperation> operation) { }];
    [operation start];
    operation.state = readyState;
    XCTAssertNotEqual(operation.state, readyState);
}

- (void)testThatSetStateChangesFromExecutingToFinished
{
    NSInteger finishedState = 3;
    MROperation *operation =
    [[MROperation alloc] initWithBlock:^(id<MRExecutingOperation> operation) { }];
    [operation start];
    operation.state = finishedState;
    XCTAssertEqual(operation.state, finishedState);
}

- (void)testThatSetStateDoesNotChangeFromFinishedToReady
{
    NSInteger readyState = 1;
    MROperation *operation =
    [[MROperation alloc] initWithBlock:^(id<MRExecutingOperation> operation) {
        [operation finishWithError:nil];
    }];
    [operation start];
    operation.state = readyState;
    XCTAssertNotEqual(operation.state, readyState);
}

- (void)testThatSetStateDoesNotChangeFromFinishedToExecuting
{
    NSInteger executingState = 2;
    MROperation *operation =
    [[MROperation alloc] initWithBlock:^(id<MRExecutingOperation> operation) {
        [operation finishWithError:nil];
    }];
    [operation start];
    operation.state = executingState;
    XCTAssertNotEqual(operation.state, executingState);
}

- (void)testThatIsReadyAccountsDependencies
{
    MROperation *dependency =
    [[MROperation alloc] initWithBlock:^(id<MRExecutingOperation> operation) { }];
    MROperation *operation =
    [[MROperation alloc] initWithBlock:^(id<MRExecutingOperation> operation) {
        XCTFail();
    }];
    [operation addDependency:dependency];
    XCTAssertFalse(operation.isReady);
}

- (void)testThatIsExecutingCorrespondsToExecutingState
{
    MROperation *operation =
    [[MROperation alloc] initWithBlock:^(id<MRExecutingOperation> operation) { }];
    [operation start];
    XCTAssertTrue(operation.isExecuting);
}

- (void)testThatIsExecutingCorrespondsToFinishedState
{
    MROperation *operation =
    [[MROperation alloc] initWithBlock:^(id<MRExecutingOperation> operation) {
        [operation finishWithError:nil];
    }];
    [operation start];
    XCTAssertTrue(operation.isFinished);
}

- (void)testThatIsConcurrentReturnsYes
{
    MROperation *operation =
    [[MROperation alloc] initWithBlock:^(id<MRExecutingOperation> operation) { }];
    XCTAssertTrue(operation.isConcurrent);
}

- (void)testThatReadyOperationDescriptionIsCorrect
{
    MROperation *operation =
    [[MROperation alloc] initWithBlock:^(id<MRExecutingOperation> operation) { }];
    NSString *format = @"<MROperation: %p, state: isReady, cancelled: NO>";
    NSString *description = [NSString stringWithFormat:format, operation];
    XCTAssertEqualObjects(operation.description, description);
}

- (void)testThatExecutingOperationDescriptionIsCorrect
{
    MROperation *operation =
    [[MROperation alloc] initWithBlock:^(id<MRExecutingOperation> operation) { }];
    [operation start];
    NSString *format = @"<MROperation: %p, state: isExecuting, cancelled: NO>";
    NSString *description = [NSString stringWithFormat:format, operation];
    XCTAssertEqualObjects(operation.description, description);
}

- (void)testThatCancelledOperationDescriptionIsCorrect
{
    MROperation *operation =
    [[MROperation alloc] initWithBlock:^(id<MRExecutingOperation> operation) { }];
    [operation cancel];
    NSString *format = @"<MROperation: %p, state: isFinished, cancelled: YES>";
    NSString *description = [NSString stringWithFormat:format, operation];
    XCTAssertEqualObjects(operation.description, description);
}

- (void)testThatDidStartNotificationIsPostedWhenStarted
{
    __block BOOL observed = NO;
    MROperation *operation =
    [[MROperation alloc] initWithBlock:^(id<MRExecutingOperation> operation) { }];
    [operation start];
    NSNotificationCenter *defaultCenter = NSNotificationCenter.defaultCenter;
    [defaultCenter addObserverForName:MROperationDidStartNotification
                               object:operation
                                queue:nil
                           usingBlock:^(NSNotification *note) {
                               XCTAssertFalse(observed);
                               observed = YES;
                           }];
    [operation start];
    dispatch_group_t dispatchGroup = dispatch_group_create();
    dispatch_group_async(dispatchGroup, operation.notificationQueue ?: dispatch_get_main_queue(), ^{
        XCTAssertTrue(observed);
    });
}

- (void)testThatDidFinishNotificationIsPostedWhenFinished
{
    __block BOOL finished = NO;
    __block BOOL observed = NO;
    MROperation *operation =
    [[MROperation alloc] initWithBlock:^(id<MRExecutingOperation> operation) {
        finished = YES;
        [operation finishWithError:nil];
    }];
    [operation start];
    NSNotificationCenter *defaultCenter = NSNotificationCenter.defaultCenter;
    [defaultCenter addObserverForName:MROperationDidFinishNotification
                               object:operation
                                queue:nil
                           usingBlock:^(NSNotification *note) {
                               XCTAssertTrue(finished);
                               XCTAssertFalse(observed);
                               observed = YES;
                           }];
    [operation start];
    dispatch_group_t dispatchGroup = dispatch_group_create();
    dispatch_group_async(dispatchGroup, operation.notificationQueue ?: dispatch_get_main_queue(), ^{
        XCTAssertTrue(observed);
    });
}

- (void)testThatDidFinishNotificationIsPostedEveryFinishWithErrorInvocation
{
    __block BOOL finished = NO;
    __block BOOL observed = NO;
    __block BOOL observedAgain = NO;
    MROperation *operation =
    [[MROperation alloc] initWithBlock:^(id<MRExecutingOperation> operation) {
        finished = YES;
        [operation finishWithError:nil];
    }];
    [operation start];
    NSNotificationCenter *defaultCenter = NSNotificationCenter.defaultCenter;
    [defaultCenter addObserverForName:MROperationDidFinishNotification
                               object:operation
                                queue:nil
                           usingBlock:^(NSNotification *note) {
                               XCTAssertTrue(finished);
                               if (observed) {
                                   XCTAssertFalse(observedAgain);
                                   observedAgain = YES;
                               } else {
                                   observed = YES;
                               }
                           }];
    [operation start];
    [operation finishWithError:nil];
    dispatch_group_t dispatchGroup = dispatch_group_create();
    dispatch_group_async(dispatchGroup, operation.notificationQueue ?: dispatch_get_main_queue(), ^{
        XCTAssertTrue(observed);
    });
}

#if defined(__IPHONE_OS_VERSION_MIN_REQUIRED)
- (void)testThatSetShouldExecuteAsBackgroundTaskSetsBackgroundTaskIdentifier
{
    MRBackgroundTaskIdentifierTestOperation *operation =
    [[MRBackgroundTaskIdentifierTestOperation alloc] initWithBlock:^(id<MRExecutingOperation> operation) { }];
    [operation setShouldExecuteAsBackgroundTaskWithExpirationHandler:^{ }];
    XCTAssertNotEqual(operation.backgroundTaskIdentifier, 0);
}
#endif

@end
