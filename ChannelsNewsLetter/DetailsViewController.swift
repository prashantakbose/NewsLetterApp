

import UIKit

extension String {
    var ns: NSString {
        return self as NSString
    }
    var pathExtension: String? {
        return ns.pathExtension
    }
    var lastPathComponent: String? {
        return ns.lastPathComponent
    }
}

class DetailsViewController: UIViewController, UITextViewDelegate{
    
    @IBOutlet weak var TitleofArt: UILabel!
    
    @IBOutlet weak var heightConstraint: NSLayoutConstraint!
    @IBOutlet weak var DetailsViewer: UITextView!
    @IBOutlet weak var Images: UIImageView!
    @IBOutlet weak var AuthorName: UILabel!
    
    var ATsegue: Article?
    
    func getDocumentsDirectory() -> NSString {
        let paths = NSSearchPathForDirectoriesInDomains(.DocumentDirectory, .UserDomainMask, true)
        let documentsDirectory = paths[0]
        return documentsDirectory
    }
    
    override func viewWillAppear(animated: Bool) {
        if let article = ATsegue {
            DetailsViewer.text = article.content
            TitleofArt.text = article.name
            AuthorName.text = "Article Written By " + article.author
            
            let pathComp = article.image.lastPathComponent
            
            let filename = self.getDocumentsDirectory().stringByAppendingPathComponent(pathComp!)
            let checkValidation = NSFileManager.defaultManager()
            if (checkValidation.fileExistsAtPath(filename))
            {
                self.Images.image = UIImage(contentsOfFile: filename)
            }
            else
            {
                
                dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), { () -> Void in
                    let data = NSData(contentsOfURL: NSURL(string: article.image)!)
                    if data != nil {                        
                        dispatch_async(dispatch_get_main_queue()) {
                            
                            if let image = UIImage(data: data!) {
                                if let data = UIImagePNGRepresentation(image) {
                                    self.Images.image = image
                                    data.writeToFile(filename, atomically: true)
                                }
                            }
                            
                        }
                    }
                })
                
            }
            
        }
//            let name = "DetailScreen"
//            let tracker = GAI.sharedInstance().defaultTracker
//            tracker.set(kGAIScreenName, value: name)
//            
//            let builder = GAIDictionaryBuilder.createScreenView()
//            tracker.send(builder.build() as [NSObject : AnyObject])
        
        let fixedWidth = DetailsViewer.frame.size.width
        DetailsViewer.sizeThatFits(CGSize(width: fixedWidth, height: CGFloat.max))
        let newSize = DetailsViewer.sizeThatFits(CGSize(width: fixedWidth, height: CGFloat.max))
        var newFrame = DetailsViewer.frame
        newFrame.size = CGSize(width: max(newSize.width, fixedWidth), height: newSize.height)
        DetailsViewer.frame = newFrame
        heightConstraint.constant = newFrame.height + 80
        DetailsViewer.delegate = self
//        print(DetailsViewer)
//        DetailsViewer.sizeToFit()
        
//        func TextViewDidEndEditing(DetailsViewer: UITextView) -> Bool {
//        DetailsViewer.frame.size.height = 1
//        DetailsViewer.frame.size = DetailsViewer.sizeThatFits(CGSizeZero)
//        
//    return true
//    }
//        print("Test")
    }

  
  
    override func viewDidAppear(animated: Bool) {
        // super.viewDidAppear(animated)
        
    }
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Do any additional setup after loading the view.
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    override func touchesBegan(touches: Set<UITouch>, withEvent event: UIEvent?) {
        self.view.endEditing(true)
    }
    
}
