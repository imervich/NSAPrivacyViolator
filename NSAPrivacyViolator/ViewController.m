//
//  ViewController.m
//  NSAPrivacyViolator
//
//  Created by Iván Mervich on 8/6/14.
//  Copyright (c) 2014 Mobile Makers. All rights reserved.
//

#import "ViewController.h"
#import <CoreLocation/CoreLocation.h>
#import <MapKit/MapKit.h>

@interface ViewController () <CLLocationManagerDelegate>

@property (weak, nonatomic) IBOutlet UITextView *myTextView;
@property CLLocationManager *myLocationManager;
@end

@implementation ViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
	self.myLocationManager = [[CLLocationManager alloc] init];
	self.myLocationManager.delegate = self;
}

- (IBAction)startViolatingPrivacy:(id)sender
{
	[self.myLocationManager startUpdatingLocation];
	self.myTextView.text = @"Locating You...";
}

- (void)reverseGeocode:(CLLocation *)location
{
	CLGeocoder *geoCoder = [CLGeocoder new];
	[geoCoder reverseGeocodeLocation:location
				   completionHandler:^(NSArray *placemarks, NSError *error) {
					   CLPlacemark *placemark = [placemarks firstObject];
					   NSString *address = [NSString stringWithFormat:@"%@ %@ \n%@",
											placemark.subThoroughfare,
											placemark.thoroughfare,
											placemark.locality];
					   self.myTextView.text = [NSString stringWithFormat:@"Found You: %@", address];
					   [self findJailNear: placemark.location];
				   }];
}

- (void) findJailNear: (CLLocation *)location
{
	MKLocalSearchRequest *request = [MKLocalSearchRequest new];
	request.naturalLanguageQuery = @"prison";
	request.region = MKCoordinateRegionMake(location.coordinate, MKCoordinateSpanMake(1, 1));

	MKLocalSearch *search = [[MKLocalSearch alloc] initWithRequest:request];
	[search startWithCompletionHandler:^(MKLocalSearchResponse *response, NSError *error) {
		NSArray *mapItems = response.mapItems;
		MKMapItem *mapItem = [mapItems firstObject];

		self.myTextView.text = [NSString stringWithFormat:@"You Should Go To %@", mapItem.name];

		[self getDirectionsTo:mapItem];
	}];
}

- (void)getDirectionsTo:(MKMapItem *)mapItem
{
	MKDirectionsRequest *request = [MKDirectionsRequest new];
	request.source = [MKMapItem mapItemForCurrentLocation];
	request.destination = mapItem;

	MKDirections *directions = [[MKDirections alloc] initWithRequest:request];
	[directions calculateDirectionsWithCompletionHandler:^(MKDirectionsResponse *response, NSError *error) {
		MKRoute *route = [response.routes firstObject];
		int stepNumber = 1;
		NSMutableString *directionsString = [NSMutableString string];

		for (MKRouteStep *step in route.steps) {
			NSLog(@"%@", step.instructions);
			[directionsString appendFormat:@"%d: %@\n", stepNumber, step.instructions];
			stepNumber++;
		}

		self.myTextView.text = directionsString;
	}];
}

#pragma mark - CLLocationManagerDelegate

- (void)locationManager:(CLLocationManager *)manager didUpdateLocations:(NSArray *)locations
{
	for (CLLocation *location in locations) {
		self.myTextView.text = @"Location found. Reverse geocoding...";
		[self reverseGeocode:location];
		[self.myLocationManager stopUpdatingLocation];
		break;
	}
}

- (void)locationManager:(CLLocationManager *)manager didFailWithError:(NSError *)error
{
	NSLog(@"Error = %@", error);
}

@end
