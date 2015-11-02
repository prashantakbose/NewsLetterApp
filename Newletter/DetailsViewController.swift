//
//  DetailsViewController.swift
//  Newletter
//
//  Created by Prashanta Kumar Bose on 30/10/2015.
//  Copyright © 2015 ltlcreation. All rights reserved.
//

import UIKit

class DetailsViewController: UIViewController {
    
    @IBOutlet weak var DetailsViewer: UITextView!
    //@IBOutlet weak var TitleofArt: UILabel!
    //@IBOutlet weak var Images: UIImageView!
    //@IBOutlet weak var AuthorName: UILabel!
    
    var ATsegue: Article?
    
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        if let article = ATsegue {
        DetailsViewer.text = article.content
            //TitleofArt.text = article.title
            //Images.image = UIImage(named: (article.image))
            //AuthorName.text = "By " + article.author
        }
        
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
