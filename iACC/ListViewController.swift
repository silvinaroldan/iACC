//
// Copyright © Essential Developer. All rights reserved.
//

import UIKit

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

class ListViewController: UITableViewController {
	var items = [ItemViewModel]()
	
	var retryCount = 0
	var maxRetryCount = 0
	var shouldRetry = false
	
	var longDateStyle = false
	
	var fromReceivedTransfersScreen = false
	var fromSentTransfersScreen = false
	var fromCardsScreen = false
	var fromFriendsScreen = false
	
	override func viewDidLoad() {
		super.viewDidLoad()
		
		refreshControl = UIRefreshControl()
		refreshControl?.addTarget(self, action: #selector(refresh), for: .valueChanged)
		
		if fromFriendsScreen {
			shouldRetry = true
			maxRetryCount = 2
			
			title = "Friends"
			navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .add, target: self, action: #selector(addFriend))
			
		} else if fromCardsScreen {
			shouldRetry = false
			
			title = "Cards"
			navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .add, target: self, action: #selector(addCard))
			
		} else if fromSentTransfersScreen {
			shouldRetry = true
			maxRetryCount = 1
			longDateStyle = true

			navigationItem.title = "Sent"
			navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Send", style: .done, target: self, action: #selector(sendMoney))

		} else if fromReceivedTransfersScreen {
			shouldRetry = true
			maxRetryCount = 1
			longDateStyle = false
			
			navigationItem.title = "Received"
			navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Request", style: .done, target: self, action: #selector(requestMoney))
		}
	}
	
	override func viewDidAppear(_ animated: Bool) {
		super.viewDidAppear(animated)
		
		if tableView.numberOfRows(inSection: 0) == 0 {
			refresh()
		}
	}
	
	@objc private func refresh() {
		refreshControl?.beginRefreshing()
		if fromFriendsScreen {
			FriendsAPI.shared.loadFriends { [weak self] result in
				DispatchQueue.mainAsyncIfNeeded {
					self?.handleAPIResult(result)
				}
			}
		} else if fromCardsScreen {
			CardAPI.shared.loadCards { [weak self] result in
				DispatchQueue.mainAsyncIfNeeded {
					self?.handleAPIResult(result)
				}
			}
		} else if fromSentTransfersScreen || fromReceivedTransfersScreen {
			TransfersAPI.shared.loadTransfers { [weak self] result in
				DispatchQueue.mainAsyncIfNeeded {
					self?.handleAPIResult(result)
				}
			}
		}
	}
	
	private func handleAPIResult<T>(_ result: Result<[T], Error>) {
		switch result {
		case let .success(items):
            self.retryCount = 0
                if let friends = items as? [Friend] {
                    if fromFriendsScreen && User.shared?.isPremium == true {
                        (UIApplication.shared.connectedScenes.first?.delegate as! SceneDelegate).cache.save(friends)
                    }
                    
                    self.items = friends.map { friend in
                        ItemViewModel(item: friend) {
                            self.select(item: friend) }
                    }
            }
            
            else if let transfers = items as? [Transfer] {
                self.items = transfers
                    .filter { fromSentTransfersScreen ? $0.isSender : !$0.isSender }
                    .map { transfer in
                        ItemViewModel(item: transfer, longDateStyle: longDateStyle) {
                            self.select(item: transfer)
                        }
                    }
            }
			
            else if let cards = items as? [Card] {
                self.items = cards.map { card in
                    ItemViewModel(item: card) {
                        self.select(item: card)
                    }
                }
            }
            
            self.refreshControl?.endRefreshing()
            self.tableView.reloadData()
		case let .failure(error):
			if shouldRetry && retryCount < maxRetryCount {
				retryCount += 1
				
				refresh()
				return
			}
			
			retryCount = 0
			if fromFriendsScreen && User.shared?.isPremium == true {
				(UIApplication.shared.connectedScenes.first?.delegate as! SceneDelegate).cache.loadFriends { [weak self] result in
					DispatchQueue.mainAsyncIfNeeded {
						switch result {
						case let .success(items):
                            self?.items = items.map { friend in
                                ItemViewModel(item: friend) {
                                    self?.select(item: friend) }
                            }
                            self?.tableView.reloadData()
                            
                        case let .failure(error):
                            self?.showError(error)
                        }
                    }
                }
            } else {
                showError(error)
            }
        }
        self.refreshControl?.endRefreshing()
	}
    
	override func numberOfSections(in tableView: UITableView) -> Int {
		1
	}
	
	override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
		items.count
	}
	
	override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
		let item = items[indexPath.row]
		let cell = tableView.dequeueReusableCell(withIdentifier: "ItemCell") ?? UITableViewCell(style: .subtitle, reuseIdentifier: "ItemCell")
		cell.configure(item, longDateStyle: longDateStyle)
		return cell
	}
	
	override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
		let item = items[indexPath.row]
        
        item.select()
	}
}



extension UITableViewCell {
	func configure(_ item: ItemViewModel, longDateStyle: Bool) {
        textLabel?.text = item.title
        detailTextLabel?.text = item.subtitle
	}
}
