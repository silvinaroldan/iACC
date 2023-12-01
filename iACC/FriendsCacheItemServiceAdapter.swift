//	
// Copyright © Essential Developer. All rights reserved.
//

import Foundation

struct FriendsCacheItemServiceAdapter: ItemService {
    let cache: FriendsCache
    let select: (Friend) -> Void
    
    func loadItems(completion: @escaping (Result<[ItemViewModel], Error>) -> Void) {
        cache.loadFriends { result in
            DispatchQueue.mainAsyncIfNeeded {
                completion(result.map { items in
                    return items.map { friend in
                        ItemViewModel(item: friend) {
                            select(friend)
                        }
                    }
                })
            }
        }
    }
}
