import UIKit
import Alamofire
import SwiftyJSON

extension UIColor
{
    class func myBlueColor() -> UIColor
    {
        return UIColor(red:0.00, green:0.68, blue:0.94, alpha:1.0)/*#00aeef*/
    }
    class func myNavColor() -> UIColor
    {
        return UIColor(red:0.01, green:0.17, blue:0.35, alpha:1.0)/*#022b59*/
    }
}

class EditionTableViewController: UITableViewController {
    var editions = [Edition]()
    
    func loaddata(){
        
        Alamofire.request(.GET, "https://s3-eu-west-1.amazonaws.com/channels-newsletter-assets/json/article.json")
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
        self.navigationItem.title = "PlayBack"
        self.navigationController!.navigationBar.barTintColor = UIColor.myNavColor()
        self.navigationController!.navigationBar.titleTextAttributes = [NSForegroundColorAttributeName : UIColor.whiteColor()]
        loaddata()
        self.tableView.rowHeight = 45.0
        
    }
    override func viewWillAppear(animated: Bool) {
        let name = "EditionScreen"
        let tracker = GAI.sharedInstance().defaultTracker
        tracker.set(kGAIScreenName, value: name)
        
        let builder = GAIDictionaryBuilder.createScreenView()
        tracker.send(builder.build() as [NSObject : AnyObject])
        if let row = tableView.indexPathForSelectedRow {
            self.tableView.deselectRowAtIndexPath(row, animated: false)
        }
    }
    
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
        // New
        let Cell = tableView.dequeueReusableCellWithIdentifier("Cell", forIndexPath: indexPath) as UITableViewCell
        // let Cell = UITableViewCell()
        
        // Fetches the appropriate article for the data source layout.
        let edition = editions[indexPath.row]
        
        //set cell text label to article name
        Cell.textLabel?.text = edition.Version
        
        Cell.textLabel!.highlightedTextColor = UIColor.whiteColor()

        let myCustomSelectionColorView = UIView()
        myCustomSelectionColorView.backgroundColor = UIColor.myBlueColor()
        Cell.selectedBackgroundView = myCustomSelectionColorView

        return Cell
        
    }
   
    
    var valueToPass:Int!
    
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
            let Cell = UITableViewCell()
        let CellImage = UIImage(named: "Calendar_Wht")
        Cell.imageView?.image = CellImage
        
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
