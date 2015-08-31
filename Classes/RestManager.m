//
//  RestManager.m
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

#import "RestManager.h"

#import "NSManagedObject+RestMapping.h"
#import "NSEntityDescription+RestMapping.h"


@implementation NSManagedObjectContext (Parsing)

/**
 *  Delete objects that have been orphaned
 */
-(void)deleteOrphaned {
    
    NSSet *objectsToDelete = [self.updatedObjects filteredSetUsingPredicate:
                              [NSPredicate predicateWithBlock:^BOOL(NSManagedObject *evaluatedObject, NSDictionary *bindings) {
        return [evaluatedObject isOrphan];
    }]];
    
    if (objectsToDelete.count>0) {
        [objectsToDelete enumerateObjectsUsingBlock:^(NSManagedObject *obj, BOOL *stop) {
            [self deleteObject:obj];
        }];
    }
}

-(NSError *)deleteOrphanedAndSave {
    NSError *error = nil;
    if (self.hasChanges) {
        [self deleteOrphaned];
        [self save:&error];
    }
    return error;
}

@end

NSString const* RestManagerErrorDomain = @"com.manager.rest.error.domain";

@interface RestManager ()
{
    NSMutableDictionary *_restRoutes;
    NSURL *_baseURL;
}

@end

@implementation RestManager

-(instancetype)initWithBaseURL:(NSURL *)baseURL mainManagedObjectContext:(NSManagedObjectContext *)mainManagedObjectContext andNetworkingDelegateClass:(Class)networkingDelegateClass
{
    self = [super init];
    if (self) {
        NSAssert([networkingDelegateClass conformsToProtocol:@protocol(RestNetworkingDelegate)], @"The networkingDelegateClass need be conform to RestNetworkingDelegate protocol.");
        _baseURL = baseURL;
        _networkingDelegate = [[networkingDelegateClass alloc] initWithBaseURL:baseURL];
        _globalParameters = nil;
        _mainManagedObjectContext = mainManagedObjectContext;
        _restRoutes = [NSMutableDictionary new];
    }
    return self;
}

-(void)addRestRoute:(RestRoute *)route withIdentifier:(id<NSCopying>)routeIdentifier
{
    [_restRoutes setObject:route forKey:routeIdentifier];
}

-(NSSet *)parseJsonObject:(id)jsonObject forRoute:(RestRoute *)route inContext:(NSManagedObjectContext *)importContext {
    if ([route subroutes]) {
        __block NSMutableSet *result = [NSMutableSet set];
        
        __weak typeof(self)weakSelf = self;
        
        [[route subroutes] enumerateKeysAndObjectsUsingBlock:^(id key, RestRoute *obj, BOOL *stop) {
            __strong __typeof(weakSelf)strongSelf = weakSelf;
            [result addObjectsFromArray:[[strongSelf parseJsonObject:jsonObject[key] forRoute:obj inContext:importContext] allObjects]];
        }];
        return result;
    }
    if (route.baseEntityName && jsonObject) {
        NSEntityDescription *baseEntity = [NSEntityDescription entityForName:route.baseEntityName inManagedObjectContext:importContext];
        
        return [baseEntity insertObjectsFromJSONObject:jsonObject inContext:importContext];
    }
    return nil;
}

-(void)callAPIForRouteIdentifier:(id<NSCopying>)routeIdentifier
                       forObject:(id)object
              withCallParameters:(NSDictionary *)callParameters
              andCompletionBlock:(APIRouteCompletionBlock)completionBlock
{
    NSAssert(_mainManagedObjectContext!=nil, @"Rest Manager need a mainManagedObjectContext to make the mapping");
    
    RestRoute *route = _restRoutes[routeIdentifier];
    NSAssert(route!=nil, @"No route added for identifier %@",routeIdentifier);
    
    NSMutableDictionary *parameters = [NSMutableDictionary new];
    
    if (callParameters) [parameters addEntriesFromDictionary:callParameters];
    if (_globalParameters) [parameters addEntriesFromDictionary:_globalParameters];
    if (route.routeParameters) [parameters addEntriesFromDictionary:route.routeParameters];
    
    if (parameters.count == 0) parameters = nil;
    
    APICallCompletionBlock successBlock = ^(id jsonObject, NSError *error) {
        if (error) {
            if (completionBlock) completionBlock(routeIdentifier,nil,error);
        }
        else if(jsonObject) {
            
            NSManagedObjectContext *importContext = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSPrivateQueueConcurrencyType];
            importContext.persistentStoreCoordinator = _mainManagedObjectContext.persistentStoreCoordinator;
            importContext.mergePolicy = NSOverwriteMergePolicy;            
            
            [importContext performBlock:^{
                NSSet *routeBaseObjects = [self parseJsonObject:jsonObject forRoute:route inContext:importContext];
                NSError *error = [importContext deleteOrphanedAndSave];
                
                if (completionBlock) {
                    completionBlock(routeIdentifier,routeBaseObjects,error);
                }
            }];
        }
        else {
            error = [NSError errorWithDomain:RestManagerErrorDomain.copy code:RestManagerNilJSONObjectError userInfo:@{}];
        }
    };
    
    if (route.isLocal) {
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
            NSError *error = error;
            NSData *data = [NSData dataWithContentsOfURL:[_baseURL URLByAppendingPathComponent:[route routeURLWithObject:nil]] options:NSDataReadingUncached error:&error];
            if (error) {
                successBlock(nil,error);
            }
            else {
                id jsonObject = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingMutableContainers error:&error];
                successBlock(jsonObject,error);
            }
        });
    }
    else {
        [_networkingDelegate callAPI:[route routeURLWithObject:object] forHTTPMethod:route.HTTPMethod withParameters:parameters andCompletionBlock:successBlock];
    }
}

-(void)callAPIForRouteIdentifier:(id<NSCopying>)routeIdentifier
              andCompletionBlock:(APIRouteCompletionBlock)completionBlock
{
    [self callAPIForRouteIdentifier:routeIdentifier forObject:nil withCallParameters:nil andCompletionBlock:completionBlock];
}

-(void)callAPIForRouteIdentifier:(id<NSCopying>)routeIdentifier
                       forObject:(id)object
              andCompletionBlock:(APIRouteCompletionBlock)completionBlock
{
    [self callAPIForRouteIdentifier:routeIdentifier forObject:object withCallParameters:nil andCompletionBlock:completionBlock];
}

-(void)callAPIForRouteIdentifier:(id<NSCopying>)routeIdentifier
              withCallParameters:(NSDictionary *)callParameters
              andCompletionBlock:(APIRouteCompletionBlock)completionBlock
{
    [self callAPIForRouteIdentifier:routeIdentifier forObject:nil withCallParameters:callParameters andCompletionBlock:completionBlock];
}



@end