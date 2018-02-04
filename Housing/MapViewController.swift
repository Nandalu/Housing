//
//  MapViewController.swift
//
//  Created by denkeni on 01/11/2017.
//  Copyright © 2017 Nandalu. All rights reserved.
//

import UIKit
import MapKit

extension UIColor {

    static let hou_annotationColor = UIColor(red:0.99, green:0.34, blue:0.28, alpha:1.0)  // #FD5748
}

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
    private lazy var taiwanRegion : MKCoordinateRegion = {
        return MKCoordinateRegion(center: CLLocationCoordinate2D(latitude: 23.563533658012641, longitude: 120.99793200000008), span: MKCoordinateSpan(latitudeDelta: 3.6626503643275328, longitudeDelta: 2.0419336676933426))
    }()
    private lazy var locationManager : CLLocationManager = {
        return CLLocationManager()
    }()
    private lazy var mapView : MKMapView = {
        return MKMapView(frame: self.view.frame)
    }()
    private lazy var searchController : UISearchController = {
        let searchResultTableViewController = SearchResultTableViewController(delegate: self)
        let controller = UISearchController(searchResultsController: searchResultTableViewController)
        controller.searchResultsUpdater = searchResultTableViewController
        controller.hidesNavigationBarDuringPresentation = false
        controller.dimsBackgroundDuringPresentation = true
        controller.searchBar.placeholder = "搜尋地點"
        return controller
    }()

    // MARK: - UIViewController life cycle

    override func viewDidLoad() {
        super.viewDidLoad()

        // Set up MKMapView
        mapView.delegate = self
        mapView.mapType = .mutedStandard
        mapView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        mapView.showsUserLocation = true
        view.addSubview(mapView)

        // Set up location search
        navigationItem.titleView = searchController.searchBar
        definesPresentationContext = true

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
        switch CLLocationManager.authorizationStatus() {
        case .notDetermined:
            locationManager.requestWhenInUseAuthorization()
        case .denied:
            // Move to Taiwan
            mapView.setRegion(taiwanRegion, animated: true)
        default:
            break
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    private func showPrompt(msg: String) {
        DispatchQueue.main.async {
            self.navigationItem.prompt = msg
            Timer.scheduledTimer(withTimeInterval: 3.0, repeats: false) { (timer) in
                self.navigationItem.prompt = nil
            }
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
            let taiwanBroaderRegion = MKCoordinateRegion(center: CLLocationCoordinate2D(latitude: 23.563533658012641, longitude: 120.99793200000008), span: MKCoordinateSpan(latitudeDelta: 5.0, longitudeDelta: 5.0))
            let isInTaiwan = isLocation(coordinate: userLocationCoordinate, within: taiwanBroaderRegion)
            if isInTaiwan {
                // Show user's location
                let region = MKCoordinateRegionMakeWithDistance(userLocationCoordinate, 500.0, 500.0)
                mapView.setRegion(region, animated: false)
            } else {
                // Move to Taiwan
                mapView.setRegion(taiwanRegion, animated: true)
            }
            self.mapView(mapView, regionDidChangeAnimated: true)     // make sure data show up at first glance
        }
    }

    private func isLocation(coordinate: CLLocationCoordinate2D, within region: MKCoordinateRegion) -> Bool {
        var northWestCorner = CLLocationCoordinate2D()
        var southEastCorner = CLLocationCoordinate2D()
        northWestCorner.latitude  = region.center.latitude  + (region.span.latitudeDelta  / 2.0)
        northWestCorner.longitude = region.center.longitude - (region.span.longitudeDelta / 2.0)
        southEastCorner.latitude  = region.center.latitude  - (region.span.latitudeDelta  / 2.0)
        southEastCorner.longitude = region.center.longitude + (region.span.longitudeDelta / 2.0)
        if (coordinate.latitude  <= northWestCorner.latitude &&
            coordinate.latitude  >= southEastCorner.latitude &&
            coordinate.longitude >= northWestCorner.longitude &&
            coordinate.longitude <= southEastCorner.longitude) {
            return true
        } else {
            return false
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
        requestJinmaMsgs(within: mapView, paginationKey: nil)
    }

    // MARK: Housing data
    private func requestJinmaMsgs(within mapView: MKMapView, paginationKey: String?) {
        let CLat = mapView.region.center.latitude
        let CLng = mapView.region.center.longitude
        let SLat = mapView.region.span.latitudeDelta
        let SLng = mapView.region.span.longitudeDelta
        var urlString = "https://www.jinma.io/MsgsByGeoAppUser?CLat=\(CLat)&CLng=\(CLng)&SLat=\(SLat)&SLng=\(SLng)&AppID=16VHVHiLd3NzX&UserID=128DEi3hheGXG"
        if let SortKey = paginationKey,
            let SortKeyEncoded = SortKey.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) {
            urlString += "&SKF64=\(SortKeyEncoded)"
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
                guard let errorModel = try? jsonDecoder.decode(JinErrorModel.self, from: data) else {
                    self.showPrompt(msg: "[Error] json decode failed")
                    return
                }
                self.showPrompt(msg: errorModel.Error)
                return
            }
            var isFinished : Bool = true
            var lastMsgSKF64 : String? = nil
            for msg in jinModel.Msgs {
                if self.msgsDict[msg.ID] == nil {
                    self.msgsDict[msg.ID] = ""
                    let annotation = HousingPointAnnotation()
                    annotation.coordinate = CLLocationCoordinate2D(latitude: msg.Lat, longitude: msg.Lng)
                    guard let housingData = msg.Body.data(using: .utf8),
                        let housingModel = try? jsonDecoder.decode(HousingModel.self, from: housingData) else {
                            assertionFailure()
                            continue
                    }
                    annotation.housingModel = housingModel
                    annotation.housingModelRaw = msg.Body
                    if housingModel.交易標的 == "車位" {
                        continue    // remove 車位 from calculating 每坪單價 (車位 has no data for this)
                    }
                    DispatchQueue.main.async {
                        mapView.addAnnotation(annotation)
                    }
                    isFinished = false
                }
                lastMsgSKF64 = String(format: "%f", msg.SKF64)
            }
            if !isFinished {
                self.requestJinmaMsgs(within: mapView, paginationKey: lastMsgSKF64)
            }
        }
        task.resume()
    }

    func mapView(_ mapView: MKMapView, didSelect view: MKAnnotationView) {
        if view.annotation is MKUserLocation {
            return
        }
        var models = [HousingModel]()
        if let cluster = view.annotation as? MKClusterAnnotation {
            var unsortedModels = [HousingModel]()
            for annotation in cluster.memberAnnotations {
                guard let housingAnnotaion = annotation as? HousingPointAnnotation,
                    let housingModel = housingAnnotaion.housingModel else {
                        assertionFailure()
                        continue
                }
                unsortedModels.append(housingModel)
            }
            models = unsortedModels.sorted(by: {$0.交易年月日 > $1.交易年月日})
        } else if let housingAnnotation = view.annotation as? HousingPointAnnotation,
            let housingModel = housingAnnotation.housingModel {
            models.append(housingModel)
        }
        let housingVc = HousingViewController(models: models) {
            mapView.deselectAnnotation(view.annotation, animated: true)
        }
        // a trick to show vc after user seeing callout is shown
        Timer.scheduledTimer(withTimeInterval: 0.1, repeats: false) { (timer) in
            self.show(housingVc, sender: self)
        }
    }
}

// MARK: - SearchResultDelegate

extension MapViewController : SearchResultDelegate {

    func showSearchResultError(msg: String) {
        showPrompt(msg: msg)
    }

    func didSelect(placemark: MKPlacemark) {
        let name = placemark.name
        searchController.searchBar.text = name
        let coordinate = placemark.coordinate
        let region = MKCoordinateRegionMakeWithDistance(coordinate, 5000.0, 5000.0)
        mapView.setRegion(region, animated: true)
    }
}

// MARK: -

private class HousingPointAnnotation : MKPointAnnotation {

    var housingModel : HousingModel?
    var housingModelRaw : String?
}

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
                if let price = housingModel.單價每平方公尺 {
                    totalPrice += price
                }
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
            if let price = housingModel.單價每平方公尺 {
                self.glyphText = "\(Int(price * 3.3058 / 10000))萬"    // 每坪
            }
        }
    }
}
