//
//  DiscussionSearchBarDelegate.swift
//  edX
//
//  Created by Ehmad Zubair Chughtai on 02/11/2015.
//  Copyright © 2015 edX. All rights reserved.
//

import UIKit

protocol DiscussionSearchBarCallback {
    func didSearchForText(text : String)
}

class DiscussionSearchBarDelegate: NSObject, UISearchBarDelegate {

    var callback : DiscussionSearchBarCallback?
    
    func searchBarSearchButtonClicked(searchBar: UISearchBar) {
        let text = searchBar.text ?? ""
        if text.stringByTrimmingCharactersInSet(NSCharacterSet.whitespaceCharacterSet()).isEmpty {
            return
        }
        searchBar.resignFirstResponder()
        searchBar.setShowsCancelButton(false, animated: true)
        callback?.didSearchForText(text)
    }
    
    func searchBarTextDidBeginEditing(searchBar: UISearchBar) {
        searchBar.setShowsCancelButton(true, animated: true)
    }
    
    
    func searchBarCancelButtonClicked(searchBar: UISearchBar) {
        searchBar.resignFirstResponder()
        searchBar.setShowsCancelButton(false, animated: true)
    }

}
