//
//  RestRoute.m
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

#import "RestRoute.h"
#import "NSEntityDescription+RestMapping.h"
#import "NSManagedObject+RestMapping.h"

@interface RestRoute ()
{
    
}

@end

@implementation RestRoute

+(instancetype)localRestRouteWithPattern:(NSString *)pattern andBaseEntityName:(NSString *)baseEntityName
{
    RestRoute *route = [[RestRoute alloc] initWithPattern:pattern andBaseEntityName:baseEntityName];
    route.isLocal = YES;
    return route;
}

+(instancetype)httpRestRouteWithPattern:(NSString *)pattern baseEntityName:(NSString *)baseEntityName andHTTPMethod:(RestHTTPMethod)method
{
    RestRoute *route = [[RestRoute alloc] initWithPattern:pattern andBaseEntityName:baseEntityName];
    route.HTTPMethod = method;
    return route;
}

- (instancetype)initWithPattern:(NSString *)pattern andBaseEntityName:(NSString *)baseEntityName
{
    self = [super init];
    if (self) {
        self.pattern = pattern;
        self.baseEntityName = baseEntityName;
        self.HTTPMethod = RestHTTPMethodGET;
        self.routeParameters = nil;
        self.isLocal = NO;
    }
    return self;
}

- (instancetype)init
{
    self = [super init];
    if (self) {
        self.pattern = nil;
        self.baseEntityName = nil;
        self.HTTPMethod = RestHTTPMethodGET;
        self.routeParameters = nil;
        self.isLocal = NO;
    }
    return self;
}

-(NSArray *)keysForPattern {
    NSAssert(_pattern!=nil, @"Route Pattern cannot be nil.");
    NSArray *pathComponents = [_pattern pathComponents];
    NSArray *keys = [pathComponents filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"SELF BEGINSWITH %@",@":"]];
    return keys;
}


-(NSString *)routeURLWithObject:(id)object
{
    if (!object) {
        return self.pattern;
    }
    else {
        NSArray *keys = [self keysForPattern];
        __block NSString *routeUrl = self.pattern;
        [keys enumerateObjectsUsingBlock:^(NSString *key, NSUInteger idx, BOOL *stop) {
            NSString *value = [NSString stringWithFormat:@"%@",[object valueForKeyPath:[key substringFromIndex:1]]];
            NSAssert(value!=nil, @"The object %@ need have a value for key %@",object,key);
            routeUrl = [routeUrl stringByReplacingOccurrencesOfString:[NSString stringWithFormat:@"%@",key] withString:value];
        }];
        return routeUrl;
    }
    return nil;
}

@end
