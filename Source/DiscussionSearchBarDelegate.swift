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
    
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        let text = searchBar.text ?? ""
        if text.trimmingCharacters(in: NSCharacterSet.whitespaces).isEmpty {
            return
        }
        searchBar.resignFirstResponder()
        searchBar.setShowsCancelButton(false, animated: true)
        callback?(text)
    }
    
    func searchBarTextDidBeginEditing(_ searchBar: UISearchBar) {
        searchBar.setShowsCancelButton(true, animated: true)
    }
    
    
    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        searchBar.resignFirstResponder()
        searchBar.setShowsCancelButton(false, animated: true)
    }

}
