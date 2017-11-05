//
//  MapViewController.swift
//
//  Created by denkeni on 01/11/2017.
//  Copyright © 2017 Nandalu. All rights reserved.
//

import UIKit
import MapKit

final class MapViewController: UIViewController {

    private var msgsDict = [String: Any]()
    private var networkActivityCounter : UInt = 0 {
        didSet {
            DispatchQueue.main.async {
                switch self.networkActivityCounter {
                case 0:
                    UIApplication.shared.isNetworkActivityIndicatorVisible = false
                default:
                    UIApplication.shared.isNetworkActivityIndicatorVisible = true
                }
            }
        }
    }
    private var isFirstTimeUpdateUserLocation : Bool = true
    private lazy var locationManager : CLLocationManager = {
        return CLLocationManager()
    }()

    // MARK: - UIViewController life cycle

    override func viewDidLoad() {
        super.viewDidLoad()

        // Set up MKMapView
        let mapView = MKMapView(frame: view.frame)
        mapView.delegate = self
        mapView.mapType = .mutedStandard
        mapView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        mapView.showsUserLocation = true
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

        // Set up clustering
        mapView.register(AnnotaionView.self, forAnnotationViewWithReuseIdentifier: MKMapViewDefaultAnnotationViewReuseIdentifier)
        mapView.register(ClusterAnnotationView.self, forAnnotationViewWithReuseIdentifier: MKMapViewDefaultClusterAnnotationViewReuseIdentifier)

        // Location permission
        if CLLocationManager.authorizationStatus() == .notDetermined {
            locationManager.requestWhenInUseAuthorization()
        }
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.isNavigationBarHidden = true
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        navigationController?.isNavigationBarHidden = false
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    /// Only for debug - show navigation bar to show prompt
    private func showPrompt(msg: String) {
        DispatchQueue.main.async {
            self.navigationItem.prompt = msg
        }
        Timer.scheduledTimer(withTimeInterval: 3.0, repeats: false) { (timer) in
            self.navigationItem.prompt = nil
        }
    }
}

// MARK: - MKMapViewDelegate

extension MapViewController : MKMapViewDelegate {

    // MARK: User location
    func mapView(_ mapView: MKMapView, didUpdate userLocation: MKUserLocation) {
        if isFirstTimeUpdateUserLocation {
            isFirstTimeUpdateUserLocation = false
            let userLocationCoordinate = userLocation.coordinate
            let region = MKCoordinateRegionMakeWithDistance(userLocationCoordinate, 500.0, 500.0)
            mapView.setRegion(region, animated: false)
        }
    }

    func mapView(_ mapView: MKMapView, didChange mode: MKUserTrackingMode, animated: Bool) {
        if mode == .follow && CLLocationManager.authorizationStatus() == .denied {
            let alert = UIAlertController(title: nil, message: "您已拒絕授權位置資訊", preferredStyle: .alert)
            let changeSetting = UIAlertAction(title: "去設定改", style: .default, handler: { (action) in
                guard let url = URL(string: UIApplicationOpenSettingsURLString) else { return }
                UIApplication.shared.open(url, completionHandler: nil)
            })
            let cancel = UIAlertAction(title: "知道了", style: .cancel, handler: nil)
            alert.addAction(changeSetting)
            alert.addAction(cancel)
            present(alert, animated: true, completion: nil)
        }
    }

    func mapView(_ mapView: MKMapView, regionDidChangeAnimated animated: Bool) {
        requestJinmaMsgs(within: mapView, paginationT: nil)
    }

