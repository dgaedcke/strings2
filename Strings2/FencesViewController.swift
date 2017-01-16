//
//  FencesViewController.swift
//  Strings2
//
//  Created by Dewey Gaedcke on 1/2/17.
//  Copyright © 2017 Dewey Gaedcke. All rights reserved.
//
// Goal of this view is to let the user quickly specify both:
//		Centerpoint of the GeoFence
//		Radius of GeoFence
// for a given String that they created/own
// annotations can be used (later) to show the location of various contributors to the string
// although I'm inclined to factor this code out into a manager-singleton
// locationManager:didUpdateLocations


import UIKit
import MapKit
import CoreLocation
import EasyTipView

private let K_CUR_FENCE_NAME = "CURRENT_FENCE"
private let K_START_RADIUS_WIDTH:CGFloat = 90	// Constants.Map.initialZoom
private let K_ZOOM_PRECISION:CLLocationDegrees = 0.07

fileprivate enum ViewMode {
	case Navigate	// user is dragging pin around the map
	case Search			// user is searching by zip or city-name;  pin will drop in center of found location
	case PinchRadius	// user see's pinch circle & is allowed to drag it around the map
	case Edit			// user has come back to modify settings on an existing fence
}

fileprivate enum AccessoryBtnType:Int {
	// these are the buttons available on the Pin/Annotation
	// would subclass annotation for full implementation
	case SetPinchMode = 0
	case SetDragMode = 1
	case SearchNewLocation = 2
}

class FencesViewController: AppViewController {
	
	@IBOutlet weak var mapView: MKMapView!
	@IBOutlet weak var mapModeControl: UISegmentedControl!
	// specify whether to show street, hybrid or satelight view
	@IBOutlet weak var mapViewDetailControl: UISegmentedControl!
	@IBOutlet weak var gestureOverlayView: UIView!	// overlay view to host the PinchGestureRec
	@IBOutlet weak var pinchableImageView: UIImageView!		// contains the pinchable circle
	@IBOutlet weak var circleWidthConstraint: NSLayoutConstraint!
	
	let locationManager = CLLocationManager()	// allows requesting user location
	var userLocation: CLLocation?		// updated after map inits

	var currentFence:GeoFenceLocation? {
		didSet {
			mapModeControl.setEnabled( currentFence != nil , forSegmentAt: 1)
			if currentFence == nil {
				mapModeControl.selectedSegmentIndex = 0
			}
		}
	}
	
	fileprivate var viewMode:ViewMode = .Navigate {
		didSet {
			switch viewMode {
			case .Navigate:

				mapView.isUserInteractionEnabled = true
				mapView.isRotateEnabled = false
				
				hidePinchableCircle()
				// only let them click radius seg-control after setting the fence-center
				mapModeControl.setEnabled( currentFence != nil, forSegmentAt: 1)
				selectAnnotation()
				
			case .Search:
				break
				
			case .PinchRadius:
				assert( currentFence != nil, "should not have gotten to this mode")
				gestureOverlayView.isHidden = false
				gestureOverlayView.isUserInteractionEnabled = true
				mapView.isUserInteractionEnabled = false
				deselectAnnotation()
				showPinchableCircle()
//				removeAnnotation()
			
			case .Edit:
				break
			}

		}
	}
	
	@IBAction func changeMapMode(_ sender: UISegmentedControl) {
		assert(sender == mapModeControl, "sanity check")
		
		if currentFence == nil {
			// 2nd option on mapModeControl is disabled until currentFence has been set
			assert(false, "should never reach here")
			// you must specify your centerpoint b4 u can pinch radius
			sender.selectedSegmentIndex = 0
			// FIXME:  add user alert or tooltip here!!
			return
		}
		
		switch sender.selectedSegmentIndex {
		case 0:
			viewMode = .Navigate
		case 1:
			viewMode = .PinchRadius
		default:
			break
		}
//		print("changeMapMode \(viewMode.hashValue)")
	}
	
	@IBAction func mapTypeChanged(sender: AnyObject) {
		
		switch mapViewDetailControl.selectedSegmentIndex {
		case 0:
			mapView.mapType = MKMapType.standard
		case 1:
			mapView.mapType = MKMapType.hybrid
		case 2:
			mapView.mapType = MKMapType.satellite
		default:
			break
		}
	}
	
