//
//  GeoRegionsOnMapViewController.swift
//  GeofencingApp
//
//  Created by vinmac on 23/09/19.
//  Copyright © 2019 vinmac. All rights reserved.
//

import UIKit
import MapKit
import CoreLocation


class GeoRegionsOnMapViewController: UIViewController {
    
    // MARK: PRivate IBOutlets
    @IBOutlet weak private var mapView: MKMapView!
    @IBOutlet weak private var segmentedControlBar: UISegmentedControl!
    @IBOutlet weak private var lblRegionsCount: UILabel!
    
    // MARK: Actions methods
    @IBAction private func btnAddRegionTapped(_ sender: UIButton) {
        if let vc = self.storyboard?.instantiateViewController(withIdentifier: "AddGeoRegionViewController") as? AddGeoRegionViewController {
            vc.delegate = self
            self.present(vc, animated: true, completion: nil)
        }
    }

    @objc private func segmentedBarValueChanged(sender: UISegmentedControl) {
        self.updateOnMap()
    }
    
    @IBAction private func zoomToCurrentLocation(sender: AnyObject) {
        self.mapView.zoomToUserLocation()
    }
    
    // MARK: Class properties
    var allGeoRegions: [GeoRegion] = []
    var entryGeoRegions: [GeoRegion] = []
    var exitGeoRegions: [GeoRegion] = []
    let locationManager = CLLocationManager()
    
