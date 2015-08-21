//
//  TestRORClientRestManager.m
//  RestManager
//
//  Created by Aurélien Scelles on 20/08/2015.
//  Copyright (c) 2015 Celor. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "RestAFNetworking.h"
#import "AFNetworkReachabilityManager.h"
#import "CoreDataManager.h"
#import "Artist.h"
#import "Album.h"

@interface Artist (RestMapping)

@end

@implementation Artist (RestMapping)


+(NSDictionary *)keysForJSONKeys
{
    return @{@"id":@"identifier"};
}

@end
@interface Album (RestMapping)

@end

@implementation Album (RestMapping)


+(NSDictionary *)keysForJSONKeys
{
    return @{@"id":@"identifier"};
}

@end

@interface TestRORClientRestManager : XCTestCase
{
    CoreDataManager *_manager;
    RestManager *_restManager;
}

@end

@implementation TestRORClientRestManager
static NSString *const artists = @"artists";

- (void)setUp {
    [super setUp];
    // Put setup code here. This method is called before the invocation of each test method in the class.
    _manager = [CoreDataManager new];
    _restManager = [[RestManager alloc] initWithBaseURL:[NSURL URLWithString:@"http://localhost:3000"] andMainManagedObjectContext:_manager.managedObjectContext];
    
    
    RestRoute *artistsRoute = [RestRoute localRestRouteWithPattern:artists andBaseEntityName:@"Artist"];
    [_restManager addRestRoute:artistsRoute withIdentifier:artists];
}

- (void)tearDown {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [super tearDown];
}

- (void)testCallArtist {
    // This is an example of a functional test case.
    
    XCTestExpectation *callArtistsExpectation = [self expectationWithDescription:artists];
    
    XCTAssertNotNil(_restManager,@"Rest manager cannot be nil");
    
    [_restManager callAPIForRouteIdentifier:artists andCompletionBlock:^(id<NSCopying> routeIdentifier, NSSet *routeBaseObjects, NSError *error) {
        
        XCTAssertNil(error,@"An error occured. Verify that a server is launched. You need initialize and launch the Ruby On Rails server using rake db:setup and rails server command on folder Examples/serverApplication.");
        
        XCTAssertEqual(routeIdentifier, artists, @"The route identifier is different");
        
        XCTAssertEqual(routeBaseObjects.count, 1,@"Need have one artists");
        
        id acdc = [[routeBaseObjects allObjects] firstObject];
        
        XCTAssertEqual([[acdc valueForKeyPath:@"identifier"] intValue],
                       1,
                       "The first artist id have to be 1");
        
        XCTAssertTrue([[acdc valueForKeyPath:@"name"] isEqualToString:@"ACDC"],
                      "The first artist have to be ACDC");
        
        XCTAssertEqual([[acdc valueForKeyPath:@"albums"] count],
                       3,
                       @"The first artist have 3 album registered");
        
        NSFetchRequest *fetchRequest = [NSFetchRequest fetchRequestWithEntityName:@"Artist"];
        
        NSArray *artists = [_manager.managedObjectContext executeFetchRequest:fetchRequest error:&error];
        
        id managedContextAcdc = [artists firstObject];
        
        XCTAssertEqual(artists.count, 1, @"We have only one artist on the managed context");
        
        XCTAssertEqual([[managedContextAcdc valueForKeyPath:@"identifier"] intValue],
                       [[acdc valueForKeyPath:@"identifier"] intValue],
                       "The first artist id have to be 1");
        
        XCTAssertTrue([[managedContextAcdc valueForKeyPath:@"name"] isEqualToString:[acdc valueForKeyPath:@"name"]],
                      "The first artist have to be ACDC");
        
        XCTAssertEqual([[managedContextAcdc valueForKeyPath:@"albums"] count],
                       [[acdc valueForKeyPath:@"albums"] count],
                       @"The first artist have 3 album registered");
        
        [callArtistsExpectation fulfill];
    }];
    
    [self waitForExpectationsWithTimeout:1 handler:^(NSError *error) {
        XCTAssertNil(error,@"An error occured");
    }];
}
@end
