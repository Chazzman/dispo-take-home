import Combine
import UIKit

struct TenorAPIClient {
  var gifInfo: (_ gifId: String) -> AnyPublisher<[GifInfo], Never>
  var searchGIFs: (_ query: String) -> AnyPublisher<[SearchResult], Never>
  var featuredGIFs: () -> AnyPublisher<[SearchResult], Never>
}

// MARK: - Live Implementation

extension TenorAPIClient {
  static let live = TenorAPIClient(
    gifInfo: { gifId in
      guard var unwrappedComponents = URLComponents(
        url: URL(string: "https://g.tenor.com/v1/gifs")!,
        resolvingAgainstBaseURL: false
      ) else {
        return Empty().eraseToAnyPublisher()
      }
      unwrappedComponents.queryItems = [
        .init(name: "ids", value: gifId),
        .init(name: "key", value: Constants.tenorApiKey),
        .init(name: "media_filter", value: "minimal")
      ]
      guard let unwrappedUrl = unwrappedComponents.url else {
        return Empty().eraseToAnyPublisher()
      }
      return URLSession.shared.dataTaskPublisher(for: unwrappedUrl)
        // NOTE TO REVIEWER: THIS NEVER RETURNS!! URL is correct and parameters are correct
        .tryMap { element -> Data in
          guard let httpResponse = element.response as? HTTPURLResponse,
                httpResponse.statusCode == 200 else {
            throw URLError(.badServerResponse)
          }
          return element.data
        }
        .decode(type: GifResponse.self, decoder: JSONDecoder())
        .map { response in
          response.results.map {
            GifInfo(
              id: $0.id,
              gifUrl: $0.url,
              text: $0.title,
              shares: $0.shares,
              tags: $0.tags
            )
          }
        }
        .replaceError(with: [])
        .share()
        .receive(on: DispatchQueue.main)
        .eraseToAnyPublisher()
    },
    searchGIFs: { query in
      var components = URLComponents(
        url: URL(string: "https://g.tenor.com/v1/search")!,
        resolvingAgainstBaseURL: false
      )!
      components.queryItems = [
        .init(name: "q", value: query),
        .init(name: "key", value: Constants.tenorApiKey),
        .init(name: "limit", value: "30"),
      ]
      let url = components.url!

      return URLSession.shared.dataTaskPublisher(for: url)
        .tryMap { element -> Data in
          guard let httpResponse = element.response as? HTTPURLResponse,
                httpResponse.statusCode == 200 else {
            throw URLError(.badServerResponse)
          }
          return element.data
        }
        .decode(type: APIListResponse.self, decoder: JSONDecoder())
        .map { response in
          response.results.map {
            SearchResult(
              id: $0.id,
              gifUrl: $0.media[0].gif.url,
              text: $0.h1_title ?? "no title"
            )
          }
        }
        .replaceError(with: [])
        .share()
        .receive(on: DispatchQueue.main)
        .eraseToAnyPublisher()
    },
    featuredGIFs: {
      var components = URLComponents(
        url: URL(string: "https://g.tenor.com/v1/trending")!,
        resolvingAgainstBaseURL: false
      )!
      components.queryItems = [
        .init(name: "key", value: Constants.tenorApiKey),
        .init(name: "limit", value: "30"),
      ]
      let url = components.url!

      return URLSession.shared.dataTaskPublisher(for: url)
        .tryMap { element -> Data in
          guard let httpResponse = element.response as? HTTPURLResponse,
                httpResponse.statusCode == 200 else {
            throw URLError(.badServerResponse)
          }
          return element.data
        }
        .decode(type: APIListResponse.self, decoder: JSONDecoder())
        .map { response in
          response.results.map {
            SearchResult(
              id: $0.id,
              gifUrl: $0.media[0].gif.url,
              text: $0.h1_title ?? "no title"
            )
          }
        }
        .replaceError(with: [])
        .share()
        .receive(on: DispatchQueue.main)
        .eraseToAnyPublisher()
    }
  )
}

private struct APIListResponse: Codable {
  var results: [Result]

  struct Result: Codable {
    var id: String
    var h1_title: String?
    var media: [Media]

    struct Media: Codable {
      var gif: MediaData

      struct MediaData: Codable {
        var url: URL
      }
    }
  }
}

private struct GifResponse: Codable {
  var results: [Result]

  struct Result: Codable {
    var tags: [String]
    var url: String
    var media: [Media]
    var created: Double
    var shares: Int
    var itemurl: String
    var title: String
    var id: String

    struct Media: Codable {
      var gif: MediaData

      struct MediaData: Codable {
        var url: URL
      }
    }
  }
}
