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
    
    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var segmentedControlBar: UISegmentedControl!
    @IBOutlet weak var lblRegionsCount: UILabel!
    
    @IBAction func btnAddRegionTapped(_ sender: UIButton) {
        if let vc = self.storyboard?.instantiateViewController(withIdentifier: "AddGeoRegionViewController") as? AddGeoRegionViewController {
            vc.delegate = self
            self.present(vc, animated: true, completion: nil)
        }
    }
    var allGeoRegions: [GeoRegion] = []
    var entryGeoRegions: [GeoRegion] = []
    var exitGeoRegions: [GeoRegion] = []
    let locationManager = CLLocationManager()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.segmentedControlBar.addTarget(self, action: #selector(self.segmentedBarValueChanged), for: .valueChanged)
        self.locationManager.delegate = self
        self.locationManager.requestAlwaysAuthorization()
        self.loadAllGeoRegions()
        self.filterGeoRegionsBasedOnEventType()
        self.updateOnMap()
    }
    
    // MARK: Loading and saving functions
    func loadAllGeoRegions() {
        self.allGeoRegions.removeAll()
        self.allGeoRegions = GeoRegion.allGeoRegions()
    }
    
    func filterGeoRegionsBasedOnEventType() {
        for geoRegion in self.allGeoRegions {
            if geoRegion.eventType == .onEntry {
                self.entryGeoRegions.append(geoRegion)
            } else {
                self.exitGeoRegions.append(geoRegion)
            }
        }
    }
    
    func saveAllGeoRegions() {
        let encoder = JSONEncoder()
        do {
            let data = try encoder.encode(self.allGeoRegions)
            UserDefaults.standard.set(data, forKey: Utilities.savedItems)
        } catch {
            print("error encoding GeoRegions")
        }
        
    }
    
    @objc func segmentedBarValueChanged(sender: UISegmentedControl) {
        self.updateOnMap()
    }
    
    // MARK: Update Functions
    func updateOnMap() {
        switch self.segmentedControlBar.selectedSegmentIndex {
        case 0:
            self.allGeoRegions.forEach(addOnMap(_:))
            self.lblRegionsCount.text = "Regions(\(self.allGeoRegions.count))"
        case 1:
            self.entryGeoRegions.forEach(addOnMap(_:))
            self.exitGeoRegions.forEach(removeFromMap(_:))
            self.lblRegionsCount.text = "Regions(\(self.entryGeoRegions.count))"
        case 2:
            self.exitGeoRegions.forEach(addOnMap(_:))
            self.entryGeoRegions.forEach(removeFromMap(_:))
            self.lblRegionsCount.text = "Regions(\(self.exitGeoRegions.count))"
        default:
            break
        }
    }
    
    func addToGeoRegionArrayBasedOnEventType(geoRegion: GeoRegion) {
        self.allGeoRegions.append(geoRegion)
        if geoRegion.eventType == .onEntry {
            self.entryGeoRegions.append(geoRegion)
        } else {
            self.exitGeoRegions.append(geoRegion)
        }
        
        switch self.segmentedControlBar.selectedSegmentIndex {
        case 0:
            self.addOnMap(geoRegion)
        case 1:
            if geoRegion.eventType == .onEntry {
                self.addOnMap(geoRegion)
            }
        case 2:
            if geoRegion.eventType == .onExit {
                self.addOnMap(geoRegion)
            }
        default:
            break
        }
    }
    
    func addOnMap(_ geoRegion: GeoRegion) {
        self.mapView.addAnnotation(geoRegion)
        addRadiusOverlay(forGeoRegion: geoRegion)
    }
    
    func removeFromGeoRegionArrayBasedOnEventType(geoRegion: GeoRegion) {
        guard let index = allGeoRegions.firstIndex(of: geoRegion) else { return }
        print(index)
        print(geoRegion.identifier)
        self.allGeoRegions.remove(at: index)
        if geoRegion.eventType == .onEntry {
            guard let i = entryGeoRegions.firstIndex(of: geoRegion) else { return }
            self.entryGeoRegions.remove(at: i)
        } else {
            guard let i = exitGeoRegions.firstIndex(of: geoRegion) else { return }
            self.exitGeoRegions.remove(at: i)
        }
        
        switch self.segmentedControlBar.selectedSegmentIndex {
        case 0:
            removeFromMap(geoRegion)
            self.lblRegionsCount.text = "Regions(\(self.allGeoRegions.count))"
        case 1:
            if geoRegion.eventType == .onEntry {
                removeFromMap(geoRegion)
                self.lblRegionsCount.text = "Regions(\(self.entryGeoRegions.count))"
            }
        case 2:
            if geoRegion.eventType == .onExit {
                removeFromMap(geoRegion)
                self.lblRegionsCount.text = "Regions(\(self.exitGeoRegions.count))"
            }
        default:
            break
        }
        
    }
    
    func removeFromMap(_ geoRegion: GeoRegion) {
        mapView.removeAnnotation(geoRegion)
        removeRadiusOverlay(forGeoRegion: geoRegion)
    }
    
    // MARK: Map overlay functions
    func addRadiusOverlay(forGeoRegion geoRegion: GeoRegion) {
        mapView?.addOverlay(MKCircle(center: geoRegion.coordinate, radius: geoRegion.radius))
    }
    
    func removeRadiusOverlay(forGeoRegion geoRegion: GeoRegion) {
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
    
    @IBAction func zoomToCurrentLocation(sender: AnyObject) {
        self.mapView.zoomToUserLocation()
    }
    
}

// MARK: Conforming AddGeoRegionViewControllerDelegate
extension GeoRegionsOnMapViewController: AddGeoRegionDelegate {

    func addGeoRegionViewController(_ controller: AddGeoRegionViewController, didAddCoordinate coordinate: CLLocationCoordinate2D, radius: Double, identifier: String, note: String, eventType: EventType) {
        controller.dismiss(animated: true, completion: nil)
        let geoRegion = GeoRegion(coordinate: coordinate, radius: radius, identifier: identifier, note: note, eventType: eventType)
        self.addToGeoRegionArrayBasedOnEventType(geoRegion: geoRegion)
        self.saveAllGeoRegions()
    }

}

// MARK: - Location Manager Delegate Methods
extension GeoRegionsOnMapViewController: CLLocationManagerDelegate {
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        self.mapView.showsUserLocation = (status == .authorizedAlways)
    }
}

// MARK: - MapView Delegate Methods
extension GeoRegionsOnMapViewController: MKMapViewDelegate {
    
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        let identifier = "myGeoRegion"
        if annotation is GeoRegion {
            var annotationView = mapView.dequeueReusableAnnotationView(withIdentifier: identifier) as? MKPinAnnotationView
            if annotationView == nil {
                annotationView = MKPinAnnotationView(annotation: annotation, reuseIdentifier: identifier)
                annotationView?.canShowCallout = true
                let removeButton = UIButton(type: .custom)
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
            removeFromGeoRegionArrayBasedOnEventType(geoRegion: geoRegion)
        }
        saveAllGeoRegions()
    }
    
}

