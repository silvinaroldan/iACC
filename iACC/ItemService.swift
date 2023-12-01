//	
// Copyright © Essential Developer. All rights reserved.
//

import Foundation

protocol ItemService {
    func loadItems(completion: @escaping (Result<[ItemViewModel], Error>) -> Void)
}

extension ItemService {
    func fallback(_ fallback: ItemService) -> ItemService {
        return ItemServiceWithFallback(primary: self, fallback: fallback)
    }
    
    func retry(_ retryCount: Int) -> ItemService {
        var service: ItemService = self
        for _ in 0..<retryCount {
            service = service.fallback(self)
        }
        return service
    }
}

struct ItemServiceWithFallback: ItemService {
    let primary: ItemService
    let fallback: ItemService
    
    func loadItems(completion: @escaping (Result<[ItemViewModel], Error>) -> Void) {
        primary.loadItems { result in
            switch result {
            case .success:
                completion(result)
            case .failure:
                fallback.loadItems(completion: completion)
            }
        }
    }
}
