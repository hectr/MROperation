// MROperation.h
//
// Copyright (c) 2013 Héctor Marqués
//
// This software contains code derived from AFURLConnectionOperation
// Copyright (c) 2011 Gowalla (http://gowalla.com/)
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in
// all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
// THE SOFTWARE.

#import <Foundation/Foundation.h>

@protocol MRExecutingOperation;


/**
 Posted when an operation has begun executing.
 */
extern NSString *const MROperationDidStartNotification;

/**
 Posted when an operation has finished.
 */
extern NSString *const MROperationDidFinishNotification;


/**
 A protocol that represents a concrete operation.
 */
@protocol MRConcreteOperation <NSObject>

/**
 Returns the receiver's `userInfo`.
 
 @return The user info dictionary.
 */
- (NSDictionary *)userInfo;

/**
 Returns a `BOOL` value indicating whether the executing operation is currently
 executing.
 
 @return `YES` if the operation is executing; otherwise, `NO`.
 */
- (BOOL)isExecuting;

/**
 Returns a `BOOL` value indicating whether the executing operation is done
 executing.
 
 @return `YES` if the operation is no longer executing; otherwise, `NO`.
 */
- (BOOL)isFinished;

/**
 Returns a `BOOL` value indicating whether the executing operation has been
 cancelled.
 
 @return `YES` if the operation was cancelled; otherwise, `NO`.
 */
- (BOOL)isCancelled;

@end


/**
 The `MROperation` class is a concrete subclass of `NSOperation` that manages
 the concurrent execution of a block.
 
 The operation itself is not considered finished when the block has finished 
 executing, but when it is explicitly finished by invoking `finishWithError:` on
 the blocks parameter.
 */
@interface MROperation : NSOperation <MRConcreteOperation>

#if defined(COREANIMATION_H) & defined(__OBJC__)

/**
 Returns an operation that begins a transaction for executing the given block.
 
 @param transactionAnimations The block to be executed by the new operation 
 before committing the transaction.
 
 @return A new operation object.
 */
+ (instancetype)layerOperation:(void (^)(NSError **errorPtr))transactionAnimations;

#endif

/**
 The error, if any, that occurred in the lifecycle of the request.
 */
@property (readonly, nonatomic, strong) NSError *error;

/**
 The user info dictionary for the receiver.
 */
@property (nonatomic, strong) NSDictionary *userInfo;

/**
 Block executed when the operation is cancelled.
 **/
@property (nonatomic, copy) void (^onCancelBlock)(id<MRExecutingOperation> operation);

/**
 The callback dispatch queue on success. If `NULL` (default), the main queue is
 used.
 */
@property (nonatomic, assign) dispatch_queue_t successCallbackQueue;

/**
 The callback dispatch queue on failure. If `NULL` (default), the main queue is
 used.
 */
@property (nonatomic, assign) dispatch_queue_t failureCallbackQueue;

/**
 The callback dispatch queue on cancel. If `NULL` (default), the main queue is
 used.
 */
@property (nonatomic, assign) dispatch_queue_t onCancelCallbackQueue;

/**
 The dispatch queue for posting notifications. If `NULL` (default), the main
 queue is used.
 */
@property (nonatomic, assign) dispatch_queue_t notificationQueue;

/**
 Initializes and returns a newly allocated operation object that will execute 
 the given block.
 
 This is the designated initializer.
 
 @param block The block to be executed by the new operation.
 
 @return A new operation object.
 */
- (instancetype)initWithBlock:(void(^)(id<MRExecutingOperation> operation))block;

/**
 Specifies that the operation should continue execution after the app has 
 entered the background, and the expiration handler for that background task.
 
 @param handler A handler to be called shortly before the application’s 
 remaining background time reaches 0. The handler is wrapped in a block that 
 cancels the operation, and cleans up and marks the end of execution, unlike the
 `handler` parameter in 
 `UIApplication -beginBackgroundTaskWithExpirationHandler:`, which expects this 
 to be done in the handler itself. The handler is called synchronously on the
 main thread, thus blocking the application’s suspension momentarily while the 
 application is notified.
 */
#if defined(__IPHONE_OS_VERSION_MIN_REQUIRED)
- (void)setShouldExecuteAsBackgroundTaskWithExpirationHandler:(void (^)(void))handler;
#endif

/**
 Sets the `completionBlock` property with a block that executes either the
 specified success or failure block, depending on the `error` property of the
 receiver. If `error` returns a value then `failure` is executed. Otherwise,
 `success` is executed.
 
 @param success The block to be executed on the completion of a successful
 operation. This block has no return value and takes one argument: the receiver
 operation.
 @param failure The block to be executed on the completion of an unsuccessful
 operation. This block has no return value and takes two arguments: the receiver
 operation and the error that occurred during the operation execution.
 */
- (void)setCompletionBlockWithSuccess:(void (^)(id<MRConcreteOperation> operation))success
                              failure:(void (^)(id<MRConcreteOperation> operation, NSError *error))failure;

@end


/**
 A protocol that represents an operation that can be finished.
 
 See `initWithBlock:`.
 */
@protocol MRExecutingOperation <MRConcreteOperation>

/**
 Use this method for finishing the receiver with the given error.
 
 @param error The representation of the operation's execution result. May be 
 `nil` when the operation succeeded.
 */
- (void)finishWithError:(NSError *)error;

/**
 Advises the executing operation object that it should stop executing its task.
 */
- (void)cancel;

@end
