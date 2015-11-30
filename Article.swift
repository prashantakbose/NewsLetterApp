
class Article {
    // MARK: Properties
    
    var name: String
    var subheading: String
    var content: String
    var author: String
    var image: String
    //    var localFileLocation: String
    
    // MARK: Initialization
    
    init?(name: String, subheading: String, content: String, author: String, image: String/*, localFileLocation:String*/) {
        // Initialize stored properties.
        self.name = name
        self.subheading = subheading
        self.content = content
        self.author = author
        self.image = image
        //        self.localFileLocation = localFileLocation
        
        
        // Initialization should fail if there is no name or if the rating is negative.
        if name.isEmpty {
            return nil
        }
    }
    
}