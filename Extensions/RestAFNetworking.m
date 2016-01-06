//
//  RestAFNetworking.m
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

#import "RestAFNetworking.h"

@implementation RestAFNetworking


-(instancetype)initWithBaseURL:(NSURL *)url {
    self = [super initWithBaseURL:url];
    self.completionQueue = dispatch_queue_create("com.rest.manager.parsequeue", DISPATCH_QUEUE_SERIAL);
//    self.completionGroup = dispatch_group_create();
    return self;
}

-(void)callAPI:(NSString *)urlString forHTTPMethod:(RestHTTPMethod)method withParameters:(NSDictionary *)parameters andCompletionBlock:(APICallCompletionBlock)completionBlock
{
    void(^successBlock)(NSURLSessionDataTask *, id) = ^(NSURLSessionDataTask *task, id responseObject) {
        completionBlock(responseObject,nil,((NSHTTPURLResponse *)task.response).statusCode);
    };
    
    void(^failureBlock)(NSURLSessionDataTask *, NSError *) = ^(NSURLSessionDataTask *task, NSError *error) {
        completionBlock(nil,error,((NSHTTPURLResponse *)task.response).statusCode);
    };
    switch (method) {
        case RestHTTPMethodGET:
        {
            [self GET:urlString parameters:parameters success:successBlock failure:failureBlock];
        }
            break;
            
        case RestHTTPMethodPOST:
        {
            [self POST:urlString parameters:parameters success:successBlock failure:failureBlock];
        }
            break;
            
        case RestHTTPMethodPUT:
        {
            [self PUT:urlString parameters:parameters success:successBlock failure:failureBlock];
        }
            break;
            
        case RestHTTPMethodDELETE:
        {
            [self DELETE:urlString parameters:parameters success:successBlock failure:failureBlock];
        }
            break;
            
        case RestHTTPMethodHEAD:
        {
            [self HEAD:urlString parameters:parameters success:^(NSURLSessionDataTask *task) {
                completionBlock(nil,nil,((NSHTTPURLResponse *)task.response).statusCode);
            } failure:failureBlock];
        }
            break;
            
        case RestHTTPMethodPATCH:
        {
            [self PATCH:urlString parameters:parameters success:successBlock failure:failureBlock];
        }
            break;
    }
}

@end

@implementation RestManager (RestAFNetworking)

- (instancetype)initWithBaseURL:(NSURL *)baseURL andNetworkManagedObjectContext:(NSManagedObjectContext *)networkManagedObjectContext
{
    return [self initWithBaseURL:baseURL networkManagedObjectContext:networkManagedObjectContext andNetworkingDelegateClass:[RestAFNetworking class]];
}

-(RestAFNetworking *)afNetworkingDelegate
{
    return (RestAFNetworking *)self.networkingDelegate;
}

@end