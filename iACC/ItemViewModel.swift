//	
// Copyright © Essential Developer. All rights reserved.
//

import Foundation

class ItemViewModel {
    typealias Action = () -> Void
    let title: String
    let subtitle: String
    let selection: Action
    
    init(item: Friend, selection: @escaping Action) {
        self.title = item.name
        self.subtitle = item.phone
        self.selection = selection
    }
    
    init(item: Card, selection: @escaping Action) {
        self.title = item.number
        self.subtitle = item.holder
        self.selection = selection
    }
    
    init(item: Transfer, longDateStyle: Bool, selection: @escaping Action) {
        let numberFormatter = Formatters.number
        numberFormatter.numberStyle = .currency
        numberFormatter.currencyCode = item.currencyCode
        
        let amount = numberFormatter.string(from: item.amount as NSNumber)!
        self.title = "\(amount) • \(item.description)"
        
        let dateFormatter = Formatters.date
        if longDateStyle {
            dateFormatter.dateStyle = .long
            dateFormatter.timeStyle = .short
            self.subtitle = "Sent to: \(item.recipient) on \(dateFormatter.string(from: item.date))"
        } else {
            dateFormatter.dateStyle = .short
            dateFormatter.timeStyle = .short
            self.subtitle = "Received from: \(item.sender) on \(dateFormatter.string(from: item.date))"
        }
        
        self.selection = selection
    }
    
    func select() {
        selection()
    }
}
