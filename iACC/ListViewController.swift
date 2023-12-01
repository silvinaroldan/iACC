//
// Copyright © Essential Developer. All rights reserved.
//

import UIKit

protocol ItemService {
    func loadItems(completion: @escaping (Result<[ItemViewModel], Error>) -> Void)
}



class ListViewController: UITableViewController {
	var items = [ItemViewModel]()
    var service: ItemService?
	
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
		
		if fromCardsScreen {
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
            service?.loadItems(completion: handleAPIResult)
        }
        else if fromCardsScreen {
            CardAPI.shared.loadCards { [weak self] result in
                DispatchQueue.mainAsyncIfNeeded {
                    self?.handleAPIResult(result.map { items in
                        return items.map { card in
                            ItemViewModel(item: card, selection: {
                                self?.select(item: card)
                            })
                        }})
                }
            }
        }
        else if fromSentTransfersScreen || fromReceivedTransfersScreen {
            TransfersAPI.shared.loadTransfers { [weak self] result in
                DispatchQueue.mainAsyncIfNeeded {
                    self?.handleAPIResult(result.map { items in
                        return items
                            .filter {
                                self?.fromSentTransfersScreen ?? false ? $0.isSender : !$0.isSender
                            }
                            .map { transfer in
                                ItemViewModel(
                                    item: transfer,
                                    longDateStyle: self?.longDateStyle ?? false,
                                    selection: {
                                        self?.select(item: transfer)
                                    })
                            }})
                }
            }
        }
    }
	
	private func handleAPIResult(_ result: Result<[ItemViewModel], Error>) {
		switch result {
		case let .success(items):
            self.retryCount = 0
            self.items = items
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
						case let .success(friends):
                            self?.items = friends.map { friend in
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
