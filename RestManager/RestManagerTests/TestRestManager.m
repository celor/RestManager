//
//  TestRestManager.m
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

#import <XCTest/XCTest.h>
#import "RestAFNetworking.h"
#import "CoreDataManager.h"

@interface TestRestManager : XCTestCase
{
    CoreDataManager *_manager;
    RestManager *_restManager;
}

@end

@implementation TestRestManager
static NSString *const artists = @"artists";

- (void)setUp {
    [super setUp];
    // Put setup code here. This method is called before the invocation of each test method in the class.
    _manager = [CoreDataManager new];
    _restManager = [[RestManager alloc] initWithBaseURL:[NSBundle bundleForClass:self.class].resourceURL andNetworkManagedObjectContext:_manager.managedObjectContext];
    
    RestRoute *artistsRoute = [RestRoute localRestRouteWithPattern:nil andBaseEntityName:@"Artist"];
    RestRoute *jsonRoute = [RestRoute localRestRouteWithPattern:artists andBaseEntityName:nil];
    jsonRoute.subroutes = @{@"list":artistsRoute};
    [_restManager addRestRoute:jsonRoute withIdentifier:artists];
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
        
        XCTAssertNil(error,@"An error occured");
        
        XCTAssertEqual(routeIdentifier, artists, @"The route identifier is different");
        
        XCTAssertEqual(routeBaseObjects.count, 2,@"Need have one artists");
        NSPredicate *acdcPredicate = [NSPredicate predicateWithFormat:@"name = %@",@"ACDC"];
        
        id acdc = [[[routeBaseObjects allObjects] filteredArrayUsingPredicate:acdcPredicate] firstObject];
        
        XCTAssertEqual([[acdc valueForKeyPath:@"identifier"] intValue],
                       1,
                       "The first artist id have to be 1");
        
        XCTAssertTrue([[acdc valueForKeyPath:@"name"] isEqualToString:@"ACDC"],
                      "The first artist have to be ACDC");
        
        XCTAssertEqual([[acdc valueForKeyPath:@"albums"] count],
                       3,
                       @"The first artist have 3 album registered");
        
        NSFetchRequest *fetchRequest = [NSFetchRequest fetchRequestWithEntityName:@"Artist"];
        [fetchRequest setPredicate:acdcPredicate];
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