    // MARK: Housing data
    private func requestJinmaMsgs(within mapView: MKMapView, paginationT: String?) {
        let CLat = mapView.region.center.latitude
        let CLng = mapView.region.center.longitude
        let SLat = mapView.region.span.latitudeDelta
        let SLng = mapView.region.span.longitudeDelta
        var urlString = "https://www.jinma.io/MsgsByGeoAppUser?CLat=\(CLat)&CLng=\(CLng)&SLat=\(SLat)&SLng=\(SLng)&AppID=16VHVHiLd3NzX&UserID=128DEi3hheGXG"
        if let Time = paginationT {
            urlString += "&Time=\(Time)"
        }
        guard let url = URL(string: urlString) else {
            showPrompt(msg: "[Error] URL failed: \(urlString)")
            return
        }
        networkActivityCounter += 1
        let task = URLSession.shared.dataTask(with: url) { (data, response, error) in
            self.networkActivityCounter -= 1
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
                    let annotation = HousingPointAnnotation()
                    annotation.coordinate = CLLocationCoordinate2D(latitude: msg.Lat, longitude: msg.Lng)
                    if let housingData = msg.Body.data(using: .utf8),
                        let housingModel = try? jsonDecoder.decode(HousingModel.self, from: housingData) {
                        annotation.housingModel = housingModel
                    }
                    annotation.housingModelRaw = msg.Body
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

    func mapView(_ mapView: MKMapView, didSelect view: MKAnnotationView) {
        var models = [HousingModel]()
        if let cluster = view.annotation as? MKClusterAnnotation {
            for annotation in cluster.memberAnnotations {
                guard let housingAnnotaion = annotation as? HousingPointAnnotation,
                    let housingModel = housingAnnotaion.housingModel else {
                        assertionFailure()
                        continue
                }
                models.append(housingModel)
            }
        } else if let housingAnnotation = view.annotation as? HousingPointAnnotation,
            let housingModel = housingAnnotation.housingModel {
            models.append(housingModel)
        }
        let housingVc = HousingViewController(models: models)
        // a trick to show vc after user seeing callout is shown
        Timer.scheduledTimer(withTimeInterval: 0.1, repeats: false) { (timer) in
            self.show(housingVc, sender: self)
        }
    }
}

// MARK: -

private class HousingPointAnnotation : MKPointAnnotation {

    var housingModel : HousingModel?
    var housingModelRaw : String?
}

/*
private class MarkerAnnotationView : MKMarkerAnnotationView {

    override init(annotation: MKAnnotation?, reuseIdentifier: String?) {
        super.init(annotation: annotation, reuseIdentifier: reuseIdentifier)
        canShowCallout = false
        // Note: Calling didTapAnnotationView here reacts much faster than in setSelected: or mapView:didSelectAnnotationView
        // For the size of this project, I don't care about MVC.
        let tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(didTapAnnotationView))
        addGestureRecognizer(tapGestureRecognizer)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    @objc private func didTapAnnotationView() {
        guard let delegate = UIApplication.shared.delegate as? AppDelegate, let rootVc = delegate.window?.rootViewController else {
                return
        }
        var models = [HousingModel]()
        if let cluster = annotation as? MKClusterAnnotation {
            for annotation in cluster.memberAnnotations {
                guard let housingAnnotaion = annotation as? HousingPointAnnotation,
                    let housingModel = housingAnnotaion.housingModel else {
                    assertionFailure()
                    continue
                }
                models.append(housingModel)
            }
        } else if let housingAnnotation = annotation as? HousingPointAnnotation,
            let housingModel = housingAnnotation.housingModel {
            models.append(housingModel)
        }
        let housingVc = HousingViewController(models: models)
        rootVc.show(housingVc, sender: self)
    }
}
 */

private final class ClusterAnnotationView : MKMarkerAnnotationView {

    override var annotation: MKAnnotation? {
        didSet {
            guard let cluster = annotation as? MKClusterAnnotation else {
                return
            }
            var totalPrice : Float = 0
            var count : Int = 0
            for memberAnnotation in cluster.memberAnnotations {
                guard let annotation = memberAnnotation as? HousingPointAnnotation,
                let housingModel = annotation.housingModel else {
                    assertionFailure()
                    continue
                }
                totalPrice += housingModel.單價每平方公尺
                count += 1
            }
            if count == 0 {
                assertionFailure()
                return
            }
            let averagePrice = totalPrice / Float(count)
            self.glyphText = "\(Int(averagePrice * 3.3058 / 10000))萬"    // 每坪
        }
    }
}

private final class AnnotaionView : MKMarkerAnnotationView {

    override var annotation: MKAnnotation? {
        didSet {
            clusteringIdentifier = "AnnotaionView"
            guard let annotation = annotation as? HousingPointAnnotation,
                let housingModel = annotation.housingModel else {
                    return
            }
            let price = housingModel.單價每平方公尺
            self.glyphText = "\(Int(price * 3.3058 / 10000))萬"    // 每坪
        }
    }
}
