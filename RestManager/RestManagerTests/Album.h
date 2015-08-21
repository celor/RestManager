//
//  Album.h
//  RestManager
//
//  Created by Aurélien Scelles on 20/08/2015.
//  Copyright (c) 2015 Celor. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class Artist, Track;

@interface Album : NSManagedObject

@property (nonatomic, retain) NSNumber * identifier;
@property (nonatomic, retain) NSString * name;
@property (nonatomic, retain) NSDate * releaseDate;
@property (nonatomic, retain) NSSet *artists;
@property (nonatomic, retain) NSSet *tracks;
@end

@interface Album (CoreDataGeneratedAccessors)

- (void)addArtistsObject:(Artist *)value;
- (void)removeArtistsObject:(Artist *)value;
- (void)addArtists:(NSSet *)values;
- (void)removeArtists:(NSSet *)values;

- (void)addTracksObject:(Track *)value;
- (void)removeTracksObject:(Track *)value;
- (void)addTracks:(NSSet *)values;
- (void)removeTracks:(NSSet *)values;

@end
