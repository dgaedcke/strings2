//
//  GeoFence.swift
//  Strings2


import UIKit
import MapKit
import CoreLocation

struct GeoEncodeKey {
	// NSCoding keys for storage in NSUserDefaults
	static let latitude = "latitude"
	static let longitude = "longitude"
	static let radius = "radius"
	static let identifier = "identifier"
	static let note = "note"
	static let eventType = "eventTYpe"
}

enum EventType: String {
	case onEntry = "On Entry"
	case onExit = "On Exit"
}


class ContributorLocation: NSObject, NSCoding, MKAnnotation {
	// show where contributor was for each posting
	var coordinate: CLLocationCoordinate2D
	var identifier: String
	var note: String
	
	var title: String? {
		if note.isEmpty {
			return "Note missing?"
		}
		return note
	}
	
	init(coordinate: CLLocationCoordinate2D, identifier: String, note: String) {
		self.coordinate = coordinate
		self.identifier = identifier
		self.note = note
	}
	
	// MARK: NSCoding
	required init?(coder decoder: NSCoder) {
		let latitude = decoder.decodeDouble(forKey: GeoEncodeKey.latitude)
		let longitude = decoder.decodeDouble(forKey: GeoEncodeKey.longitude)
		coordinate = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
		identifier = decoder.decodeObject(forKey: GeoEncodeKey.identifier) as! String
		note = decoder.decodeObject(forKey: GeoEncodeKey.note) as! String
	}
	
	func encode(with coder: NSCoder) {
		coder.encode(coordinate.latitude, forKey: GeoEncodeKey.latitude)
		coder.encode(coordinate.longitude, forKey: GeoEncodeKey.longitude)
		coder.encode(identifier, forKey: GeoEncodeKey.identifier)
		coder.encode(note, forKey: GeoEncodeKey.note)
	}
}


class GeoFenceLocation: ContributorLocation {
	// defines a fence around a string
	
	var radius: CLLocationDistance
	var eventType: EventType
	
	var subtitle: String? {
		let eventTypeString = eventType.rawValue
//		return "Fence Radius: \(radius)m - \(eventTypeString)"
		return Strings.setFenceRadiusInstructions.localized
	}
	
	init(coordinate: CLLocationCoordinate2D, radius: CLLocationDistance, identifier: String, note: String, eventType: EventType) {
		self.radius = radius
		self.eventType = eventType
		
		super.init(coordinate: coordinate, identifier: identifier, note: note)
	}
	
	// MARK: NSCoding
	required init?(coder decoder: NSCoder) {
		radius = decoder.decodeDouble(forKey: GeoEncodeKey.radius)
		eventType = EventType(rawValue: decoder.decodeObject(forKey: GeoEncodeKey.eventType) as! String)!
		super.init(coder: decoder)
	}
	
	override func encode(with coder: NSCoder) {
		coder.encode(coordinate.latitude, forKey: GeoEncodeKey.latitude)
		coder.encode(coordinate.longitude, forKey: GeoEncodeKey.longitude)
		coder.encode(radius, forKey: GeoEncodeKey.radius)
		coder.encode(identifier, forKey: GeoEncodeKey.identifier)
		coder.encode(note, forKey: GeoEncodeKey.note)
		coder.encode(eventType.rawValue, forKey: GeoEncodeKey.eventType)
	}
	
}

