//
//  NSManagedObject+RestMapping.m
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

#import "ISO8601DateFormatter.h"
#import "RestManager.h"

@implementation NSManagedObject (RestMapping)

+(NSString *)propertyKeyForJSONKey:(NSString *)key
{
    if ([self conformsToProtocol:@protocol(RestMapping)]) {
        id<RestMapping> mappingSelf = (id<RestMapping>)self;
        NSDictionary *keys = [mappingSelf keysForJSONKeys];
        if (keys[key]) {
            key = keys[key];
        }
    }
    return key;
}

+(NSArray *)JSONKeyForPropertyKey:(NSString *)key
{
    if ([self conformsToProtocol:@protocol(RestMapping)]) {
        id<RestMapping> mappingSelf = (id<RestMapping>)self;
        NSDictionary *keys = [mappingSelf keysForJSONKeys];
        if ([keys allKeysForObject:key]) {
            return [@[key] arrayByAddingObjectsFromArray:[keys allKeysForObject:key]];
        }
    }
    
    return @[key];
}

+(NSString *)identifierKey
{
    return nil;
}

+(NSPredicate *)orphanedPredicate
{
    return nil;
}

-(BOOL)isOrphan {
    NSPredicate *predicate = [self.class orphanedPredicate];
    if (!predicate) {
        return NO;
    }
    return [@[self] filteredArrayUsingPredicate:predicate].count!=0;
}

-(NSDate *)dateFromString:(NSString *)stringDate forPropertyNamed:(NSString *)propertyName {
    return [[ISO8601DateFormatter new] dateFromString:stringDate];
}


-(id)formattedValueForAttributeKey:(NSString *)attributeKey withJSONValue:(id)value {
    NSAttributeDescription *attribute = [self attributes][attributeKey];
    id formattedValue = value;
    if (![formattedValue isKindOfClass:attribute.class]) {
        switch (attribute.attributeType) {
            case NSInteger16AttributeType:
            case NSInteger32AttributeType:
            case NSInteger64AttributeType:
            case NSDecimalAttributeType:
            case NSDoubleAttributeType:
            case NSFloatAttributeType:
            case NSBooleanAttributeType:
            if ([value isKindOfClass:[NSString class]]) {
                NSNumberFormatter *f = [NSNumberFormatter new];
                if ([value rangeOfString:@","].location!=NSNotFound) {
                    [f setDecimalSeparator:@","];
                }
                else {
                    [f setDecimalSeparator:@"."];
                }
                f.numberStyle = NSNumberFormatterDecimalStyle;
                formattedValue = [f numberFromString:value];
            }
            else if(![value isKindOfClass:[NSNumber class]]){
                formattedValue = [NSNull null];
            }
            break;
            case NSStringAttributeType:
            if ([value isKindOfClass:[NSNumber class]]) {
                formattedValue = [value stringValue];
            }
            else if(![value isKindOfClass:[NSString class]]){
                formattedValue = [NSNull null];
            }
            break;
            case NSDateAttributeType:
            if ([value isKindOfClass:[NSNumber class]]) {
                value = [value stringValue];
            }
            if ([value isKindOfClass:[NSString class]]) {
                formattedValue = [self dateFromString:value forPropertyNamed:attributeKey];
            }
            else {
                formattedValue = [NSNull null];
            }
            break;
            
            default:
            break;
        }
    }
    if ([formattedValue isKindOfClass:[NSString class]] && [formattedValue isEqualToString:@"null"]) {
        formattedValue = [NSNull null];
    }
    return formattedValue;
}


-(id)formattedValueForRelationKey:(NSString *)relationKey withJSONValue:(id)value andPagedKeys:(NSArray *)pagedKeys {
    NSRelationshipDescription *relationship = [self relationships][relationKey];
    id formattedValue = nil;
    if (![value isKindOfClass:relationship.destinationEntity.class]) {
        NSSet *set = [relationship.destinationEntity insertObjectsFromJSONObject:value inContext:self.managedObjectContext withPagedKeys:pagedKeys];
        if (relationship.toMany) {
            if ([pagedKeys containsObject:relationKey]) {
                NSSet *previousValues = [self valueForKey:relationKey];
                formattedValue = [previousValues setByAddingObjectsFromSet:set];
            }
            else {
                formattedValue = set;
            }
        }
        else {
            formattedValue = [[set allObjects] firstObject];
        }
    }
    else {
        formattedValue = value;
    }
    return formattedValue;
}

