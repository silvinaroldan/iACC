//	
// Copyright © Essential Developer. All rights reserved.
//

import UIKit


extension UIViewController {
    @objc func addCard() {
        show(AddCardViewController(), sender: self)
    }
    
    @objc func addFriend() {
        show(AddFriendViewController(), sender: self)
    }
    
    @objc func sendMoney() {
        show(SendMoneyViewController(), sender: self)
    }
    
    @objc func requestMoney() {
        show(RequestMoneyViewController(), sender: self)
    }
    
    func select(item: Friend) {
        let vc = FriendDetailsViewController()
        vc.friend = item
        self.show(vc, sender: self)
    }
    
    func select(item: Transfer) {
        let vc = TransferDetailsViewController()
        vc.transfer = item
        self.show(vc, sender: self)
    }
    
    func select(item: Card) {
        let vc = CardDetailsViewController()
        vc.card = item
        self.show(vc, sender: self)
    }
    
    func showError(_ error: Error) {
        let alert = UIAlertController(title: "Error", message: error.localizedDescription, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Ok", style: .default))
        self.showDetailViewController(alert, sender: self)
    }
}
