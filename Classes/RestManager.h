//
//  RestManager.h
//  RestManager
//
//  Created by Aurélien Scelles on 24/06/2015.
//
//  The MIT License (MIT)
//
//  Copyright (c) 2015 Aurélien Scelles
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in all
//  copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
//  SOFTWARE.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>
#import "RestRoute.h"
#import "NSManagedObject+RestMapping.h"
#import "NSEntityDescription+RestMapping.h"

#define RMILog(...) if([RestManager logLevel] >= RMLogLevelInfo) NSLog(__VA_ARGS__)
#define RMELog(...) if([RestManager logLevel] >= RMLogLevelError) NSLog(__VA_ARGS__)
#define RMFLog(...) if([RestManager logLevel] >= RMLogLevelFull) NSLog(__VA_ARGS__)

typedef void(^APIRouteCompletionBlock)(id<NSCopying> routeIdentifier,NSSet *routeBaseObjects, NSError *error, NSInteger statusCode);

typedef enum : NSUInteger {
    RMLogNone = 0,
    RMLogLevelInfo = 1,
    RMLogLevelError = 2,
    RMLogLevelFull = 3,
} RMLogLevel;

extern NSString const* RestManagerErrorDomain;
typedef enum : NSUInteger {
    RestManagerNilJSONObjectError = -5002,
} RestManagerErrorCode;

@protocol RestNetworkingDelegate;
@interface RestManager : NSObject

@property (nonatomic,weak) NSManagedObjectContext *networkManagedObjectContext;

@property (nonatomic,strong) NSDictionary *globalParameters;

@property (nonatomic,readonly,strong) id <RestNetworkingDelegate> networkingDelegate;

+(void)setLogLevel:(RMLogLevel)logDegree;
+(RMLogLevel)logLevel;



/**
 *  Init RestManager with baseURL and custom networkingDelegateClass
 *
 *  @param baseURL                  The base url of the API
 *  @param mainManagedObjectContext The main context which will be use to import objects
 *  @param networkingDelegateClass  A networking class that is conform to protocol RestNetworkingDelegate
 *
 *  @return A RestManager
 */
-(instancetype)initWithBaseURL:(NSURL *)baseURL networkManagedObjectContext:(NSManagedObjectContext *)networkManagedObjectContext andNetworkingDelegateClass:(Class)networkingDelegateClass;

-(void)addRestRoute:(RestRoute *)route withIdentifier:(id<NSCopying>)routeIdentifier;

-(void)callAPIForRouteIdentifier:(id<NSCopying>)routeIdentifier
              andCompletionBlock:(APIRouteCompletionBlock)completionBlock;

-(void)callAPIForRouteIdentifier:(id<NSCopying>)routeIdentifier
                       forObject:(id)object
              andCompletionBlock:(APIRouteCompletionBlock)completionBlock;

-(void)callAPIForRouteIdentifier:(id<NSCopying>)routeIdentifier
              withCallParameters:(NSDictionary *)callParameters
              andCompletionBlock:(APIRouteCompletionBlock)completionBlock;

-(void)callAPIForRouteIdentifier:(id<NSCopying>)routeIdentifier
                       forObject:(id)object
              withCallParameters:(NSDictionary *)callParameters
              andCompletionBlock:(APIRouteCompletionBlock)completionBlock;


@end

typedef void(^APICallCompletionBlock)(id jsonObject, NSError *error, NSInteger statusCode);

/**
 Define the rest networking delegate protocol
 */
@protocol RestNetworkingDelegate <NSObject>

@required
/**
 *  An init method that take baseURL
 *
 *  @param baseURL the base URL for this manager
 *
 */
-(id)initWithBaseURL:(NSURL *)baseURL;
/**
 *  Call the API for the defined routes
 *
 *  @param urlString       The api components (Example: application/1)
 *  @param method          The route defined httpmethod
 *  @param parameters      A concatenation of parameters from Route and Manager
 *  @param completionBlock The block that will need to be call to start the mapping 
 *                         (take an already parsed jsonObject -with NSJSONSerialisation or other- and an optional error)
 */
-(void)callAPI:(NSString *)urlString forHTTPMethod:(RestHTTPMethod)method withParameters:(NSDictionary *)parameters andCompletionBlock:(APICallCompletionBlock)completionBlock;

@end
