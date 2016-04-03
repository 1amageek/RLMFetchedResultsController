//
//  RLMFetchedResultsController.swift
//  RLMFetchedResultsController
//
//  Created by 1amageek on 2016/03/26.
//  Copyright © 2016年 Stamp inc. All rights reserved.
//

import RealmSwift

protocol RLMFetchedResultsSectionInfo {
    
    /* Name of the section
     */
    var name: String { get }
    
    /* Title of the section (used when displaying the index)
     */
    var indexTitle: String? { get }
    
    /* Number of objects in section
     */
    var numberOfObjects: Int { get }
    
    /* Returns the array of objects in the section.
     */
    var objects: [AnyObject]? { get }
    
    
}

class _RLMFetchedResultsSectionInfo: NSObject, RLMFetchedResultsSectionInfo {

    var fetchRequest: RLMFetchRequest!
    var token: NotificationToken?
    
    override init() {
        super.init()
    }
    
    convenience init(fetchRequest: RLMFetchRequest, name: String) {
        self.init()
        self.fetchRequest = fetchRequest
        self._name = name
    }
    
    var _name: String = ""
    var name: String {
        return _name
    }
    
    var indexTitle: String? {
        return ""
    }
    
    var _numberOfObjects: Int = 1
    var numberOfObjects: Int {
        return self.results.count
    }
    
    var objects: [AnyObject]? {
        return Array(self.results)
    }
    
    private lazy var results: Results<Object> = {
        let fetchRequest = self.fetchRequest
        let type: Object.Type = fetchRequest.type
        var results = try! Realm().objects(type)
        
        // filter
        if let predicate = fetchRequest.predicate {
            results = results.filter(predicate)
        }
        
        // sorted
        if let sortDescriptors = fetchRequest.sortDescriptors {
            results = results.sorted(sortDescriptors)
        }
        return results
    }()
    
}

class RLMFetchedResultsController: NSObject {
    
    enum RLMFetchedResultsControllerError: ErrorType {
        case InvalidSectionNameKeyPath
        case InvalidFetchRequestType
        case InvalidRealm
    }
    
    var delegate: RLMFetchedResultsControllerDelegate?
    private(set) var sections: [RLMFetchedResultsSectionInfo]?
    private(set) var fetchRequest: RLMFetchRequest
    private(set) var sectionNameKeyPath: String?
    private(set) var realm: Realm?
    
    init(fetchRequest: RLMFetchRequest, sectionNameKeyPath: String) {
        self.fetchRequest = fetchRequest
        self.sectionNameKeyPath = sectionNameKeyPath
    }
    
    /* Returns the results of the fetch.
     Returns nil if the performFetch: hasn't been called.
     */
    var fetchedObjects: [AnyObject]?
    
    /* Returns the fetched object at a given indexPath.
     */
    func objectAtIndexPath(indexPath: NSIndexPath) -> AnyObject {
        let sectionInfo: RLMFetchedResultsSectionInfo = self.sections![indexPath.section]
        return sectionInfo.objects![indexPath.item]
    }
    
    /* Returns the indexPath of a given object.
     */
    func indexPathForObject(object: AnyObject) -> NSIndexPath? {
        for (section, sectionInfo) in self.sections!.enumerate() {
            if let index = sectionInfo.objects?.indexOf({$0 === object}) {
                return NSIndexPath(forItem: index, inSection: section)
            }
        }
        return nil
    }
    
    
    private let queue = dispatch_queue_create("RLM.fetchedResultsController.queue", DISPATCH_QUEUE_SERIAL)
    private class _RLMFetchTask {
        private(set) var isCanceled: Bool
        private(set) var isCompleted: Bool
        
        init() {
            isCanceled = false
            isCompleted = false
        }
        
        func cancel() {
            self.isCanceled = true
        }
        
        func finish() {
            self.isCompleted = true
        }
        
    }
    
    private var _runningTask: _RLMFetchTask?
    
    private var addToken: NotificationToken?
    private var removeToken: NotificationToken?
    func performFetch() throws {
        
        let fetchRequest = self.fetchRequest
        
        guard let type: Object.Type = fetchRequest.type else {
            throw RLMFetchedResultsControllerError.InvalidFetchRequestType
        }
        
        guard let sectionNameKeyPath: String = self.sectionNameKeyPath else {
            throw RLMFetchedResultsControllerError.InvalidSectionNameKeyPath
        }
        
        let realm = try! Realm()
        var results = realm.objects(type)

        // filter
        if let predicate = fetchRequest.predicate {
            results = results.filter(predicate)
        }
        
        // sorted
        if let sortDescriptors = fetchRequest.sortDescriptors {
            results = results.sorted(sortDescriptors)
        }
        
        self.addToken = results.addNotificationBlock { (results, error) in
            
            if error != nil {
                // TODO
                
            }
            
            if self._runningTask != nil {
                self._runningTask?.cancel()
            }
            self.fetch(sectionNameKeyPath)
        }
        
        self.fetch(sectionNameKeyPath)
    }
    
    private func fetch(sectionNameKeyPath: String) {
        _runningTask = _findSectionInfoWithFetchRequest(fetchRequest, exist: { (sectionInfo) in
            
            sectionInfo._numberOfObjects = sectionInfo._numberOfObjects + 1
            
            }, notExist: { (name, sections, results) -> _RLMFetchedResultsSectionInfo in
                
                let fetchRequest: RLMFetchRequest = RLMFetchRequest(type: self.fetchRequest.type) // FIXME
                let sectionPredicate: NSPredicate = NSPredicate(format: "%K == %@", sectionNameKeyPath, name)
                
                if let predicate = self.fetchRequest.predicate {
                    fetchRequest.predicate = NSCompoundPredicate(andPredicateWithSubpredicates: [predicate, sectionPredicate])
                } else {
                    fetchRequest.predicate = sectionPredicate
                }
                
                let sectionInfo: _RLMFetchedResultsSectionInfo = _RLMFetchedResultsSectionInfo(fetchRequest: fetchRequest, name: name)
                return sectionInfo
                
        }) { (sections, error) in
            
            if error != nil {
                print(error)
            }
            
            self.sections = sections.map({$0 as _RLMFetchedResultsSectionInfo})
            self.delegate?.controllerDidChangeContent(self)
        }
    }
    
