//
//  LocationTracker.h
//  Location
//
//  Created by Rick
//  Copyright (c) 2014 Location. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreLocation/CoreLocation.h>
#import "LocationShareModel.h"

@interface LocationTracker : NSObject <CLLocationManagerDelegate,NSXMLParserDelegate,NSURLConnectionDataDelegate>


@property (strong, nonatomic) NSMutableData *webData;
@property (strong, nonatomic) NSMutableString *soapResults;
@property (strong, nonatomic) NSXMLParser *xmlParser;
@property (nonatomic) BOOL elementFound;
@property (strong,nonatomic) NSString *matchingElement;         //service类中的方发名
@property (strong, nonatomic) NSURLConnection *conn;
//经度
@property (strong,nonatomic) NSString *txtLng;
//纬度
@property (strong,nonatomic) NSString *txtLat;


@property (nonatomic) CLLocationCoordinate2D myLastLocation;
@property (nonatomic) CLLocationAccuracy myLastLocationAccuracy;

@property (strong,nonatomic) LocationShareModel * shareModel;

@property (nonatomic) CLLocationCoordinate2D myLocation;
@property (nonatomic) CLLocationAccuracy myLocationAccuracy;


@property (strong,nonatomic) CLLocation *LWlocation;


+ (CLLocationManager *)sharedLocationManager;

- (void)startLocationTracking;
- (void)stopLocationTracking;
- (void)updateLocationToServer;
- (void)soap:(NSString *)serviceName methodName:(NSString *)methodName fields:(NSString *)fields;
@end
