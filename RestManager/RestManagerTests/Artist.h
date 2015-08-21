//
//  Artist.h
//  RestManager
//
//  Created by Aurélien Scelles on 20/08/2015.
//  Copyright (c) 2015 Celor. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class Album;

@interface Artist : NSManagedObject

@property (nonatomic, retain) NSNumber * identifier;
@property (nonatomic, retain) NSString * name;
@property (nonatomic, retain) NSSet *albums;
@end

@interface Artist (CoreDataGeneratedAccessors)

- (void)addAlbumsObject:(Album *)value;
- (void)removeAlbumsObject:(Album *)value;
- (void)addAlbums:(NSSet *)values;
- (void)removeAlbums:(NSSet *)values;

@end
