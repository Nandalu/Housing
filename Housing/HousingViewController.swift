//
//  HousingViewController.swift
//  Housing
//
//  Created by denkeni on 05/11/2017.
//  Copyright © 2017 Nandalu. All rights reserved.
//

import UIKit

final class HousingViewController: UITableViewController {

    private var models : [HousingModel]
    private lazy var dateFormatter : DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy/MM/dd"
        formatter.locale = Locale.current
        return formatter
    }()
    private let viewDidDisappearHandler : (() -> Void)?

    init(models: [HousingModel], viewDidDisappearHandler handler: (() -> Void)?) {
        self.models = HousingViewController.sorted(models: models)
        self.viewDidDisappearHandler = handler
        super.init(style: .grouped)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        let sortButton = UIButton(type: .system)
        sortButton.frame = CGRect(x: 0, y: 0, width: view.frame.width, height: 44.0)
        let sortButtonTitle : String
        if let sortField = UserDefaults.standard.string(forKey: "SortField") {
            sortButtonTitle = sortField
        } else {
            sortButtonTitle = "交易年月日↓"
        }
        sortButton.setTitle(sortButtonTitle, for: .normal)
        sortButton.titleLabel?.font = UIFont.preferredFont(forTextStyle: .headline)
        sortButton.addTarget(self, action: #selector(didTapSortButton), for: .touchUpInside)
        navigationItem.titleView = sortButton

        tableView.register(HousingTableViewCell.self, forCellReuseIdentifier: "UITableViewCellReuseIdentifier")
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

    // MARK: - Actions

    @objc private func didTapSortButton(sender: UIButton) {
        let actionSheet = UIAlertController(title: "排序方式", message: nil, preferredStyle: .actionSheet)
        for value in ["建築完成年月↑", "建築完成年月↓", "總價元↑", "總價元↓", "交易年月日↑", "交易年月日↓"] {
            let action = UIAlertAction(title: value, style: .default, handler: { (alertAction) in
                sender.setTitle(value, for: .normal)
                UserDefaults.standard.set(value, forKey: "SortField")
                self.models = HousingViewController.sorted(models: self.models)
                self.tableView.reloadData()
            })
            actionSheet.addAction(action)
        }
        let cancel = UIAlertAction(title: "取消", style: .cancel, handler: nil)
        actionSheet.addAction(cancel)
        let popPresenter = actionSheet.popoverPresentationController
        popPresenter?.sourceRect = sender.frame
        popPresenter?.sourceView = sender
        present(actionSheet, animated: true, completion: nil)
    }

    /// return sorted model based on UserDefaults "SortField" value
    private static func sorted(models: [HousingModel]) -> [HousingModel] {
        let sortedModels : [HousingModel]
        if let sortField = UserDefaults.standard.string(forKey: "SortField") {
            switch sortField {
            case "建築完成年月↑":
                sortedModels = models.sorted(by: {$0.建築完成年月 < $1.建築完成年月})
            case "建築完成年月↓":
                sortedModels = models.sorted(by: {$0.建築完成年月 > $1.建築完成年月})
            case "總價元↑":
                sortedModels = models.sorted(by: {$0.總價元 < $1.總價元})
            case "總價元↓":
                sortedModels = models.sorted(by: {$0.總價元 > $1.總價元})
            case "交易年月日↑":
                sortedModels = models.sorted(by: {$0.交易年月日 < $1.交易年月日})
            case "交易年月日↓":
                sortedModels = models.sorted(by: {$0.交易年月日 > $1.交易年月日})
            default:
                sortedModels = models.sorted(by: {$0.交易年月日 > $1.交易年月日})
            }
        } else {
            sortedModels = models.sorted(by: {$0.交易年月日 > $1.交易年月日})
        }
        return sortedModels
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
            case 2, 3, 4:
                cell.detailTextLabel?.textColor = UIColor.hou_annotationColor
            default:
                cell.detailTextLabel?.textColor = .gray
            }
            switch row {
            case 0:
                cell.textLabel?.text = "交易標的"
                cell.detailTextLabel?.text = model.交易標的
            case 1:
                cell.textLabel?.text = "土地區段位置或建物區門牌"
                cell.detailTextLabel?.text = model.土地區段位置或建物區門牌
            case 2:
                cell.textLabel?.text = "單價(元/每坪)"
                if let price = models[section].單價每平方公尺 {
                    cell.detailTextLabel?.text = String(format: "%.1f 萬", price * 3.3058 / 10000) // 每坪
                }
            case 3:
                cell.textLabel?.text = "建物移轉總面積(坪)"
                if let areaInM2 = model.建物移轉總面積平方公尺 {
                    cell.detailTextLabel?.text = String(format: "%.1f 坪", areaInM2 / 3.3058)
                }
            case 4:
                cell.textLabel?.text = "總價(元)"
                cell.detailTextLabel?.text = String(format: "%.0f 萬", model.總價元 / 10000)
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
                if let level = model.移轉層次, let totalLevel = model.總樓層數 {
                    cell.detailTextLabel?.text = "\(level) / \(totalLevel)"
                }
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