	override func viewDidLoad() {
		super.viewDidLoad()
		
		locationManager.delegate = self
		locationManager.requestAlwaysAuthorization()
		
		mapView.showsUserLocation = false
		mapView.isRotateEnabled = false
	}
	
	override func viewWillAppear(_ animated: Bool) {
		hidePinchableCircle()	// opening mode is .Navigate
	}

	// MARK: Functions that update the model/associated views with fence changes
	func addAnnotation(fence: GeoFenceLocation) {
		mapView.addAnnotation(fence)
	}
	
	func removeAnnotation() {

		if let fence = currentFence {
			mapView.removeAnnotation(fence)
			removeRadiusOverlay(forFence: fence)
		}
	}
	
	// MARK: Map overlay functions
	func addRadiusOverlay(forFence fence: GeoFenceLocation) {
		removeRadiusOverlay(forFence: fence)
		mapView?.add(MKCircle(center: fence.coordinate, radius: fence.radius))
	}
	
	func removeRadiusOverlay(forFence fence: GeoFenceLocation) {
		// Find exactly one overlay which has the same coordinates & radius to remove

		guard let fence = currentFence else { return }
		guard let overlays = mapView?.overlays else { return }
		
		for overlay in overlays {
			guard let circleOverlay = overlay as? MKCircle else { continue }
			let coord = circleOverlay.coordinate
			if coord.latitude == fence.coordinate.latitude && coord.longitude == fence.coordinate.longitude && circleOverlay.radius == fence.radius {
				mapView?.remove(circleOverlay)
				break
			}
		}
	}
	
	func updateRadiusOverlay(radius:Double) {
		// niu

	}
	
	func clearMap() {
		mapView.removeAnnotations(mapView.annotations)
		mapView.removeOverlays(mapView.overlays)
	}
	
	func zoomToSpecifiedLocation(location:CLLocation?) {
		// call this any time you want to reset Fence center & zoom map to that location
		guard let userLocation = location == nil ? self.userLocation : location
		else {
			print("user location never specified")
			return
		}

		let latitude = userLocation.coordinate.latitude
		let longitude = userLocation.coordinate.longitude
		let span:MKCoordinateSpan = MKCoordinateSpanMake(K_ZOOM_PRECISION, K_ZOOM_PRECISION)
		let location: CLLocationCoordinate2D = CLLocationCoordinate2DMake(latitude, longitude)
		let region: MKCoordinateRegion = MKCoordinateRegionMake(location, span)
		mapView.setRegion(region, animated: true)
	}
	
	func setFenceCenterBy(location:CLLocation) {
		let zoomRadius =  CLLocationDistance(K_START_RADIUS_WIDTH)
		currentFence = GeoFenceLocation(coordinate: location.coordinate, radius:zoomRadius, identifier: K_CUR_FENCE_NAME, note: Strings.mapAnnotationTitle.localized, eventType: .onEntry)
		userLocation = location	// update the global
		zoomToSpecifiedLocation(location: location)
		
	}
	
	@IBAction func zoomToCurrentUserLocation(sender: AnyObject) {
		// button not yet hooked up
		// user wants to start over setting center of the fence
		self.userLocation = nil
		self.currentFence = nil
		clearMap()
		locationManager.requestLocation()	// force location.didUpdateLocations to call setFenceCenterBy
	}
	
	func addMoveablePin(fence: GeoFenceLocation) {
		addAnnotation(fence: fence)
		zoomToSpecifiedLocation(location: fence.coordinate.toLoc())
	}
	
	func deselectAnnotation() {
		if let fa = mapView.annotations.first {
			mapView.deselectAnnotation(fa, animated: true)
		}
	}
	
	func selectAnnotation() {
		if let fa = mapView.annotations.first {
			mapView.selectAnnotation(fa, animated: true)
		}
	}
}


// MARK: - Location Manager Delegate
extension FencesViewController: CLLocationManagerDelegate {
	
	func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
		//		print("locationManager callback with \(locations.count) locations")
		
		guard let topLoc = locations.first
		else {
			print("no coords in locationManager update")
			return
		}

