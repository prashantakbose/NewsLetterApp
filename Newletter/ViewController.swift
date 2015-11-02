//
//  ViewController.swift
//  Newletter
//
//  Created by Luke Langfield on 14/10/2015.
//  Copyright © 2015 ltlcreation. All rights reserved.
//

import UIKit
import Alamofire
import SwiftyJSON




class ViewController: UIViewController, UITableViewDataSource{
    
    @IBOutlet weak var tableview: UITableView!
    var articles = [Article]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Do any additional setup after loading the view, typically from a nib.
        
        //get data from network call
        loaddata()
     
        //end view did load
    }
    
    func loaddata(){
        
        Alamofire.request(.GET, "http://178.62.83.50/article.json")
            .responseJSON { response in
                
                //get json from response data
                let json = JSON(data: response.data!)
                //print(json)
                
                //for loop over json and write all article titles articles array
                
                for (key, subJson) in json["Articles"] {
                    
                    
                    
                    let author = subJson["title"].string
                    let subheading = subJson["subheading"].string
                    let content = subJson["content"].string
                    let Author = subJson["author"].string
                    
                    let stuff = Article(name: author!, subheading: subheading!, content: content!, author: Author!)
                    
                    
                        self.articles.append(stuff!)
                        
                        //end iff
                    
                    //if let content = subJson["content"].string {
                    // self.Content.append(content)
                    
                    //}
                    
                    //end for
                }
                
                dispatch_async(dispatch_get_main_queue(), {
                    [unowned self] in
                    self.tableview.reloadData()
                    })
                
        }
        
        }
    
    
    
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        //let num = articles.count
       // print(num)
        //return number of rows
        return articles.count
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = UITableViewCell()
        
        //let (artTitle) = articles[indexPath.row]
        
        // Fetches the appropriate article for the data source layout.
        let article = articles[indexPath.row]
        
        //set cell text label to article name
        cell.textLabel?.text = article.name
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
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        print("tapped")
        let article = articles[indexPath.row]
        self.performSegueWithIdentifier("showDetailsView", sender: article)
    }

    
   
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
 
  
    //end of class
    }



