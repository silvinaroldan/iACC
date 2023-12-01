//	
// Copyright © Essential Developer. All rights reserved.
//

import Foundation

struct CardsAPIItemServiceAdapter: ItemService {
    let api: CardAPI
    let select: (Card) -> Void
    
    func loadItems(completion: @escaping (Result<[ItemViewModel], Error>) -> Void) {
        api.loadCards { result in
            DispatchQueue.mainAsyncIfNeeded {
                completion(result.map { items in
                    return items.map { card in
                        ItemViewModel(item: card) {
                            self.select(card)
                        }
                    }
                })
            }
        }
    }
}
