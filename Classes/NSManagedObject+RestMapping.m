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

#import "NSManagedObject+RestMapping.h"
#import "NSEntityDescription+RestMapping.h"
#import "ISO8601DateFormatter.h"

@implementation NSManagedObject (RestMapping)

+(NSDictionary *)keysForJSONKeys
{
    return nil;
}

+(NSDictionary *)managedKeysForJSONKeys {
    NSDictionary *keys = [self keysForJSONKeys];
    if ([self respondsToSelector:@selector(globalKeysForJSONKeys)]) {
        NSMutableDictionary *mKeys = [self performSelector:@selector(globalKeysForJSONKeys)];
        [mKeys addEntriesFromDictionary:keys];
        keys = [mKeys copy];
    }
    return keys;
}

+(NSString *)propertyKeyForJSONKey:(NSString *)key
{
    NSDictionary *keys = [self managedKeysForJSONKeys];
    return keys[key]?:key;
}

+(NSArray *)JSONKeyForPropertyKey:(NSString *)key
{
    NSDictionary *keys = [self managedKeysForJSONKeys];
    return [keys allKeysForObject:key]?[@[key] arrayByAddingObjectsFromArray:[keys allKeysForObject:key]]:@[key];
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
    NSAttributeDescription *attribute = self.entity.attributesByName[attributeKey];
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
                    f.numberStyle = NSNumberFormatterDecimalStyle;
                    formattedValue = [f numberFromString:value];
                }
                break;
            case NSStringAttributeType:
                if ([value isKindOfClass:[NSNumber class]]) {
                    formattedValue = [value stringValue];
                }
                break;
            case NSDateAttributeType:
                if ([value isKindOfClass:[NSNumber class]]) {
                    value = [value stringValue];
                }
                if ([value isKindOfClass:[NSString class]]) {
                    formattedValue = [self dateFromString:value forPropertyNamed:attributeKey];
                }
                break;
                
            default:
                break;
        }
    }
    return formattedValue;
}


-(id)formattedValueForRelationKey:(NSString *)relationKey withJSONValue:(id)value {
    NSRelationshipDescription *relationship = self.entity.relationshipsByName[relationKey];
    id formattedValue = nil;
    if (![value isKindOfClass:relationship.destinationEntity.class]) {
        NSSet *set = [relationship.destinationEntity insertObjectsFromJSONObject:value inContext:self.managedObjectContext ];
        if (relationship.toMany) {
            formattedValue = set;
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

-(void)updateValuesForKeysWithDictionary:(NSDictionary *)keyedValues {
    NSArray *relationshipsKeys = [self.entity.relationshipsByName allKeys];
    NSArray *attributesKeys = [self.entity.attributesByName allKeys];
    NSMutableDictionary *propertyKeyedValues = [NSMutableDictionary new];
    
    [keyedValues enumerateKeysAndObjectsUsingBlock:^(NSString * key, id obj, BOOL *stop) {
        NSString *propertyKey = [self.entity propertyKeyForJSONKey:key];
        if ([relationshipsKeys containsObject:propertyKey]) {
            [propertyKeyedValues setObject:[self formattedValueForRelationKey:propertyKey withJSONValue:obj] forKey:propertyKey];
        }
        else if ([attributesKeys containsObject:propertyKey]){
            [propertyKeyedValues setObject:[self formattedValueForAttributeKey:propertyKey withJSONValue:obj] forKey:propertyKey];
        }
    }];
    [self setValuesForKeysWithDictionary:propertyKeyedValues];
}
@end
