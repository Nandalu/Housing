//
//  MapViewController.swift
//
//  Created by denkeni on 01/11/2017.
//  Copyright © 2017 Nandalu. All rights reserved.
//

import UIKit
import MapKit

class MapViewController: UIViewController {

    private var msgsDict = [String: Any]()

    override func viewDidLoad() {
        super.viewDidLoad()

        // Set up MKMapView
        let mapView = MKMapView(frame: view.frame)
        mapView.delegate = self
        mapView.mapType = .mutedStandard
        mapView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        view.addSubview(mapView)

        // Set up MKUserTrackingButton
        let button = MKUserTrackingButton(mapView: mapView)
        button.layer.backgroundColor = UIColor(white: 1, alpha: 0.8).cgColor
        button.layer.borderColor = UIColor.white.cgColor
        button.layer.borderWidth = 1
        button.layer.cornerRadius = 5
        button.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(button)
        NSLayoutConstraint.activate([
            button.bottomAnchor.constraint(equalTo: view.layoutMarginsGuide.bottomAnchor, constant: -10),
            button.trailingAnchor.constraint(equalTo: view.layoutMarginsGuide.trailingAnchor, constant: 0)])

        // Set up clusteringIdentifier to participate in clustering
        mapView.register(AnnotaionView.self, forAnnotationViewWithReuseIdentifier: MKMapViewDefaultAnnotationViewReuseIdentifier)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
}

extension MapViewController : MKMapViewDelegate {

    func mapView(_ mapView: MKMapView, regionDidChangeAnimated animated: Bool) {
        let CLat = mapView.region.center.latitude
        let CLng = mapView.region.center.longitude
        let SLat = mapView.region.span.latitudeDelta
        let SLng = mapView.region.span.longitudeDelta
        guard let url = URL(string: "https://www.jinma.io/MsgsByGeo?CLat=\(CLat)&CLng=\(CLng)&SLat=\(SLat)&SLng=\(SLng)") else {
            assertionFailure()
            return
        }
        let task = URLSession.shared.dataTask(with: url) { (data, response, error) in
            if let _ = error {
                assertionFailure()
                return
            }
            guard let data = data else {
                assertionFailure()
                return
            }
            let jsonDecoder = JSONDecoder()
            guard let jinModel = try? jsonDecoder.decode(JinModel.self, from: data) else {
                assertionFailure()
                return
            }
            for msg in jinModel.Msgs {
                if self.msgsDict[msg.ID] == nil {
                    self.msgsDict[msg.ID] = ""
                    let annotation = MKPointAnnotation()
                    annotation.coordinate = CLLocationCoordinate2D(latitude: msg.Lat, longitude: msg.Lng)
                    annotation.title = msg.App.Name
                    annotation.subtitle = msg.User.Name
                    DispatchQueue.main.async {
                        mapView.addAnnotation(annotation)
                    }
                }
            }
        }
        task.resume()
    }
}

private class AnnotaionView : MKMarkerAnnotationView {

    override init(annotation: MKAnnotation?, reuseIdentifier: String?) {
        super.init(annotation: annotation, reuseIdentifier: reuseIdentifier)
        clusteringIdentifier = "AnnotaionView"
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
