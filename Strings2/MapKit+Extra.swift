//
//  MapKit+Extra.swift
//  Strings2
//

import MapKit

extension MKMapView {
	func zoomToUserLocation(zoom:Double = Constants.Map.initialZoom) {
		guard let coordinate = userLocation.location?.coordinate
		else {
			print("map has no user location")
			return
		}
		
		let region = MKCoordinateRegionMakeWithDistance(coordinate, zoom, zoom)
		setRegion(region, animated: true)
		self.showsUserLocation = true
	}
	
	var knowsUserLocation: Bool {
		return userLocation.location?.coordinate != nil
	}
}

extension CLLocationCoordinate2D {
	
	func toLoc() -> CLLocation {
		let l = CLLocation(latitude: self.latitude, longitude: self.longitude)
		return l
	}
}
