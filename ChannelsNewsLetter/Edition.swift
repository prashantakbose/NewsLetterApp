
class Edition {
    // MARK: Properties
    
    var Version: String
    
    
    // MARK: Initialization
    
    init?(Version: String) {
        // Initialize stored properties.
        self.Version = Version
        
        
        
        // Initialization should fail if there is no name or if the rating is negative.
        if Version.isEmpty {
            return nil
        }
    }
    
}