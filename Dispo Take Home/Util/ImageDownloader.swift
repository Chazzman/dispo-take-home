//
//  ImageDownloader.swift
//  Dispo Take Home
//
//  Created by Charles Edmundson on 6/8/21.
//

import UIKit
import Combine

enum ImageDownloader {
  static func download(url: URL) -> AnyPublisher<UIImage, Never> {
    return URLSession.shared.dataTaskPublisher(for: url)
      .tryMap { response -> Data in
        guard let httpURLResponse = response.response as? HTTPURLResponse,
              httpURLResponse.statusCode == 200 else {
          throw URLError(.badServerResponse)
        }

        return response.data
      }
      .tryMap { data in
        guard let unwrappedImage = UIImage(data: data) else {
          throw URLError(.cannotDecodeRawData)
        }
        return unwrappedImage
      }
      .replaceError(with: UIImage())
      .eraseToAnyPublisher()
  }
}