		if currentFence == nil || userLocation == nil {
			// 1st location callback after VC loaded
			setFenceCenterBy(location: topLoc)
			addMoveablePin(fence: currentFence!)
			
			mapView.selectAnnotation(mapView.annotations.first!, animated: true)
		}
	}
	
	
	func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
		// user change OS privs for loc data
		assert(manager == locationManager, "sanity check")
		if status != .denied {
			if currentFence == nil {
				locationManager.requestLocation()	// will cause callback to didUpdateLocations below
			}
		}
	}
	
	func locationManager(_ manager: CLLocationManager, monitoringDidFailFor region: CLRegion?, withError error: Error) {
		print("Monitoring failed for region with identifier: \(region!.identifier)")
	}
 
	func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
		print("Location Manager failed with the following error: \(error)")
	}
}


// MARK: - MapView Delegate for showing annotations
extension FencesViewController: MKMapViewDelegate {
	
//	public func mapView(_ mapView: MKMapView, didAdd views: [MKAnnotationView]) {
//		guard let ann = views.first else { return }
//		
//		if let coord = ann.annotation?.coordinate {
//			let loc = coord.toLoc()
//			zoomToSpecifiedLocation(location: loc)
//		}
//	}
	
	func mapView(_ mapView: MKMapView, annotationView view: MKAnnotationView, didChange newState: MKAnnotationViewDragState, fromOldState oldState: MKAnnotationViewDragState) {
		// user just dragged annotation pin to new location
		
		guard newState == .ending, let viewAnn = view.annotation
		else {
//			print("pin annotation was created or moved but not dropped")
			return
		}
		
		// pin was dropped
		zoomToSpecifiedLocation(location: viewAnn.coordinate.toLoc())
		// update the current fence to the new drop location
		currentFence?.coordinate = viewAnn.coordinate
	}
	
	func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
		let identifier = "myFence"	// K_CUR_FENCE_NAME
		if annotation is GeoFenceLocation {
			var annotationView = mapView.dequeueReusableAnnotationView(withIdentifier: identifier) as? MKPinAnnotationView
			if annotationView == nil {
				annotationView = MKPinAnnotationView(annotation: annotation, reuseIdentifier: identifier)
				annotationView?.canShowCallout = true
				annotationView?.isDraggable = true
				
				let finalizePosBtn = UIButton(type: .custom)
				finalizePosBtn.tag = AccessoryBtnType.SetPinchMode.rawValue
				finalizePosBtn.frame = CGRect(x: 0, y: 0, width: 23, height: 23)
				finalizePosBtn.setImage(UIImage(named: "DeleteFence")!, for: .normal)
//				finalizePosBtn.setTitle("Set Position", for: .normal)
				annotationView?.leftCalloutAccessoryView = finalizePosBtn
			} else {
				annotationView?.annotation = annotation
			}
			return annotationView
		}
		return nil
	}
	
	
	func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
		if overlay is MKCircle {
			let circleRenderer = MKCircleRenderer(overlay: overlay)
			circleRenderer.lineWidth = 1.0
			circleRenderer.strokeColor = .purple
			circleRenderer.fillColor = UIColor.purple.withAlphaComponent(0.4)
			return circleRenderer
		}
		return MKOverlayRenderer(overlay: overlay)
	}
	
	func mapView(_ mapView: MKMapView, annotationView view: MKAnnotationView, calloutAccessoryControlTapped control: UIControl) {
		// user has tapped a btn on the annotation accessory view
		
		switch control.tag {
		case AccessoryBtnType.SetPinchMode.rawValue:
			mapModeControl.selectedSegmentIndex = 1
			self.viewMode = .PinchRadius
			
			
		case AccessoryBtnType.SearchNewLocation.rawValue:
			// Delete fence & let user search for new pin location
			removeAnnotation()	// fence: fence
		default:
			break
		}
//		mapView.deselectAnnotation(view.annotation, animated: true)
	}
}

// MARK: - methods to support pinchable radius control
extension FencesViewController {
	
