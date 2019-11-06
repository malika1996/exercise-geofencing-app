//
//  Utilities.swift
//  GeofencingApp
//
//  Created by vinmac on 24/09/19.
//  Copyright © 2019 vinmac. All rights reserved.
//

import Foundation
import UIKit
import MapKit

class Utilities {
    static let savedItems = "savedItems"
}

extension UITextView {
    open override func awakeFromNib() {
        self.layer.borderColor = UIColor.darkGray.cgColor
        self.layer.borderWidth = 1.0
    }
}

extension MKMapView {
    func zoomToUserLocation() {
        guard let coordinate = userLocation.location?.coordinate else { return }
        let region = MKCoordinateRegion(center: coordinate, latitudinalMeters: 10000, longitudinalMeters: 10000)
        self.setRegion(region, animated: true)
    }
}
