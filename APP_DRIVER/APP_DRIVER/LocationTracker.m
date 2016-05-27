//
//  LocationTracker.m
//  Location
//
//  Created by Rick
//  Copyright (c) 2014 Location All rights reserved.
//

#import "LocationTracker.h"
#import "StaticRef.h"
#import "User.h"
#import "RendaKeychain.h"
#import "Util.h"

#define LATITUDE @"latitude"
#define LONGITUDE @"longitude"
#define ACCURACY @"theAccuracy"

#define IS_OS_8_OR_LATER ([[[UIDevice currentDevice] systemVersion] floatValue] >= 8.0)


@interface LocationTracker ()

@property (strong,nonatomic) NSDictionary *logInfo;
@property (weak,nonatomic) NSString *webservice_id;
@property (strong,nonatomic) NSString *webservice_port;
@property (strong,nonatomic) NSString *webservice_name;
@property (strong,nonatomic) NSString *webservice_subname;

@end

@implementation LocationTracker


@synthesize webData;
@synthesize soapResults;
@synthesize xmlParser;
@synthesize elementFound;
@synthesize matchingElement;
@synthesize conn;
@synthesize txtLat;
@synthesize txtLng;
@synthesize LWlocation;




+ (CLLocationManager *)sharedLocationManager {
	static CLLocationManager *_locationManager;
	
	@synchronized(self) {
		if (_locationManager == nil) {
			_locationManager = [[CLLocationManager alloc] init];
            _locationManager.desiredAccuracy = kCLLocationAccuracyBestForNavigation;
			_locationManager.allowsBackgroundLocationUpdates = YES;
			_locationManager.pausesLocationUpdatesAutomatically = NO;
		}
	}
	return _locationManager;
}

- (id)init {
	if (self==[super init]) {
        //Get the share model and also initialize myLocationArray
        self.shareModel = [LocationShareModel sharedModel];
        self.shareModel.myLocationArray = [[NSMutableArray alloc]init];
        
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(applicationEnterBackground) name:UIApplicationDidEnterBackgroundNotification object:nil];
	}
	return self;
}

-(void)applicationEnterBackground{
    CLLocationManager *locationManager = [LocationTracker sharedLocationManager];
    locationManager.delegate = self;
    locationManager.desiredAccuracy = kCLLocationAccuracyBestForNavigation;
    locationManager.distanceFilter = kCLDistanceFilterNone;
    
    if(IS_OS_8_OR_LATER) {
        [locationManager requestAlwaysAuthorization];
    }
    [locationManager startUpdatingLocation];
    
    //Use the BackgroundTaskManager to manage all the background Task
    self.shareModel.bgTask = [BackgroundTaskManager sharedBackgroundTaskManager];
    [self.shareModel.bgTask beginNewBackgroundTask];
}

- (void) restartLocationUpdates
{
    //NSLog(@"restartLocationUpdates");
    
    if (self.shareModel.timer) {
        [self.shareModel.timer invalidate];
        self.shareModel.timer = nil;
    }
    
    CLLocationManager *locationManager = [LocationTracker sharedLocationManager];
    locationManager.delegate = self;
    locationManager.desiredAccuracy = kCLLocationAccuracyBestForNavigation;
    locationManager.distanceFilter = kCLDistanceFilterNone;
    
    if(IS_OS_8_OR_LATER) {
        [locationManager requestAlwaysAuthorization];
    }
    [locationManager startUpdatingLocation];
}


