import UIKit
import Alamofire
import SwiftyJSON

class TableViewController: UITableViewController {
    
    var editionName: Int?
    
    var articles = [Article]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.navigationItem.title = "Articles"
        self.navigationController!.navigationBar.barTintColor = UIColor.myNavColor()
        
        if editionName != nil
        {
            loaddata(editionName!)
        }
        self.tableView.rowHeight = 45.0
    }
    
    func loaddata(rowIndex: Int){
        
        Alamofire.request(.GET, "https://s3-eu-west-1.amazonaws.com/channels-newsletter-assets/json/article.json")
            .responseJSON { response in
                
                //get json from response data
                let json = JSON(data: response.data!)
                
                
                func looping(Number: Int){
                    
                    
                    
                    for (_, subJson) in json["Editions"][Number]["Articles"]{
                        
                        
                        let author = subJson["title"].string
                        let subheading = subJson["subheading"].string
                        let content = subJson["content"].string
                        let Author = subJson["author"].string
                        let Image = subJson["image"].string
                        let newsletter = Article(name: author!, subheading: subheading!, content: content!, author: Author!, image: Image!)
                        
                        
                        self.articles.append(newsletter!)
                        
                        //end loop
                    }
                    //end looping
                }
                
                looping(rowIndex)
                
                dispatch_async(dispatch_get_main_queue()) {
                    self.tableView.reloadData()
                }
        }
        
    }
    override func viewWillAppear(animated: Bool) {
        let name = "ArticleScreen"
        let tracker = GAI.sharedInstance().defaultTracker
        tracker.set(kGAIScreenName, value: name)
        
        let builder = GAIDictionaryBuilder.createScreenView()
        tracker.send(builder.build() as [NSObject : AnyObject])
        if let row = tableView.indexPathForSelectedRow {
            self.tableView.deselectRowAtIndexPath(row, animated: false)
        }
    }
    
    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }
    
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return articles.count
    }
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("cell", forIndexPath: indexPath) as UITableViewCell
        // Fetches the appropriate article for the data source layout.
        let article = articles[indexPath.row]
        
        //set cell text label to article name
        cell.textLabel?.text = article.name
        cell.detailTextLabel?.text = article.author
        
        cell.textLabel!.highlightedTextColor = UIColor.whiteColor()
        cell.detailTextLabel?.highlightedTextColor = UIColor.whiteColor()
        
        let myCustomSelectionColorView = UIView()
        myCustomSelectionColorView.backgroundColor = UIColor.myBlueColor()
        cell.selectedBackgroundView = myCustomSelectionColorView
        
        return cell
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        
        if segue.identifier == "showDetailsView" {
            let destination = segue.destinationViewController as! DetailsViewController
            if let articles = sender as? Article {
                destination.ATsegue = articles
            }
        }
    }
    
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        let article = articles[indexPath.row]
        self.performSegueWithIdentifier("showDetailsView", sender: article)
    }
    
    
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
}
