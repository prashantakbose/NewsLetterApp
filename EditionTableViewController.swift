import UIKit
import Alamofire
import SwiftyJSON

class EditionTableViewController: UITableViewController {
    var editions = [Edition]()
    
    func loaddata(){
        
        Alamofire.request(.GET, "http://178.62.83.50/articlev6.json")
            .responseJSON { response in
                
                //get json from response data
                
                //print (response.data)
                let json = JSON(data: response.data!)
                
                //for loop over json and write all article titles articles array
                
                for (_, subJson) in json["Editions"] {
                    let version = subJson["Version"].string
                    let newsletter = Edition(Version: version!)
                    self.editions.append(newsletter!)
                }
                dispatch_async(dispatch_get_main_queue()) {
                    self.tableView.reloadData()
                }
        }
        
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        loaddata()
    }
//    override func viewWillAppear(animated: Bool) {
//        let name = "EditionScreen"
//        let tracker = GAI.sharedInstance().defaultTracker
//        tracker.set(kGAIScreenName, value: name)
//        
//        let builder = GAIDictionaryBuilder.createScreenView()
//        tracker.send(builder.build() as [NSObject : AnyObject])
//    }
//    
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }
    
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return editions.count
    }
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let Cell = UITableViewCell()
        // Fetches the appropriate article for the data source layout.
        let edition = editions[indexPath.row]
        
        //set cell text label to article name
        Cell.textLabel?.text = edition.Version
        
        let CellImage = UIImage(named: "edition")
        Cell.imageView?.image = CellImage
        return Cell
    }
    
    
    var valueToPass:Int!
    
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        
        
        let indexPath = tableView.indexPathForSelectedRow;
        
        valueToPass = indexPath?.row
        
        self.performSegueWithIdentifier("showEdition", sender: self)
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        
        if segue.identifier == "showEdition" {
            let destination = segue.destinationViewController as! TableViewController
            
            destination.editionName = valueToPass
        }
    }
    
}