-(id)formattedValuesForUnknownKey:(NSString *)unknownKey withJSONValue:(id)value andPagedKeys:(NSArray *)pagedKeys
{
    if ([value isKindOfClass:[NSDictionary class]]) {
        NSMutableDictionary *propertyKeyedValues = [NSMutableDictionary new];
        [value enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
            NSString *newKey = [@[unknownKey,key] componentsJoinedByString:@"."];
            [propertyKeyedValues setValuesForKeysWithDictionary:[self formattedValueForKey:newKey withJSONValue:obj andPagedKeys:pagedKeys]];
        }];
    }
    return nil;
}


-(NSDictionary *)relationships {
    
    NSMutableDictionary *relationships = [NSMutableDictionary new];
    NSEntityDescription *entity = self.entity;
    while (entity) {
        [relationships addEntriesFromDictionary:entity.relationshipsByName];
        entity = entity.superentity;
    }
    return relationships.copy;
}

-(NSArray *)relationshipsKeys{
    return [[self relationships] allKeys];
}

-(NSDictionary *)attributes {
    
    NSMutableDictionary *attributes = [NSMutableDictionary new];
    NSEntityDescription *entity = self.entity;
    while (entity) {
        [attributes addEntriesFromDictionary:entity.attributesByName];
        entity = entity.superentity;
    }
    return attributes.copy;
}
-(NSArray *)attributesKeys
{
    return [[self attributes] allKeys];
}

-(id)formattedValueForKey:(NSString *)key withJSONValue:(id)value andPagedKeys:(NSArray *)pagedKeys{
    
    NSArray *relationshipsKeys = [self relationshipsKeys];
    NSArray *attributesKeys = [self attributesKeys];
    NSMutableDictionary *propertyKeyedValues = [NSMutableDictionary new];
    
    NSString *propertyKey = [self.entity propertyKeyForJSONKey:key];
    if ([value isKindOfClass:[NSNull class]]) {
        [propertyKeyedValues setObject:value forKey:propertyKey];
    }
    else {
        if ([relationshipsKeys containsObject:propertyKey]) {
            id object = [self formattedValueForRelationKey:propertyKey withJSONValue:value andPagedKeys:pagedKeys];
            if (object) {
                [propertyKeyedValues setObject:object forKey:propertyKey];
            }
            RMFLog(@"relation %@(%@) value %@",propertyKey,key,object);
        }
        else if ([attributesKeys containsObject:propertyKey]){
            id object = [self formattedValueForAttributeKey:propertyKey withJSONValue:value];
            if (object) {
                [propertyKeyedValues setObject:object forKey:propertyKey];
            }
            RMFLog(@"attribute %@(%@) value %@",propertyKey,key,object);
        }
        else {
            id newValues = [self formattedValuesForUnknownKey:propertyKey withJSONValue:value andPagedKeys:pagedKeys];
            if (newValues) {
                [propertyKeyedValues setValuesForKeysWithDictionary:newValues];
            }
            else {
                RMELog(@"unknown %@ - %@",propertyKey,value);
            }
        }
    }
    return propertyKeyedValues;
}

-(void)updateValuesForKeysWithDictionary:(NSDictionary *)keyedValues withPagedKeys:(NSArray *)pagedKeys{
    NSMutableDictionary *propertyKeyedValues = [NSMutableDictionary new];
    [keyedValues enumerateKeysAndObjectsUsingBlock:^(NSString * key, id obj, BOOL *stop) {
        [propertyKeyedValues addEntriesFromDictionary:[self formattedValueForKey:key withJSONValue:obj andPagedKeys:pagedKeys]];
    }];
    [self setValuesForKeysWithDictionary:propertyKeyedValues.copy];
}
@end