	@objc
	func pinchCallback(_ recognizer : UIPinchGestureRecognizer) {
		
//		pinchableImageView.transform = pinchableImageView.transform.scaledBy(x: recognizer.scale, y: recognizer.scale)
		
		// scaling this contraint will scale pinchableImageView
		circleWidthConstraint.constant = recognizer.scale * pinchableImageView.bounds.width
		gestureOverlayView.setNeedsLayout()
		gestureOverlayView.layoutIfNeeded()
		
//		print("circleWidthConstraint.constant: \(circleWidthConstraint.constant )")
		recognizer.scale = 1
		
//		print("pinch callback in state \(recognizer.state.rawValue)")
		if recognizer.state == .ended {
//			let width = pinchableImageView.bounds.width
//			print("pinchableImageView width = \(width)")
			let cirRegion = mapView.convert(pinchableImageView.frame, toRegionFrom: self.gestureOverlayView)
			let centerLoc = cirRegion.center
			let span = cirRegion.span
			
			let leftEdgeCenter = CLLocation(latitude: centerLoc.latitude - span.latitudeDelta * 0.5, longitude: centerLoc.longitude)
			let rightEdgeCenter = CLLocation(latitude: centerLoc.latitude + span.latitudeDelta * 0.5, longitude: centerLoc.longitude)
			let halfRegionDistMeters:CLLocationDistance = leftEdgeCenter.distance(from: rightEdgeCenter) / 2
			
//			print("halfRegionDistMeters: \(halfRegionDistMeters)")
			currentFence?.radius = halfRegionDistMeters
			
			showTooltipNow(forView: pinchableImageView, withinSuperView:gestureOverlayView, msg:Strings.tapToSetRadius.localized)
		}
	}
	
	func tapCallback(_ recognizer : UITapGestureRecognizer) {
		// user tapped on the radius zoom circle so fence area established
		setFenceRadius()
	}
	
	override func easyTipViewDidDismiss(_ tipView : EasyTipView) {
//		setFenceRadius()
	}
	
	func setFenceRadius() {
		hidePinchableCircle()
		mapView.removeOverlays(mapView.overlays)
		addRadiusOverlay(forFence: currentFence!)
		self.viewMode = .Navigate
		self.mapModeControl.selectedSegmentIndex = 0
	}
	
	func showPinchableCircle() {
		
		// fenceCenter / currentFence should always be positioned in center of the map
		// show circle in middle
		
		addRecognizeToGestureView()
		gestureOverlayView.isHidden = false
		gestureOverlayView.gestureRecognizers?.first?.isEnabled = true
	}
	
	func hidePinchableCircle() {
		gestureOverlayView.isHidden = true
		gestureOverlayView.isUserInteractionEnabled = false
	}
	
	func addRecognizeToGestureView() {
//		print("trying addRecognizeToGestureView")
		guard gestureOverlayView.gestureRecognizers?.count == nil
		else {	// don't add them twice
			return
		}
		
//		print("adding 2 gesture recognizers to \(self.view) & \(gestureOverlayView)")
//		let sel = #selector(pinchCallback(_:) )
//		print("sel: \(sel)")
		let grPinch = UIPinchGestureRecognizer(target: self, action: #selector(pinchCallback(_:) ) )
		view.addGestureRecognizer(grPinch)
		let grTap = UITapGestureRecognizer(target: self, action: #selector(self.tapCallback(_:)))
		view.addGestureRecognizer(grTap)
	}
	
//	func addCircleToView(circView:UIView) {
//		
//		let circWidth = circView.layer.bounds.width
//		circView.backgroundColor = UIColor.init(white: 1.0, alpha: 0.6)
//		
//		let circlePath = UIBezierPath(arcCenter: CGPoint(x: circWidth/2,y: circWidth/2), radius: circWidth, startAngle: CGFloat(0), endAngle:CGFloat(M_PI * 2), clockwise: true)
//		
//		let shapeLayer = CAShapeLayer()
//		shapeLayer.path = circlePath.cgPath
//		
//		shapeLayer.fillColor = UIColor.clear.cgColor
//		shapeLayer.strokeColor = UIColor.red.cgColor
//		shapeLayer.lineWidth = 3.0
//		//		circView.alpha = 0.4
//		
//		circView.layer.addSublayer(shapeLayer)
//	}
}
