//
//  NSManagedObject+RestMapping.h
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

#import <CoreData/CoreData.h>

@interface NSManagedObject (RestMapping)

+(NSString *)propertyKeyForJSONKey:(NSString *)key;

+(NSString *)JSONKeyForPropertyKey:(NSString *)key;

+(NSDictionary *)keysForJSONKeys;

+(NSString *)identifierKey;

-(NSDate *)dateFromString:(NSString *)stringDate forPropertyNamed:(NSString *)propertyName;

-(id)formattedValueForAttributeKey:(NSString *)attributeKey withJSONValue:(id)value;

-(void)updateValuesForKeysWithDictionary:(NSDictionary *)keyedValues;

+(NSPredicate *)orphanedPredicate;

-(BOOL)isOrphan;

@end
