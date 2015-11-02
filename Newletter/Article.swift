//
//  Article.swift
//  Newletter
//
//  Created by Luke Langfield on 27/10/2015.
//  Copyright © 2015 ltlcreation. All rights reserved.
//

class Article {
    // MARK: Properties
    
    var name: String
    var subheading: String
    var content: String
    var author: String
  
    
    // MARK: Initialization
    
    init?(name: String, subheading: String, content: String, author: String) {
        // Initialize stored properties.
        self.name = name
        self.subheading = subheading
        self.content = content
        self.author = author
 
        
        // Initialization should fail if there is no name or if the rating is negative.
        if name.isEmpty {
            return nil
        }
    }
    
}