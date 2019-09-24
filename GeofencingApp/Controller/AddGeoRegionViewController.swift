//
//  ViewController.swift
//  GeofencingApp
//
//  Created by vinmac on 23/09/19.
//  Copyright © 2019 vinmac. All rights reserved.
//

import UIKit
import MapKit

protocol AddGeoRegionDelegate {
    func addGeoRegionViewController(_ controller: AddGeoRegionViewController, didAddCoordinate coordinate: CLLocationCoordinate2D, radius: Double, identifier: String, note: String, eventType: EventType)
}

class AddGeoRegionViewController: UIViewController {
    
    @IBOutlet weak var txtRadius: UITextField!
    @IBOutlet weak var txtNote: UITextView!
    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var btnEntry: UIButton!
    @IBOutlet weak var btnExit: UIButton!
    
    var delegate: AddGeoRegionDelegate?
    var coordinate: CLLocationCoordinate2D = CLLocationCoordinate2D() {
        willSet(newValue) {
            let allAnnotations = self.mapView.annotations
            self.mapView.removeAnnotations(allAnnotations)
            let annotation = MKPointAnnotation()
            annotation.coordinate = newValue
            mapView.addAnnotation(annotation)
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.btnEntry.isSelected = true
        self.btnExit.isSelected = false
        self.mapView.showsUserLocation = true
        
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(mapViewTapped))
        self.mapView.addGestureRecognizer(tapGesture)
    }

    @IBAction func btnCloseTapped(sender: AnyObject) {
        dismiss(animated: true, completion: nil)
    }
    
    @IBAction func btnEventTypeTapped(sender: UIButton) {
        if sender.tag == 0 {
            self.btnEntry.isSelected = true
            self.btnEntry.setImage(#imageLiteral(resourceName: "filledRadioBtnImage"), for: .normal)
            self.btnExit.setImage(#imageLiteral(resourceName: "unfilledRadioBtnImage"), for: .normal)
            self.btnExit.isSelected = false
        } else {
            self.btnExit.isSelected = true
            self.btnExit.setImage(#imageLiteral(resourceName: "filledRadioBtnImage"), for: .normal)
            self.btnEntry.setImage(#imageLiteral(resourceName: "unfilledRadioBtnImage"), for: .normal)
            self.btnEntry.isSelected = false
        }
    }
    
    @IBAction private func btnSaveTapped(sender: AnyObject) {
        let coordinate = self.coordinate //mapView.centerCoordinate
        let radius = Double(txtRadius.text!) ?? 0
        let identifier = NSUUID().uuidString
        let note = txtNote.text
        let entryType = self.btnEntry.isSelected ? EventType.onEntry : EventType.onExit
        delegate?.addGeoRegionViewController(self, didAddCoordinate: coordinate, radius: radius, identifier: identifier, note: note!, eventType: entryType)
    }
    
    @IBAction private func btnZoomToCurrentLocationTapped(sender: AnyObject) {
        mapView.zoomToUserLocation()
    }
    
    @objc func mapViewTapped(gestureReconizer: UITapGestureRecognizer) {
        let location = gestureReconizer.location(in: mapView)
        self.coordinate = mapView.convert(location,toCoordinateFrom: mapView)
        
    }
}

