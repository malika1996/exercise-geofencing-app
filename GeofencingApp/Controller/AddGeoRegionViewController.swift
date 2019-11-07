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
    func addGeoRegionViewController(coordinate: CLLocationCoordinate2D, radius: Double, identifier: String, note: String, eventType: EventType)
}

class AddGeoRegionViewController: UIViewController {
    
    // MARK: Private IBOutlets
    @IBOutlet weak private var txtRadius: UITextField!
    @IBOutlet weak private var txtNote: UITextView!
    @IBOutlet weak private var mapView: MKMapView!
    @IBOutlet weak private var btnEntry: UIButton!
    @IBOutlet weak private var btnExit: UIButton!
    
    // MARK: Class properties
    var delegate: AddGeoRegionDelegate?
    private var firstResponder: UITextField?
    private var coordinate: CLLocationCoordinate2D = CLLocationCoordinate2D() {
        willSet(newValue) {
            let allAnnotations = self.mapView.annotations
            self.mapView.removeAnnotations(allAnnotations)
            let annotation = MKPointAnnotation()
            annotation.coordinate = newValue
            mapView.addAnnotation(annotation)
        }
    }
    
    // MARK: View controller life cycle methods
    override func viewDidLoad() {
        super.viewDidLoad()
        self.btnEntry.isSelected = true
        self.btnExit.isSelected = false
        self.mapView.showsUserLocation = true
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(mapViewTapped))
        self.mapView.addGestureRecognizer(tapGesture)
        self.txtRadius.keyboardType = .decimalPad
        self.addToolbarToKeyboard()
        self.txtNote.delegate = self
        self.txtRadius.delegate = self
    }
    
    override func viewDidAppear(_ animated: Bool) {
        self.mapView.zoomToUserLocation()
    }

    // MARK: IBActions, ObjC methods
    @IBAction private func btnCloseTapped(sender: AnyObject) {
        self.navigationController?.popViewController(animated: true)
    }
    
    @IBAction private func btnEventTypeTapped(sender: UIButton) {
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
        let coordinate = self.coordinate
        let radius = Double(txtRadius.text!) ?? 0
        let identifier = NSUUID().uuidString
        let note = txtNote.text ?? ""
        if note.isEmpty {
            let alertVC = UIAlertController(title: "Warning", message: "Please provide a relevant note", preferredStyle: .alert)
            let okAction = UIAlertAction(title: "OK", style: .default, handler: nil)
            alertVC.addAction(okAction)
            self.present(alertVC, animated: true, completion: nil)
        } else {
            let entryType = self.btnEntry.isSelected ? EventType.onEntry : EventType.onExit
            delegate?.addGeoRegionViewController(coordinate: coordinate, radius: radius, identifier: identifier, note: note, eventType: entryType)
            self.navigationController?.popViewController(animated: true)
        }
    }
    
    @IBAction private func btnZoomToCurrentLocationTapped(sender: AnyObject) {
        mapView.zoomToUserLocation()
    }
    
    @objc private func mapViewTapped(gestureReconizer: UITapGestureRecognizer) {
        let location = gestureReconizer.location(in: mapView)
        self.coordinate = mapView.convert(location,toCoordinateFrom: mapView)
    }
    
    @objc private func btnDoneTapped(sender: UIButton) {
        self.firstResponder?.resignFirstResponder()
    }
    
    // MARK: Class Private methods
    private func addToolbarToKeyboard() {
        let toolbar = UIToolbar(frame: CGRect(x: 0, y: 0, width: UIScreen.main.bounds.width, height: 50))
        let btnDone = UIBarButtonItem(title: "done", style: .done, target: self, action: #selector(self.btnDoneTapped(sender:)))
        toolbar.setItems([btnDone], animated: true)
        self.txtRadius.inputAccessoryView = toolbar
    }
}

extension AddGeoRegionViewController: UITextFieldDelegate {
    func textFieldDidBeginEditing(_ textField: UITextField) {
        textField.becomeFirstResponder()
        self.firstResponder = textField
    }
}

extension AddGeoRegionViewController: UITextViewDelegate {
    func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
        if text == "\n" {
            textView.resignFirstResponder()
            return false
        }
        return true
    }
}
