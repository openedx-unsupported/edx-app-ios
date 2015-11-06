//
//  DiscussionSearchBarDelegate.swift
//  edX
//
//  Created by Ehmad Zubair Chughtai on 02/11/2015.
//  Copyright © 2015 edX. All rights reserved.
//

import UIKit

class DiscussionSearchBarDelegate: NSObject, UISearchBarDelegate {

    private let callback : ((String) -> ())?
    
    init(callback : ((String) -> ())?) {
        self.callback = callback
    }
    
    func searchBarSearchButtonClicked(searchBar: UISearchBar) {
        let text = searchBar.text ?? ""
        if text.stringByTrimmingCharactersInSet(NSCharacterSet.whitespaceCharacterSet()).isEmpty {
            return
        }
        searchBar.resignFirstResponder()
        searchBar.setShowsCancelButton(false, animated: true)
        callback?(text)
    }
    
    func searchBarTextDidBeginEditing(searchBar: UISearchBar) {
        searchBar.setShowsCancelButton(true, animated: true)
    }
    
    
    func searchBarCancelButtonClicked(searchBar: UISearchBar) {
        searchBar.resignFirstResponder()
        searchBar.setShowsCancelButton(false, animated: true)
    }

}
