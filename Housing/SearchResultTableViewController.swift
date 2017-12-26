//
//  SearchResultTableViewController.swift
//  Housing
//
//  Created by denkeni on 26/12/2017.
//  Copyright © 2017 Nandalu. All rights reserved.
//

import UIKit
import MapKit

protocol SearchResultDelegate : class {

    func showSearchResultError(msg: String)
    func didSelect(placemark: MKPlacemark)
}

final class SearchResultTableViewController: UITableViewController {

    private weak var delegate : SearchResultDelegate?
    private var matchingItems: [MKMapItem] = []

    init(delegate: SearchResultDelegate) {
        self.delegate = delegate
        super.init(style: .plain)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        tableView.keyboardDismissMode = .onDrag
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "SearchResultTableViewCell")
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    // MARK: - UITableViewDataSource

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return matchingItems.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "SearchResultTableViewCell", for: indexPath)
        let row = indexPath.row
        if row < matchingItems.count {
            let item = matchingItems[row]
            cell.textLabel?.text = item.placemark.name
        }
        return cell
    }

    // MARK: - UITableViewDelegate

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let row = indexPath.row
        if row < matchingItems.count {
            let placemark = matchingItems[row].placemark
            delegate?.didSelect(placemark: placemark)
            dismiss(animated: true, completion: nil)
        }
    }
}

// MARK: - UISearchResultsUpdating

extension SearchResultTableViewController : UISearchResultsUpdating {

    func updateSearchResults(for searchController: UISearchController) {
        guard let searchBarText = searchController.searchBar.text else { return }
        if searchBarText == "" {
            return
        }
        let request = MKLocalSearchRequest()
        request.naturalLanguageQuery = searchBarText
        let taiwanRegion = MKCoordinateRegion(center: CLLocationCoordinate2D(latitude: 23.563533658012641, longitude: 120.99793200000008), span: MKCoordinateSpan(latitudeDelta: 3.6626503643275328, longitudeDelta: 2.0419336676933426))
        request.region = taiwanRegion
        let search = MKLocalSearch(request: request)
        search.start { (response, error) in
            if let error = error {
                self.delegate?.showSearchResultError(msg: error.localizedDescription)
                return
            }
            guard let response = response else {
                self.delegate?.showSearchResultError(msg: "No response for search")
                return
            }
            self.matchingItems = response.mapItems
            DispatchQueue.main.async {
                self.tableView.reloadData()
            }
        }
    }
}