    // MARK: View controller life cycle methods
    override func viewDidLoad() {
        super.viewDidLoad()
        self.segmentedControlBar.addTarget(self, action: #selector(self.segmentedBarValueChanged), for: .valueChanged)
        self.locationManager.delegate = self
        self.locationManager.requestAlwaysAuthorization()
        self.loadAllGeoRegions()
        self.filterGeoRegionsBasedOnEventType()
        self.updateOnMap()
        self.mapView.showsUserLocation = true
        self.mapView.zoomToUserLocation()
    }
    
    // MARK: Loading and saving functions
    private func loadAllGeoRegions() {
        self.allGeoRegions.removeAll()
        self.allGeoRegions = GeoRegion.allGeoRegions()
    }
    
    private func filterGeoRegionsBasedOnEventType() {
        for geoRegion in self.allGeoRegions {
            if geoRegion.eventType == .onEntry {
                self.entryGeoRegions.append(geoRegion)
            } else {
                self.exitGeoRegions.append(geoRegion)
            }
        }
    }
    
    private func saveAllGeoRegions() {
        let encoder = JSONEncoder()
        do {
            let data = try encoder.encode(self.allGeoRegions)
            UserDefaults.standard.set(data, forKey: Utilities.savedItems)
        } catch {
            print("error encoding GeoRegions")
        }
    }
    
    private func updateOnMap() {
        switch self.segmentedControlBar.selectedSegmentIndex {
        case 0:
            self.allGeoRegions.forEach({addOnMap(geoRegion: $0)})
            self.lblRegionsCount.text = "Regions(\(self.allGeoRegions.count))"
        case 1:
            self.entryGeoRegions.forEach({addOnMap(geoRegion: $0)})
            self.exitGeoRegions.forEach({removeFromMap(geoRegion: $0)})
            self.lblRegionsCount.text = "Regions(\(self.entryGeoRegions.count))"
        case 2:
            self.exitGeoRegions.forEach({addOnMap(geoRegion: $0)})
            self.entryGeoRegions.forEach({removeFromMap(geoRegion: $0)})
            self.lblRegionsCount.text = "Regions(\(self.exitGeoRegions.count))"
        default:
            break
        }
    }
    
    private func addToGeoRegionArrayBasedOnEventType(geoRegion: GeoRegion) {
        self.allGeoRegions.append(geoRegion)
        if geoRegion.eventType == .onEntry {
            self.entryGeoRegions.append(geoRegion)
        } else {
            self.exitGeoRegions.append(geoRegion)
        }
        self.addToMapBasedOnEventType(geoRegion: geoRegion)
    }
    
    private func addToMapBasedOnEventType(geoRegion: GeoRegion) {
        switch self.segmentedControlBar.selectedSegmentIndex {
        case 0:
            self.addOnMap(geoRegion: geoRegion)
            self.lblRegionsCount.text = "Regions(\(self.allGeoRegions.count))"
        case 1:
            if geoRegion.eventType == .onEntry {
                self.addOnMap(geoRegion: geoRegion)
                self.lblRegionsCount.text = "Regions(\(self.entryGeoRegions.count))"
            }
        case 2:
            if geoRegion.eventType == .onExit {
                self.addOnMap(geoRegion: geoRegion)
                self.lblRegionsCount.text = "Regions(\(self.exitGeoRegions.count))"
            }
        default:
            break
        }
    }
    
    private func addOnMap(geoRegion: GeoRegion) {
        self.mapView.addAnnotation(geoRegion)
        addRadiusOverlay(forGeoRegion: geoRegion)
    }
    
    private func removeFromGeoRegionArrayBasedOnEventType(geoRegion: GeoRegion) {
        guard let index = allGeoRegions.firstIndex(of: geoRegion) else { return }
        self.allGeoRegions.remove(at: index)
        if geoRegion.eventType == .onEntry {
            guard let i = entryGeoRegions.firstIndex(of: geoRegion) else { return }
            self.entryGeoRegions.remove(at: i)
        } else {
            guard let i = exitGeoRegions.firstIndex(of: geoRegion) else { return }
            self.exitGeoRegions.remove(at: i)
        }
        
        self.removeFromMapBasedOnEventType(geoRegion: geoRegion)
    }
    
    private func removeFromMapBasedOnEventType(geoRegion: GeoRegion) {
        switch self.segmentedControlBar.selectedSegmentIndex {
        case 0:
            removeFromMap(geoRegion: geoRegion)
            self.lblRegionsCount.text = "Regions(\(self.allGeoRegions.count))"
        case 1:
            if geoRegion.eventType == .onEntry {
                removeFromMap(geoRegion: geoRegion)
                self.lblRegionsCount.text = "Regions(\(self.entryGeoRegions.count))"
            }
        case 2:
            if geoRegion.eventType == .onExit {
                removeFromMap(geoRegion: geoRegion)
                self.lblRegionsCount.text = "Regions(\(self.exitGeoRegions.count))"
            }
        default:
            break
        }
    }
    
    private func removeFromMap(geoRegion: GeoRegion) {
        mapView.removeAnnotation(geoRegion)
        removeRadiusOverlay(forGeoRegion: geoRegion)
    }
    
    // MARK: Map overlay functions
    private func addRadiusOverlay(forGeoRegion geoRegion: GeoRegion) {
        mapView.addOverlay(MKCircle(center: geoRegion.coordinate, radius: geoRegion.radius))
    }
    
    private func removeRadiusOverlay(forGeoRegion geoRegion: GeoRegion) {
        guard let overlays = mapView?.overlays else { return }
        for overlay in overlays {
            guard let circleOverlay = overlay as? MKCircle else { continue }
            let coordinate = circleOverlay.coordinate
            if coordinate.latitude == geoRegion.coordinate.latitude && coordinate.longitude == geoRegion.coordinate.longitude && circleOverlay.radius == geoRegion.radius {
                self.mapView.removeOverlay(circleOverlay)
                break
            }
        }
    }
}

// MARK: Conforming AddGeoRegionViewControllerDelegate
extension GeoRegionsOnMapViewController: AddGeoRegionDelegate {
    func addGeoRegionViewController(coordinate: CLLocationCoordinate2D, radius: Double, identifier: String, note: String, eventType: EventType) {
        //can only monitor upto maximumREgionMonitoringDistance provided by location delegate
        let maxDistance = min(radius, locationManager.maximumRegionMonitoringDistance)
        let geoRegion = GeoRegion(coordinate: coordinate, radius: maxDistance, identifier: identifier, note: note, eventType: eventType)
        self.addToGeoRegionArrayBasedOnEventType(geoRegion: geoRegion)
        startMonitoring(geoRegion: geoRegion)
        self.saveAllGeoRegions()
    }
}

// MARK: - Location Manager Delegate Methods
extension GeoRegionsOnMapViewController: CLLocationManagerDelegate {
    func startMonitoring(geoRegion: GeoRegion) {
        if CLLocationManager.authorizationStatus() != .authorizedAlways {
            print("Always authorisation is required for region monitoring")
            return
        }
        if CLLocationManager.isMonitoringAvailable(for: CLCircularRegion.self) {
            let region = CLCircularRegion(center: geoRegion.coordinate, radius: geoRegion.radius, identifier: geoRegion.identifier)
            region.notifyOnEntry = (geoRegion.eventType == .onEntry)
            region.notifyOnExit = (geoRegion.eventType == .onExit)
            locationManager.startMonitoring(for: region)
        }
    }
    
