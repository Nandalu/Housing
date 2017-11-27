//
//  HousingViewController.swift
//  Housing
//
//  Created by denkeni on 05/11/2017.
//  Copyright © 2017 Nandalu. All rights reserved.
//

import UIKit

final class HousingViewController: UITableViewController {

    private let models : [HousingModel]
    private lazy var dateFormatter : DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.locale = Locale.current
        return formatter
    }()
    private let viewDidDisappearHandler : (() -> Void)?

    init(models: [HousingModel], viewDidDisappearHandler handler: (() -> Void)?) {
        self.models = models
        self.viewDidDisappearHandler = handler
        super.init(style: .grouped)

        tableView.register(HousingTableViewCell.self, forCellReuseIdentifier: "UITableViewCellReuseIdentifier")
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        if let viewDidDisappearHandler = viewDidDisappearHandler {
            viewDidDisappearHandler()
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        return models.count
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 11
    }

    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return "\(section + 1)"
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "UITableViewCellReuseIdentifier", for: indexPath)
        let section = indexPath.section
        let row = indexPath.row
        if section < models.count {
            let model = models[section]
            switch row {
            case 0:
                cell.textLabel?.text = "交易標的"
                cell.detailTextLabel?.text = model.交易標的
            case 1:
                cell.textLabel?.text = "土地區段位置或建物區門牌"
                cell.detailTextLabel?.text = model.土地區段位置或建物區門牌
            case 2:
                cell.textLabel?.text = "單價(每坪)"
                let price = models[section].單價每平方公尺
                cell.detailTextLabel?.text = "\(Int(price * 3.3058 / 10000))萬"    // 每坪
            case 3:
                cell.textLabel?.text = "建物移轉總面積(坪)"
                cell.detailTextLabel?.text = "\(model.建物移轉總面積平方公尺 / 3.3058)"
            case 4:
                cell.textLabel?.text = "總價(元)"
                let price = model.總價元
                cell.detailTextLabel?.text = "\(price / 10000)萬"
            case 5:
                cell.textLabel?.text = "交易年月日"
                let date = Date(timeIntervalSince1970: model.交易年月日)
                let dateString = self.dateFormatter.string(from: date)
                cell.detailTextLabel?.text = dateString
            case 6:
                cell.textLabel?.text = "建築完成年月"
                let date = Date(timeIntervalSince1970: model.建築完成年月)
                let dateString = dateFormatter.string(from: date)
                cell.detailTextLabel?.text = dateString
            case 7:
                cell.textLabel?.text = "交易筆棟數"
                cell.detailTextLabel?.text = model.交易筆棟數
            case 8:
                cell.textLabel?.text = "移轉層次 / 總樓層數"
                cell.detailTextLabel?.text = "\(model.移轉層次) / \(model.總樓層數)"
            case 9:
                cell.textLabel?.text = "建物型態"
                cell.detailTextLabel?.text = model.建物型態
            case 10:
                cell.textLabel?.text = "備註"
                cell.detailTextLabel?.text = model.備註
            default:
                break
            }
        }
        return cell
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if UIDevice.current.userInterfaceIdiom == .pad {
            return
        }
        tableView.deselectRow(at: indexPath, animated: true)
        let cell = tableView.cellForRow(at: indexPath)
        let alert = UIAlertController(title: cell?.textLabel?.text, message: cell?.detailTextLabel?.text, preferredStyle: .actionSheet)
        let confirm = UIAlertAction(title: "OK", style: .default, handler: nil)
        alert.addAction(confirm)
        present(alert, animated: true, completion: nil)
    }
}

private final class HousingTableViewCell : UITableViewCell {

    override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        super.init(style: .value1, reuseIdentifier: reuseIdentifier)
        if UIDevice.current.userInterfaceIdiom == .pad {
            selectionStyle = .none
        }
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
