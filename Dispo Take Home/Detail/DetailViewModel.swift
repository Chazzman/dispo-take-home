//
//  DetailViewModel.swift
//  Dispo Take Home
//
//  Created by Charles Edmundson on 6/9/21.
//

import Combine
import UIKit

func detailViewModel(searchResult: AnyPublisher<SearchResult, Never>) -> AnyPublisher<[GifInfo], Never> {

  let gifSearchResult = searchResult
    .map { TenorAPIClient.live.gifInfo($0.id) }
    .switchToLatest()
    .eraseToAnyPublisher()

  return gifSearchResult
}