    private func _findSectionInfoWithFetchRequest(fetchRequest: RLMFetchRequest,
                                           exist:(_RLMFetchedResultsSectionInfo) -> Void,
                                           notExist:(String, [_RLMFetchedResultsSectionInfo], Results<Object>) -> _RLMFetchedResultsSectionInfo,
                                           completion:([_RLMFetchedResultsSectionInfo], RLMFetchedResultsControllerError?) -> Void

        ) -> _RLMFetchTask? {
        
        let task: _RLMFetchTask = _RLMFetchTask()
        
        guard let sectionNameKeyPath = self.sectionNameKeyPath else {
            completion([], RLMFetchedResultsControllerError.InvalidSectionNameKeyPath)
            return nil
        }
        
        guard let type: Object.Type = fetchRequest.type else {
            completion([], RLMFetchedResultsControllerError.InvalidFetchRequestType)
            return nil
        }
        
        dispatch_async(queue) {
            
            let realm = try! Realm()
            
            if task.isCanceled {
                return
            }
            
            var results = realm.objects(type)
            
            // filter
            if let predicate = fetchRequest.predicate {
                results = results.filter(predicate)
            }
            
            // sorted
            if let sortDescriptors = fetchRequest.sortDescriptors {
                results = results.sorted(sortDescriptors)
            }
            
            if task.isCanceled {
                return
            }
            
            var sections: [_RLMFetchedResultsSectionInfo] = []
            
            for (_, object) in results.enumerate() {
                
                if task.isCanceled {
                    break
                }
                
                guard let value: String = object[sectionNameKeyPath]! as? String else {
                    completion([], RLMFetchedResultsControllerError.InvalidSectionNameKeyPath)
                    return
                }
                
                var sectionExist: Bool = false
                var existSectionInfo: _RLMFetchedResultsSectionInfo?
                
                for (_, sectionInfo) in sections.enumerate() {
                    
                    if task.isCanceled {
                        break
                    }
                    
                    if sectionInfo._name == value {
                        existSectionInfo = sectionInfo
                        sectionExist = true
                        break
                    }
                    
                }
                
                if task.isCanceled {
                    break
                }
                
                if sectionExist {
                    exist(existSectionInfo!)
                } else {
                    let sectionInfo: _RLMFetchedResultsSectionInfo = notExist(value, sections, results)
                    sections.append(sectionInfo)
                }
                
            }
            
            if !task.isCanceled {
                dispatch_async(dispatch_get_main_queue(), {
                    completion(sections, nil)
                })
                task.finish()
                self._runningTask = nil
            }
            
        }
    
        return task
    }
    
    // MARK: - Notification
    
    func didChangeResults() {
        self.delegate?.controllerDidChangeContent(self)
    }
}

public enum RLMFetchedResultsChangeType : UInt {
    case Insert
    case Delete
    case Move
    case Update
}

protocol RLMFetchedResultsControllerDelegate {
    /* Notifies the delegate that a fetched object has been changed due to an add, remove, move, or update. Enables RLMFetchedResultsController change tracking.
    	controller - controller instance that noticed the change on its fetched objects
    	anObject - changed object
    	indexPath - indexPath of changed object (nil for inserts)
    	type - indicates if the change was an insert, delete, move, or update
    	newIndexPath - the destination path for inserted or moved objects, nil otherwise
    	
    	Changes are reported with the following heuristics:
     
    	On Adds and Removes, only the Added/Removed object is reported. It's assumed that all objects that come after the affected object are also moved, but these moves are not reported.
    	The Move object is reported when the changed attribute on the object is one of the sort descriptors used in the fetch request.  An update of the object is assumed in this case, but no separate update message is sent to the delegate.
    	The Update object is reported when an object's state changes, and the changed attributes aren't part of the sort keys.
     */
    
    func controller(controller: RLMFetchedResultsController, didChangeObject anObject: AnyObject, atIndexPath indexPath: NSIndexPath?, forChangeType type: RLMFetchedResultsChangeType, newIndexPath: NSIndexPath?)
    
    /* Notifies the delegate of added or removed sections.  Enables RLMFetchedResultsController change tracking.
     
    	controller - controller instance that noticed the change on its sections
    	sectionInfo - changed section
    	index - index of changed section
    	type - indicates if the change was an insert or delete
     
    	Changes on section info are reported before changes on fetchedObjects.
     */
    
    func controller(controller: RLMFetchedResultsController, didChangeSection sectionInfo: RLMFetchedResultsSectionInfo, atIndex sectionIndex: Int, forChangeType type: RLMFetchedResultsChangeType)
    
    /* Notifies the delegate that section and object changes are about to be processed and notifications will be sent.  Enables RLMFetchedResultsController change tracking.
     Clients utilizing a UITableView may prepare for a batch of updates by responding to this method with -beginUpdates
     */
    
    func controllerWillChangeContent(controller: RLMFetchedResultsController)
    
    /* Notifies the delegate that all section and object changes have been sent. Enables RLMFetchedResultsController change tracking.
     Providing an empty implementation will enable change tracking if you do not care about the individual callbacks.
     */
    
    func controllerDidChangeContent(controller: RLMFetchedResultsController)
}