- (void)startLocationTracking {
    //NSLog(@"startLocationTracking");

	if ([CLLocationManager locationServicesEnabled] == NO) {
        //NSLog(@"locationServicesEnabled false");
		UIAlertView *servicesDisabledAlert = [[UIAlertView alloc] initWithTitle:@"Location Services Disabled" message:@"You currently have all location services for this device disabled" delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
		[servicesDisabledAlert show];
	} else {
        CLAuthorizationStatus authorizationStatus= [CLLocationManager authorizationStatus];
        
        if(authorizationStatus == kCLAuthorizationStatusDenied || authorizationStatus == kCLAuthorizationStatusRestricted){
            //NSLog(@"authorizationStatus failed");
        } else {
            //NSLog(@"authorizationStatus authorized");
            CLLocationManager *locationManager = [LocationTracker sharedLocationManager];
            locationManager.delegate = self;
            locationManager.desiredAccuracy = kCLLocationAccuracyBestForNavigation;
            locationManager.distanceFilter = kCLDistanceFilterNone;
            
            if(IS_OS_8_OR_LATER) {
              [locationManager requestAlwaysAuthorization];
            }
            [locationManager startUpdatingLocation];
        }
	}
}


- (void)stopLocationTracking {
    //NSLog(@"stopLocationTracking");
    
    if (self.shareModel.timer) {
        [self.shareModel.timer invalidate];
        self.shareModel.timer = nil;
    }
    
	CLLocationManager *locationManager = [LocationTracker sharedLocationManager];
	[locationManager stopUpdatingLocation];
}

#pragma mark - CLLocationManagerDelegate Methods

-(void)locationManager:(CLLocationManager *)manager didUpdateLocations:(NSArray *)locations{
    
   // NSLog(@"locationManager didUpdateLocations");
   
    LWlocation=[locations lastObject];//LW
    
    
    for(int i=0;i<locations.count;i++){
        CLLocation * newLocation = [locations objectAtIndex:i];
        CLLocationCoordinate2D theLocation = newLocation.coordinate;
        CLLocationAccuracy theAccuracy = newLocation.horizontalAccuracy;
        
        NSTimeInterval locationAge = -[newLocation.timestamp timeIntervalSinceNow];
        
        if (locationAge > 30.0)
        {
            continue;
        }
        
        //Select only valid location and also location with good accuracy
        if(newLocation!=nil&&theAccuracy>0
           &&theAccuracy<2000
           &&(!(theLocation.latitude==0.0&&theLocation.longitude==0.0))){
            
            self.myLastLocation = theLocation;
            self.myLastLocationAccuracy= theAccuracy;
            
            NSMutableDictionary * dict = [[NSMutableDictionary alloc]init];
            [dict setObject:[NSNumber numberWithFloat:theLocation.latitude] forKey:@"latitude"];
            [dict setObject:[NSNumber numberWithFloat:theLocation.longitude] forKey:@"longitude"];
            [dict setObject:[NSNumber numberWithFloat:theAccuracy] forKey:@"theAccuracy"];
            
            //Add the vallid location with good accuracy into an array
            //Every 1 minute, I will select the best location based on accuracy and send to server
            [self.shareModel.myLocationArray addObject:dict];
        }
    }
    
    //If the timer still valid, return it (Will not run the code below)
    if (self.shareModel.timer) {
        return;
    }
    
    self.shareModel.bgTask = [BackgroundTaskManager sharedBackgroundTaskManager];
    [self.shareModel.bgTask beginNewBackgroundTask];
    
    //Restart the locationMaanger after 1 minute
    self.shareModel.timer = [NSTimer scheduledTimerWithTimeInterval:60 target:self
                                                           selector:@selector(restartLocationUpdates)
                                                           userInfo:nil
                                                            repeats:NO];
    
    //Will only stop the locationManager after 10 seconds, so that we can get some accurate locations
    //The location manager will only operate for 10 seconds to save battery
    if (self.shareModel.delay10Seconds) {
        [self.shareModel.delay10Seconds invalidate];
        self.shareModel.delay10Seconds = nil;
    }
    
    self.shareModel.delay10Seconds = [NSTimer scheduledTimerWithTimeInterval:10 target:self
                                                    selector:@selector(stopLocationDelayBy10Seconds)
                                                    userInfo:nil
                                                     repeats:NO];

}


//Stop the locationManager
-(void)stopLocationDelayBy10Seconds{
    CLLocationManager *locationManager = [LocationTracker sharedLocationManager];
    [locationManager stopUpdatingLocation];
    
   // NSLog(@"locationManager stop Updating after 10 seconds");
}


- (void)locationManager: (CLLocationManager *)manager didFailWithError: (NSError *)error
{
   // NSLog(@"locationManager error:%@",error);
    
    switch([error code])
    {
        case kCLErrorNetwork: // general, network-related error
        {
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Network Error" message:@"Please check your network connection." delegate:self cancelButtonTitle:@"Ok" otherButtonTitles:nil, nil];
            [alert show];
        }
            break;
        case kCLErrorDenied:{
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Enable Location Service" message:@"You have to enable the Location Service to use this App. To enable, please go to Settings->Privacy->Location Services" delegate:self cancelButtonTitle:@"Ok" otherButtonTitles:nil, nil];
            [alert show];
        }
            break;
        default:
        {
            
        }
            break;
    }
}


//Send the location to Server
- (void)updateLocationToServer {
    
    NSMutableDictionary * myBestLocation = [[NSMutableDictionary alloc]init];
    
    for(int i=0;i<self.shareModel.myLocationArray.count;i++){
        NSMutableDictionary * currentLocation = [self.shareModel.myLocationArray objectAtIndex:i];
        
        if(i==0)
            myBestLocation = currentLocation;
        else{
            if([[currentLocation objectForKey:ACCURACY]floatValue]<=[[myBestLocation objectForKey:ACCURACY]floatValue]){
                myBestLocation = currentLocation;
            }
        }
    }
    
    if(self.shareModel.myLocationArray.count==0)
    {
        self.myLocation=self.myLastLocation;
        self.myLocationAccuracy=self.myLastLocationAccuracy;
    }else{
        CLLocationCoordinate2D theBestLocation;
        theBestLocation.latitude =[[myBestLocation objectForKey:LATITUDE]floatValue];
        theBestLocation.longitude =[[myBestLocation objectForKey:LONGITUDE]floatValue];
        self.myLocation=theBestLocation;
        self.myLocationAccuracy =[[myBestLocation objectForKey:ACCURACY]floatValue];
    }
    //TODO: 在这里插入你向服务器发送请求的代码
        self.webservice_id = [WEBSERVICE_ID substringFromIndex:0];
        self.webservice_name = [WEBSERVICE_NAME substringFromIndex:0];
        self.webservice_port = [WEBSERVICE_PORT substringFromIndex:0];
        self.webservice_subname = [WEBSERVICE_SUBNAME substringFromIndex:0];

        RendaKeychain *keyChain = [[RendaKeychain alloc] init];//获取用户 APP_ID
        NSMutableDictionary *dictionary = [[NSMutableDictionary alloc] init];//数组 用于封装 soap的值
        txtLat=[myBestLocation objectForKey:LATITUDE];
        txtLng=[myBestLocation objectForKey:LONGITUDE];
        CLGeocoder *geocoder = [[CLGeocoder alloc] init]; //根据经纬度反向地理编译出地址信息 获取当前所在城市名
        __block CLPlacemark *placemark = nil;
        [geocoder reverseGeocodeLocation:LWlocation completionHandler:^(NSArray *array,NSError *error) {
            if(array.count > 0){
                placemark = [array objectAtIndex:0];
                [dictionary setObject:placemark.name forKey:@"ADDRESS"];
                [dictionary setObject:placemark.locality forKey:@"CITY"];
                [dictionary setObject:[keyChain load:keyChain.KEY_USERNAME] forKey:@"APP_ID"];
                [dictionary setObject:txtLat forKey:@"LAT"];
                [dictionary setObject:txtLng forKey:@"LNG"];
                
                //上传数据
                [self soap:@"LogService" methodName:@"baiduMapLog" fields:[Util transDictionaryToSoapMessage:dictionary]];
               
                }
            }];
    //当你向服务器发送位置信息成功后，要清空当前的数组，以便下一回合的定位
    [self.shareModel.myLocationArray removeAllObjects];
    self.shareModel.myLocationArray = nil;
    self.shareModel.myLocationArray = [[NSMutableArray alloc]init];
}


- (void)soap:(NSString *)serviceName methodName:(NSString *)methodName fields:(NSString *)fields {
    //创建SOAP消息，内容格式就是网站上提供的请求报文的实体主体部分
    if(conn){
        //[conn ]
    }
    matchingElement = methodName;
    NSString *soapMsg = [NSString stringWithFormat:@"<?xml version=\"1.0\" encoding=\"utf-8\"?>"
                         "<soap:Envelope "
                         "xmlns:xsi=\"http://www.w3.org/2001/XMLSchema-instance\" "
                         "xmlns:xsd=\"http://www.w3.org/2001/XMLSchema\" "
                         "xmlns:soap=\"http://www.w3.org/2003/05/soap-envelope\" "
                         ">"
                         "<soap:Body>"
                         "<%@ xmlns=\"http://rd\">"
                         "%@"
                         "</%@>"
                         "</soap:Body>"
                         "</soap:Envelope>",methodName,fields,methodName];
    //创建URL，内容是前面的请求报文中第二行主机地址加上第一行URL字段
    NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"http://%@:%@/%@/%@/%@"
                                       ,self.webservice_id
                                       ,self.webservice_port
                                       ,self.webservice_name
                                       ,self.webservice_subname
                                       ,serviceName]];
    //    NSLog(@"创建请求");
    //根据上面的URL创建一个请求
    NSMutableURLRequest *req = [NSMutableURLRequest requestWithURL:url];
    NSString *msgLength = [NSString stringWithFormat:@"%lu",(unsigned long)[soapMsg length]];
    //添加请求的详细信息，与请求报文前半部分的各字段对应
    [req addValue:@"application/soap+xml;charset=utf-8" forHTTPHeaderField:@"Content-Type"];
    [req addValue:msgLength forHTTPHeaderField:@"Content-Length"];
    //设置请求行方法为POST，与请求报文第一行对应
    [req setHTTPMethod:@"POST"];
    //将SOAP消息加到请求中
    [req setHTTPBody:[soapMsg dataUsingEncoding:NSUTF8StringEncoding]];
    [req setTimeoutInterval:30.0];
    
    [req addValue:methodName forHTTPHeaderField:@"SOAPAction"];
    //创建连接
    conn = [[NSURLConnection alloc] initWithRequest:req delegate:self];
    if(conn){
        webData = [NSMutableData data];
    }
}

//刚开始接受响应时调用
-(void) connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *) response{
    //    NSLog(@"刚开始接受响应");
    [webData setLength:0];
}

//每接受到一部分数据就追加到webData中
-(void) connection:(NSURLConnection *)connection didReceiveData:(NSData *) data{
    //    NSLog(@"追加数据");
    [webData appendData:data];
}

//出现错误时
-(void) connection:(NSURLConnection *) connection didFailWithError:(NSError *)error{
    conn = nil;
    webData = nil;
    //    NSLog(@"connection - error:%@",error);
    NSString *result = @"";
    switch ([error code]) {
        case -1004://Could not connect to the server;
            result = @"连接应用服务器失败,请稍后重试";
            break;
        case -1001://The request timed out;
            result = @"服务器未响应";
            break;
        default:
            result = @"操作失败,请稍后重试";
            break;
    }
    
}

//解析整个文件结束后
-(void)parserDidEndDocument:(NSXMLParser *)parser{
}

//出错时，例如强制结束解析
-(void) parser:(NSXMLParser *)parser parseErrorOccurred:(NSError *)parseError{
    if(soapResults){
        soapResults = nil;
    }
}





@end
