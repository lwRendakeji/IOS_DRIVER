//
//  GUOLIViewController.h
//  APP_DRIVER
//
//  Created by xiaobin on 15-12-9.
//  Copyright (c) 2015年 renda. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <AssetsLibrary/AssetsLibrary.h>
#import <CoreLocation/CoreLocation.h>
#import <CoreLocation/CLLocationManagerDelegate.h>
#import <MapKit/MapKit.h>
//#import <BaiduMapAPI_Map/BMKMapComponent.h>
//#import <BaiduMapAPI_Location/BMKLocationComponent.h>

@interface GUOLIViewController : UIViewController <NSXMLParserDelegate,NSURLConnectionDataDelegate,
UIImagePickerControllerDelegate,UINavigationControllerDelegate
,CLLocationManagerDelegate,UIScrollViewDelegate,UIWebViewDelegate,UIAlertViewDelegate
//,BMKMapViewDelegate,BMKLocationServiceDelegate
>

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
//旧的经度
@property (strong,nonatomic) NSString *txtLng_old;
//旧的纬度
@property (strong,nonatomic) NSString *txtLat_old;
//高度
@property (strong,nonatomic) NSString *txtAlt;
@property (nonatomic,strong) CLLocationManager *locationManager;

- (void)soap:(NSString *)serviceName methodName:(NSString *)methodName fields:(NSString *)fields;

@end
