# RLMFetchedResultsController

RLMFetchedResultsController is FetchedResultsController to operate in realm.
This can make the Section by setting the sectionNameKeyPath in the same way as NSFetchedResultsController.

## Usage

You can easily use if you know how to use the NSFetchedResultsController.
However, `performFetch` is to operate in the background, you need to implement `controllerDidChangeContent`.

``` swift

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

```

``` swift
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
```

``` swift
    func controllerDidChangeContent(controller: RLMFetchedResultsController) {
        self.tableView.reloadData()
    }
```

## Warnning

It has not been able to implement the next Function

``` swift
    func controllerWillChangeContent(controller: RLMFetchedResultsController) {
        // TODO
    }
    
    func controller(controller: RLMFetchedResultsController, didChangeSection sectionInfo: RLMFetchedResultsSectionInfo, atIndex sectionIndex: Int, forChangeType type: RLMFetchedResultsChangeType) {
        // TODO
    }
    
    func controller(controller: RLMFetchedResultsController, didChangeObject anObject: AnyObject, atIndexPath indexPath: NSIndexPath?, forChangeType type: RLMFetchedResultsChangeType, newIndexPath: NSIndexPath?) {
        // TOOD
    }

``` 
