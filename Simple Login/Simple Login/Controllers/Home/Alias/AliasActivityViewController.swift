//
//  AliasActivityViewController.swift
//  Simple Login
//
//  Created by Thanh-Nhon Nguyen on 13/01/2020.
//  Copyright © 2020 SimpleLogin. All rights reserved.
//

import UIKit
import Toaster
import MarqueeLabel
import MBProgressHUD
import MessageUI

final class AliasActivityViewController: BaseApiKeyViewController {
    @IBOutlet private weak var tableView: UITableView!
    private let refreshControl = UIRefreshControl()
    
    var alias: Alias!
    
    var didUpdateAlias: ((_ alias: Alias) -> Void)?

    private var activities: [AliasActivity] = []
    
    private var fetchedPage: Int = -1
    private var isFetching: Bool = false
    private var moreToLoad: Bool = true
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setUpUI()
        fetchActivities()
        fetchAlias()
    }
    
    private func setUpUI() {
        // set up title
        let titleLabel = MarqueeLabel(frame: .zero, duration: 1.0, fadeLength: 8.0)
        titleLabel.type = .leftRight
        titleLabel.backgroundColor = .clear
        titleLabel.textColor = SLColor.textColor
        titleLabel.numberOfLines = 2
        titleLabel.font = UIFont.systemFont(ofSize: 16, weight: .medium)
        titleLabel.textAlignment = .center
        titleLabel.text = alias.email
        navigationItem.titleView = titleLabel
        
        // tableView
        tableView.sectionHeaderHeight = UITableView.automaticDimension
        tableView.estimatedSectionHeaderHeight = 200
        tableView.rowHeight = UITableView.automaticDimension
        tableView.tableFooterView = UIView(frame: .zero)
        tableView.separatorColor = .clear
        tableView.register(UINib(nibName: "AliasActivityTableHeaderView", bundle: nil), forHeaderFooterViewReuseIdentifier: "AliasActivityTableHeaderView")
        tableView.register(UINib(nibName: "LoadingFooterView", bundle: nil), forHeaderFooterViewReuseIdentifier: "LoadingFooterView")
        AliasActivityTableViewCell.register(with: tableView)
        
        tableView.refreshControl = refreshControl
        refreshControl.addTarget(self, action: #selector(refresh), for: .valueChanged)
    }
    
    @objc private func refresh() {
        fetchActivities()
        fetchAlias()
    }
    
    private func fetchActivities() {
        if refreshControl.isRefreshing {
            moreToLoad = true
        }
        
        guard moreToLoad, !isFetching else { return }
        
        isFetching = true
        
        let pageToFetch = refreshControl.isRefreshing ? 0 : fetchedPage + 1
        
        SLApiService.shared.fetchAliasActivities(apiKey: apiKey, aliasId: alias.id, page: pageToFetch) { [weak self] result in
            guard let self = self else { return }
            
            self.isFetching = false
            
            switch result {
            case .success(let activities):
                if activities.count == 0 {
                    self.moreToLoad = false
                } else {
                    if self.refreshControl.isRefreshing {
                        self.fetchedPage = 0
                        self.activities.removeAll()
                        
                    } else {
                        self.fetchedPage += 1
                    }
                    
                    self.activities.append(contentsOf: activities)
                }
                
                if self.refreshControl.isRefreshing {
                    self.refreshControl.endRefreshing()
                    Toast.displayUpToDate()
                }
                
                self.tableView.reloadData()
                
            case .failure(let error):
                self.refreshControl.endRefreshing()
                Toast.displayError(error)
            }
        }
    }
    
    private func fetchAlias() {
        SLApiService.shared.getAlias(apiKey: apiKey, id: alias.id) { [weak self] result in
            guard let self = self else { return }
            
            switch result {
            case .success(let alias):
                self.alias = alias
                self.didUpdateAlias?(alias)
                self.tableView.reloadData()
                
            case .failure(let error):
                Toast.displayError(error)
            }
        }
    }
}