    func stopMonitoring(geoRegion: GeoRegion) {
        for region in locationManager.monitoredRegions {
            guard let circularRegion = region as? CLCircularRegion,
                circularRegion.identifier == geoRegion.identifier else { continue }
            locationManager.stopMonitoring(for: circularRegion)
        }
    }
    
    func locationManager(_ manager: CLLocationManager, monitoringDidFailFor region: CLRegion?,withError error: Error) {
        print("Monitoring failed for region with identifier: \(region!.identifier)")
    }
    
    func locationManager(_ manager: CLLocationManager, didEnterRegion region: CLRegion) {
        if region is CLCircularRegion {
            let alertVC = UIAlertController(title: "Notification", message: "Entered region with \(region.identifier)", preferredStyle: .alert)
            let okAction = UIAlertAction(title: "OK", style: .default, handler: nil)
            alertVC.addAction(okAction)
            self.present(alertVC, animated: true, completion: nil)
            print("Entered:  Geofence triggered!")
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didExitRegion region: CLRegion) {
        if region is CLCircularRegion {
            let alertVC = UIAlertController(title: "Notification", message: "Exit from region with \(region.identifier)", preferredStyle: .alert)
            let okAction = UIAlertAction(title: "OK", style: .default, handler: nil)
            alertVC.addAction(okAction)
            self.present(alertVC, animated: true, completion: nil)
            print("Exit:  Geofence triggered!")
        }
    }
}

// MARK: - MapView Delegate Methods
extension GeoRegionsOnMapViewController: MKMapViewDelegate {

    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        let identifier = "myGeoRegion"
        if annotation is GeoRegion { //To ensure it is not a user location annotation
            var annotationView = mapView.dequeueReusableAnnotationView(withIdentifier: identifier) as? MKPinAnnotationView
            if annotationView == nil {
                annotationView = MKPinAnnotationView(annotation: annotation, reuseIdentifier: identifier)
                annotationView?.canShowCallout = true
                let removeButton = UIButton()
                removeButton.frame = CGRect(x: 0, y: 0, width: 23, height: 23)
                removeButton.setImage(#imageLiteral(resourceName: "deleteImage"), for: .normal)
                annotationView?.leftCalloutAccessoryView = removeButton
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
            circleRenderer.strokeColor = .blue
            circleRenderer.fillColor = UIColor.blue.withAlphaComponent(0.4)
            return circleRenderer
        }
        return MKOverlayRenderer(overlay: overlay)
    }

    func mapView(_ mapView: MKMapView, annotationView view: MKAnnotationView, calloutAccessoryControlTapped control: UIControl) {
        if let geoRegion = view.annotation as? GeoRegion {
            print(geoRegion.identifier)
            stopMonitoring(geoRegion: geoRegion)
            removeFromGeoRegionArrayBasedOnEventType(geoRegion: geoRegion)
        }
        saveAllGeoRegions()
    }
}

