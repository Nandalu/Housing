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
            button.bottomAnchor.constraint(equalTo: view.layoutMarginsGuide.bottomAnchor, constant: -20),
            button.trailingAnchor.constraint(equalTo: view.layoutMarginsGuide.trailingAnchor, constant: 0)])

        // Set up clusteringIdentifier to participate in clustering
        mapView.register(AnnotaionView.self, forAnnotationViewWithReuseIdentifier: MKMapViewDefaultAnnotationViewReuseIdentifier)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    private func showPrompt(msg: String) {
        DispatchQueue.main.async {
            self.navigationItem.prompt = msg
        }
        Timer.scheduledTimer(withTimeInterval: 3.0, repeats: false) { (timer) in
            self.navigationItem.prompt = nil
        }
    }
}

extension MapViewController : MKMapViewDelegate {

    func mapView(_ mapView: MKMapView, regionDidChangeAnimated animated: Bool) {
        requestJinmaMsgs(within: mapView, paginationT: nil)
    }

    func requestJinmaMsgs(within mapView: MKMapView, paginationT: String?) {
        let CLat = mapView.region.center.latitude
        let CLng = mapView.region.center.longitude
        let SLat = mapView.region.span.latitudeDelta
        let SLng = mapView.region.span.longitudeDelta
        var urlString = "https://www.jinma.io/MsgsByGeo?CLat=\(CLat)&CLng=\(CLng)&SLat=\(SLat)&SLng=\(SLng)"
        if let Time = paginationT {
            urlString += "&Time=\(Time)"
        }
        guard let url = URL(string: urlString) else {
            showPrompt(msg: "[Error] URL failed: \(urlString)")
            return
        }
        let task = URLSession.shared.dataTask(with: url) { (data, response, error) in
            if let error = error {
                self.showPrompt(msg: error.localizedDescription)
                return
            }
            guard let data = data else {
                self.showPrompt(msg: "[Error] data nil")
                return
            }
            let jsonDecoder = JSONDecoder()
            guard let jinModel = try? jsonDecoder.decode(JinModel.self, from: data) else {
                self.showPrompt(msg: "[Error] json decode failed")
                return
            }
            var lastMsgTime : String? = nil
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
                lastMsgTime = "\(msg.Time)"
            }
            if lastMsgTime != nil {
                self.requestJinmaMsgs(within: mapView, paginationT: lastMsgTime)
            }
        }
        task.resume()
    }
}

private class AnnotaionView : MKMarkerAnnotationView {

    override var annotation: MKAnnotation? {
        willSet {
            clusteringIdentifier = "AnnotaionView"
        }
    }
}