// MARK: - Edit name
extension AliasActivityViewController {
    private func presentEditNameAlert() {
        let title: String
        if let _ = alias.name {
            title = "Edit name for alias"
        } else {
            title = "Add name for alias"
        }
        
        let alert = UIAlertController(title: title, message: alias.email, preferredStyle: .alert)
        alert.addTextField { [unowned self] textField in
            textField.clearButtonMode = .always
            textField.placeholder = "John Doe"
            textField.text = self.alias.name
        }
        
        let updateAction = UIAlertAction(title: "Save", style: .default) { [unowned self] _ in
            let name = alert.textFields?[0].text
            self.updateName(name != "" ? name : nil)
        }
        alert.addAction(updateAction)
        
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
        alert.addAction(cancelAction)
        
        present(alert, animated: true, completion: nil)
    }
    
    private func updateName(_ name: String?) {
        MBProgressHUD.showAdded(to: view, animated: true)
        
        SLApiService.shared.updateAliasName(apiKey: apiKey, id: alias.id, name: name) { [weak self] result in
            guard let self = self else { return }
            MBProgressHUD.hide(for: self.view, animated: true)
            
            switch result {
            case .success(_):
                self.alias.setName(name)
                self.tableView.reloadData()
                self.didUpdateAlias?(self.alias)
                
            case .failure(let error):
                Toast.displayError(error)
            }
        }
    }
}

// MARK: - Edit notes
extension AliasActivityViewController {
    private func presentEditNoteAlert() {
        let title: String
        if let _ = alias.note {
            title = "Edit note for alias"
        } else {
            title = "Add note for alias"
        }
        
        let alert = UIAlertController(title: title, message: alias.email, preferredStyle: .alert)
        
        let textView = alert.addTextView(initialText: alias.note)
        
        let updateAction = UIAlertAction(title: "Save", style: .default) { [unowned self] _ in
            let note = textView.text
            self.updateNote(note != "" ? note : nil)
        }
        alert.addAction(updateAction)
        
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
        alert.addAction(cancelAction)
        present(alert, animated: true) {
            textView.becomeFirstResponder()
        }
    }
    
    private func updateNote(_ note: String?) {
        MBProgressHUD.showAdded(to: view, animated: true)
        
        SLApiService.shared.updateAliasNote(apiKey: apiKey, id: alias.id, note: note) { [weak self] result in
            guard let self = self else { return }
            MBProgressHUD.hide(for: self.view, animated: true)
            
            switch result {
            case .success(_):
                self.alias.setNote(note)
                self.tableView.reloadData()
                self.didUpdateAlias?(self.alias)
                
            case .failure(let error):
                Toast.displayError(error)
            }
        }
    }
}

// MARK: - UITableViewDelegate
extension AliasActivityViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let activity = activities[indexPath.row]
        
        switch activity.action {
        case .forward, .block, .bounced:
            presentReverseAliasAlert(from: activity.to, to: activity.from, reverseAlias: activity.reverseAlias, mailComposerVCDelegate: self)
            
        case .reply:
            presentReverseAliasAlert(from: activity.from, to: activity.to, reverseAlias: activity.reverseAlias, mailComposerVCDelegate: self)
        }
    }
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let header = tableView.dequeueReusableHeaderFooterView(withIdentifier: "AliasActivityTableHeaderView") as? AliasActivityTableHeaderView
        header?.bind(with: alias)
        
        header?.didTapEditNoteButton = { [unowned self] in
            self.presentEditNoteAlert()
        }
        
        header?.didTapEditNameButton = { [unowned self] in
            self.presentEditNameAlert()
        }
        
        return header
    }
    
    func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        return moreToLoad ? 44.0 : 1.0
    }
    
    func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        if moreToLoad {
            let loadingFooterView =  tableView.dequeueReusableHeaderFooterView(withIdentifier: "LoadingFooterView") as? LoadingFooterView
            loadingFooterView?.animate()
            return loadingFooterView
        } else {
            return nil
        }
    }
    
    func tableView(_ tableView: UITableView, willDisplayFooterView view: UIView, forSection section: Int) {
        if moreToLoad {
            fetchActivities()
        }
    }
}

// MARK: - UITableViewDataSource
extension AliasActivityViewController: UITableViewDataSource {
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return activities.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = AliasActivityTableViewCell.dequeueFrom(tableView, forIndexPath: indexPath)
        cell.bind(with: activities[indexPath.row])
        return cell
    }
}

// MARK: - MFMailComposeViewControllerDelegate
extension AliasActivityViewController: MFMailComposeViewControllerDelegate {
    func mailComposeController(_ controller: MFMailComposeViewController, didFinishWith result: MFMailComposeResult, error: Error?) {
        controller.dismiss(animated: true, completion: nil)
    }
}
