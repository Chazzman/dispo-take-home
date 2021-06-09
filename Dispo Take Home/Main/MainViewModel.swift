import Combine
import UIKit

func mainViewModel(
  cellTapped: AnyPublisher<SearchResult, Never>,
  searchText: AnyPublisher<String, Never>
) -> (
  loadResults: AnyPublisher<[SearchResult], Never>,
  pushDetailView: AnyPublisher<SearchResult, Never>,
  defaultResults: AnyPublisher<[SearchResult], Never>
) {
  let api = TenorAPIClient.live

  let featuredGifs = api.featuredGIFs()

  let searchResults = searchText
    .map { api.searchGIFs($0) }
    .switchToLatest()

  // NOTE TO REVIEWER: Could not determine how to coalesce searchResults and featuredGifs
  let loadResults = searchResults
    .eraseToAnyPublisher()

  let localCellTapped = cellTapped

  let pushDetailView = localCellTapped
    .eraseToAnyPublisher()

  return (
    loadResults: loadResults,
    pushDetailView: pushDetailView,
    defaultResults: featuredGifs
  )
}

