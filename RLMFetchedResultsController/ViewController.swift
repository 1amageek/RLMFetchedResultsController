//
//  ViewController.swift
//  RLMFetchedResultsController
//
//  Created by 1amageek on 2016/03/26.
//  Copyright © 2016年 Stamp inc. All rights reserved.
//

import UIKit
import RealmSwift
import CoreData

class ViewController: UITableViewController, RLMFetchedResultsControllerDelegate {
    
    @IBOutlet weak var textField: UITextField!
    
    @IBAction func saveButton(sender: AnyObject) {
        
        let text = textField.text
        if !(text?.isEmpty)! {

            let dog: Dog = Dog()
            dog.name = text!
            let realm = try! Realm()
            try! realm.write {
                realm.add(dog)
            }
            textField.text = ""
        }
        
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0)) { 
            let realm = try! Realm()
            for i in 0..<100 {
                for k in 0..<10 {
                    let dog: Dog = Dog()
                    dog.name = String(format: "%ld-%ld",i,k)
                    try! realm.write {
                        realm.add(dog)
                    }
                    print(dog.name)
                }
            }
        }
    }
    
    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return self.fetchedResultsController.sections?.count ?? 0
    }
    
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        let sectionInfo = self.fetchedResultsController.sections![section]
        return sectionInfo.numberOfObjects
    }
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell: UITableViewCell = tableView.dequeueReusableCellWithIdentifier("UITableViewCell", forIndexPath: indexPath)
        let dog: Dog = self.fetchedResultsController.objectAtIndexPath(indexPath) as! Dog
        cell.textLabel?.text = dog.name
        return cell
    }
    
    override func tableView(tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        let sectionInfo = self.fetchedResultsController.sections![section]
        return sectionInfo.name
    }
    
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    // MARK: - Fetched results controller
    
    var fetchedResultsController: RLMFetchedResultsController {
        if _fetchedResultsController != nil {
            return _fetchedResultsController!
        }
        
        let fetchRequest: RLMFetchRequest = RLMFetchRequest(Dog)
        
        // Edit the sort key as appropriate.
        let sortDescriptor = SortDescriptor(property: "name", ascending: true)
        
        fetchRequest.sortDescriptors = [sortDescriptor]
        // nil for section name key path means "no sections".
        let aFetchedResultsController = RLMFetchedResultsController(fetchRequest: fetchRequest, sectionNameKeyPath: "name")
        aFetchedResultsController.delegate = self
        _fetchedResultsController = aFetchedResultsController
        
        do {
            try _fetchedResultsController!.performFetch()
        } catch {
            // Replace this implementation with code to handle the error appropriately.
            // abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
            abort()
        }
    
        
        return _fetchedResultsController!
    }
    var _fetchedResultsController: RLMFetchedResultsController? = nil
    
    // MARK: - RLMFetchedResultsControllerDelegate
    
    func controllerWillChangeContent(controller: RLMFetchedResultsController) {
        // TODO
    }
    
    func controller(controller: RLMFetchedResultsController, didChangeSection sectionInfo: RLMFetchedResultsSectionInfo, atIndex sectionIndex: Int, forChangeType type: RLMFetchedResultsChangeType) {
        // TODO
    }
    
    func controller(controller: RLMFetchedResultsController, didChangeObject anObject: AnyObject, atIndexPath indexPath: NSIndexPath?, forChangeType type: RLMFetchedResultsChangeType, newIndexPath: NSIndexPath?) {
        // TOOD
    }
    
    func controllerDidChangeContent(controller: RLMFetchedResultsController) {
        self.tableView.reloadData()
    }

}

