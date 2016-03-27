//
//  RLMFetchedResultsController.swift
//  RLMFetchedResultsController
//
//  Created by 1amageek on 2016/03/26.
//  Copyright © 2016年 Stamp inc. All rights reserved.
//

import RealmSwift

protocol RLMFetchedResultsSectionInfo {
    func name() -> String
    func indexTitle() -> String?
    func numberOfObjects() -> Int
    func objects() -> [AnyObject]?
}

class _RLMFetchedResultsSectionInfo: NSObject, RLMFetchedResultsSectionInfo {

    override init() {
        super.init()
    }
    
    convenience init(type: Object.Type, sectionNameKeyPath: AnyObject) {
        self.init()
        let results = try! Realm().objects(type)
    }
    
    func compare(sectionNameKeyPath: String, value: AnyObject) -> Bool {
        return true
    }

    func name() -> String {
        return ""
    }
    
    func indexTitle() -> String? {
        return ""
    }
    
    func numberOfObjects() -> Int {
        return 0
    }
    
    func objects() -> [AnyObject]? {
        
        
        
        return []
    }
    
}

class RLMFetchedResultsController: NSObject {
    
    var sections: [RLMFetchedResultsSectionInfo]?
    var fetchRequest: RLMFetchRequest
    var sectionNameKeyPath: String?
    var fetchedObjects: [AnyObject]?
    
    private let queue = dispatch_queue_create("RLM.fetchedResultsController.queue", DISPATCH_QUEUE_SERIAL)
    
    init(fetchRequest: RLMFetchRequest, sectionNameKeyPath: String) {
        self.fetchRequest = fetchRequest
        self.sectionNameKeyPath = sectionNameKeyPath
    }
    
    
    var token: NotificationToken
    func performFetch() {
        let fetchRequest = self.fetchRequest
        let predicate = fetchRequest.predicate!
        let sortDescriptors = fetchRequest.sortDescriptors!
        
        let results = try! Realm().objects(fetchRequest.type).filter(predicate).sorted(sortDescriptors)
        self.token = results.addNotificationBlock { (results, error) in
            if error != nil {
                // TODO
                
                return
            }
            
            self.didChangeResults()
            
        }
        
        _findSectionInfoInObjects(results, exist: { (sectionInfo) in
                // TODO
            }, notExist: { (object, sections) -> _RLMFetchedResultsSectionInfo in
                // TODO
            }) { (sections) in
                // TODO
        }
    }
    
    private class _RLMFetchTask {
        private(set) var isCanceled: Bool
        
        init() {
            isCanceled = false
        }
        
        func cancel() {
            self.isCanceled = true
        }
        
    }
    
    private var _runningTask: _RLMFetchTask?
    private func _findSectionInfoInObjects(objects: Results<Object>,
                                           exist:(_RLMFetchedResultsSectionInfo) -> Void,
                                           notExist:(Object, [_RLMFetchedResultsSectionInfo]) -> _RLMFetchedResultsSectionInfo,
                                           completion:([_RLMFetchedResultsSectionInfo]) -> Void
        ) -> _RLMFetchTask? {
        
        let task: _RLMFetchTask = _RLMFetchTask()
        guard let sectionNameKeyPath = self.sectionNameKeyPath else {
            return nil
        }
        
        dispatch_async(queue) {
            
            let sections: [_RLMFetchedResultsSectionInfo]
            
            for (_, object) in objects.enumerate() {
                
                if task.isCanceled {
                    break
                }
                
                let value: AnyObject = object[sectionNameKeyPath]!
                
                var sectionExist: Bool = false
                var existSectionInfo: _RLMFetchedResultsSectionInfo?
                
                for (_, sectionInfo) in sections.enumerate() {
                    
                    if task.isCanceled {
                        break
                    }
                    
                    if sectionInfo.compare(sectionNameKeyPath, value: value) {
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
                    let sectionInfo: _RLMFetchedResultsSectionInfo = notExist(object, sections)
                    sections.append(sectionInfo)
                }
                
            }
            
            if !task.isCanceled {
                dispatch_async(dispatch_get_main_queue(), {
                    completion(sections)
                })
            }
        
        }
        
        return task
    }
    
    // MARK: - Notification
    
    func didChangeResults() {
        
    }
}




