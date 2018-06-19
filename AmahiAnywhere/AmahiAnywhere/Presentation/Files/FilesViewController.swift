//
//  FilesTableViewController.swift
//  AmahiAnywhere
//
//  Created by Chirag Maheshwari on 08/03/18.
//  Copyright © 2018 Amahi. All rights reserved.
//

import UIKit
import Lightbox

class FilesViewController: BaseUIViewController {
    
    // Mark - Server properties, will be set from presenting class
    public var directory: ServerFile?
    public var share: ServerShare!
    
    // Mark - TableView data properties
    internal var serverFiles: [ServerFile] = [ServerFile]()
    internal var filteredFiles: [ServerFile] = [ServerFile]()
    
    internal var fileSort = FileSort.modifiedTime
    
    // Mark - UIKit properties
    @IBOutlet var filesTableView: UITableView!
    internal var refreshControl: UIRefreshControl!
    internal var downloadProgressAlertController : UIAlertController?
    internal var progressView: UIProgressView?
    internal var docController: UIDocumentInteractionController?
    
    internal var isAlertShowing = false
    internal var presenter: FilesPresenter!

    override func viewDidLoad() {
        super.viewDidLoad()
        
        presenter = FilesPresenter(self)
        
        refreshControl = UIRefreshControl()
        refreshControl.attributedTitle = NSAttributedString(string: "Pull to refresh")
        self.refreshControl?.addTarget(self, action: #selector(handleRefresh), for: UIControlEvents.valueChanged)
        filesTableView.addSubview(refreshControl)
        
        let longPress = UILongPressGestureRecognizer(target: self, action: #selector(handleLongPress))
        filesTableView.addGestureRecognizer(longPress)
        
        self.navigationItem.title = getTitle()
        
        presenter.getFiles(share, directory: directory)
    }
    
    @objc func handleLongPress(sender: UILongPressGestureRecognizer){
        if sender.state == UIGestureRecognizerState.began {
            let touchPoint = sender.location(in: filesTableView)
            if let indexPath = filesTableView.indexPathForRow(at: touchPoint) {
                
                let file = self.filteredFiles[indexPath.row]
                
                let download = self.creatAlertAction(StringLiterals.DOWNLOAD, style: .default) { (action) in
                    let file = self.filteredFiles[indexPath.row]
                    self.presenter.makeFileAvailableOffline(file)
                }!
                
                let removeOffline = self.creatAlertAction(StringLiterals.REMOVE_OFFLINE, style: .default) { (action) in
                }!
                
                let stop = self.creatAlertAction(StringLiterals.STOP_DOWNLOAD, style: .default) { (action) in
                }!
                
                var actions = [UIAlertAction]()
                
                let state = presenter.checkFileOfflineState(file)
                if state == .none {
                    actions.append(download)
                } else if state == .downloaded {
                    actions.append(removeOffline)
                } else if state == .downloading {
                    actions.append(stop)
                }
                
                let cancel = self.creatAlertAction(StringLiterals.CANCEL, style: .cancel, clicked: nil)!
                actions.append(cancel)
                
                self.createActionSheet(title: "", message: "", ltrActions: actions, preferredActionPosition: 0)
            }
        }
    }
    
    @objc func handleRefresh(sender: UIRefreshControl) {
        presenter.getFiles(share, directory: directory)
    }
    
    func getTitle() -> String? {
        if directory != nil {
            return directory!.name
        }
        return share!.name
    }
    
    internal func setupDownloadProgressIndicator() {
        downloadProgressAlertController = UIAlertController(title: "", message: "", preferredStyle: .alert)
        progressView = UIProgressView(progressViewStyle: .bar)
        progressView?.setProgress(0.0, animated: true)
        progressView?.frame = CGRect(x: 10, y: 100, width: 250, height: 2)
        downloadProgressAlertController?.view.addSubview(progressView!)
        let height:NSLayoutConstraint = NSLayoutConstraint(item: downloadProgressAlertController!.view, attribute: NSLayoutAttribute.height, relatedBy: NSLayoutRelation.equal, toItem: nil, attribute: NSLayoutAttribute.notAnAttribute, multiplier: 1, constant: 120)
        downloadProgressAlertController?.view.addConstraint(height);
    }
    
    // MARK: - Navigation
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        let vc: FilesViewController = segue.destination as! FilesViewController
        vc.share = self.share
        vc.directory = filteredFiles[(filesTableView.indexPathForSelectedRow?.row)!]
    }
}
