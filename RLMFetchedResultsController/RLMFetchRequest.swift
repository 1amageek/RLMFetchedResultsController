//
//  RLMFetchRequest.swift
//  RLMFetchedResultsController
//
//  Created by 1amageek on 2016/03/27.
//  Copyright © 2016年 Stamp inc. All rights reserved.
//

import RealmSwift

class RLMFetchRequest {
 
    init(type: Object.Type){
        self.type = type
    }
    
    var type: Object.Type
    var predicate: NSPredicate?
    var sortDescriptors: [SortDescriptor]?
    
}