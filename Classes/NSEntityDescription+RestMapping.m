//
//  NSEntityDescription+RestMapping.m
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

#import "NSEntityDescription+RestMapping.h"
#import "NSManagedObject+RestMapping.h"

@implementation NSEntityDescription (RestMapping)

-(NSString *)propertyKeyForJSONKey:(NSString *)key
{
    return [NSClassFromString(self.managedObjectClassName) propertyKeyForJSONKey:key];
}

-(NSArray *)JSONKeyForPropertyKey:(NSString *)key
{
    return [NSClassFromString(self.managedObjectClassName) JSONKeyForPropertyKey:key];
}

-(NSString *)identifierKey
{
    __block NSString *identifierKey = [NSClassFromString(self.managedObjectClassName) identifierKey];
    
    if (!identifierKey) {
        [self.attributesByName enumerateKeysAndObjectsUsingBlock:^(NSString *name, NSAttributeDescription *obj, BOOL *stop) {
            if ([name.lowercaseString isEqualToString:@"identifier"]) {
                identifierKey = name;
            }
            else if([name.lowercaseString hasSuffix:@"id"]) {
                identifierKey = name;
            }
        }];
    }
    
    return identifierKey;
}


-(NSManagedObject *)insertObjectFromDictionary:(NSDictionary *)dictionary inContext:(NSManagedObjectContext *)managedObjectContext {
    NSString *identifierKey = [self identifierKey];
    NSAssert(identifierKey!=nil, @"You need specify an identifier key to %@ entity.",self.name);
    NSArray *JSONKeys = [self JSONKeyForPropertyKey:identifierKey];
    __block NSString *identifier = nil;
    [JSONKeys enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        identifier = dictionary[obj];
        if (identifier) *stop = YES;
    }];
    NSAssert(identifier!=nil, @"Your dictionary need contain the identifier key %@ and it contain only keys %@.",identifierKey,[dictionary.allKeys componentsJoinedByString:@","]);
    
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
    [fetchRequest setEntity:[NSEntityDescription entityForName:self.name inManagedObjectContext:managedObjectContext]];
    [fetchRequest setPredicate:[NSPredicate predicateWithFormat:@"%K == %@",identifierKey,identifier]];    
    
    __block NSManagedObject *object = nil;
    [managedObjectContext performBlockAndWait:^{
        NSError *error = nil;
        object = [[managedObjectContext executeFetchRequest:fetchRequest error:&error] firstObject];
        if (!object) {
            object = [NSEntityDescription insertNewObjectForEntityForName:self.name inManagedObjectContext:managedObjectContext];
        }
        [object updateValuesForKeysWithDictionary:dictionary];
    }];
    return object;
}

-(NSManagedObject *)insertObjectFromID:(id)objectID inContext:(NSManagedObjectContext *)managedObjectContext {
    NSString *identifierKey = [self identifierKey];
    NSAssert(identifierKey!=nil, @"You need specify an identifier key to %@ entity.",self.name);
    
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
    [fetchRequest setEntity:[NSEntityDescription entityForName:self.name inManagedObjectContext:managedObjectContext]];
    [fetchRequest setPredicate:[NSPredicate predicateWithFormat:@"%K == %@",identifierKey,objectID]];
    
    __block NSManagedObject *object = nil;
    [managedObjectContext performBlockAndWait:^{
        NSError *error = nil;
        object = [[managedObjectContext executeFetchRequest:fetchRequest error:&error] firstObject];
        if (!object) {
            object = [NSEntityDescription insertNewObjectForEntityForName:self.name inManagedObjectContext:managedObjectContext];
        }
    }];
    return object;
}

-(NSSet *)insertObjectsFromJSONObject:(id)jsonObject inContext:(NSManagedObjectContext *)managedObjectContext {
    NSMutableSet *set = [NSMutableSet new];
    if ([jsonObject isKindOfClass:[NSArray class]]) {
        [jsonObject enumerateObjectsUsingBlock:^(NSDictionary *dic, NSUInteger idx, BOOL *stop) {
            if ([dic isKindOfClass:[NSDictionary class]]) {
                if (dic.allKeys.count > 0) {
                    [set addObject:[self insertObjectFromDictionary:dic inContext:managedObjectContext]];
                }
            }
            else if ([jsonObject isKindOfClass:[NSNull class]]) {
                [set addObject:dic];
            }
        }];
    }
    else if ([jsonObject isKindOfClass:[NSDictionary class]]){
        if ([jsonObject allKeys].count > 0) {
            [set addObject:[self insertObjectFromDictionary:jsonObject inContext:managedObjectContext]];
        }
    }
    else if ([jsonObject isKindOfClass:[NSString class]]||[jsonObject isKindOfClass:[NSNumber class]]) {
        [set addObject:[self insertObjectFromID:jsonObject inContext:managedObjectContext]];
    }
    else if ([jsonObject isKindOfClass:[NSNull class]]) {
        [set addObject:jsonObject];
    }
    else {
        NSAssert(false, @"%@ need be an NSArray or an NSDictionary. Verify your mapping.",jsonObject);
    }
    return set;
}

+(NSSet *)insertObjectsForEntityForName:(NSString *)entityName fromJSONObject:(id)jsonObject inContext:(NSManagedObjectContext *)managedObjectContext
{
    return [[self entityForName:entityName inManagedObjectContext:managedObjectContext] insertObjectsFromJSONObject:jsonObject inContext:managedObjectContext];
}

@end
