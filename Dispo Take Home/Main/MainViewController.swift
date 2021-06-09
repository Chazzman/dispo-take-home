import Combine
import UIKit

class MainViewController: UIViewController {
  private let imageCellId = "IMAGE_CELL_ID"
  private let cellSpacing: CGFloat = 2
  private var cancellables = Set<AnyCancellable>()
  private let searchTextChangedSubject = PassthroughSubject<String, Never>()
  private let cellTappedPublisher = PassthroughSubject<SearchResult, Never>()
  private var imagesToDisplay: [SearchResult] = []
  private var defaultImagesToDisplay: [SearchResult] = []

  override func viewDidLoad() {
    super.viewDidLoad()
    navigationItem.titleView = searchBar

    let (
      loadResults,
      pushDetailView,
      defaultResults
    ) = mainViewModel(
      cellTapped: cellTappedPublisher.eraseToAnyPublisher(),
      searchText: searchTextChangedSubject.eraseToAnyPublisher()
    )

    loadResults
      .sink { [weak self] results in

        self?.imagesToDisplay = results
        self?.collectionView.reloadData()
        // load search results into data source
      }
      .store(in: &cancellables)

    pushDetailView
      .sink { [weak self] result in
        let detailViewController = DetailViewController(searchResult: result)
        detailViewController.modalPresentationStyle = .fullScreen
        self?.present(detailViewController, animated: true, completion: nil)
      }
      .store(in: &cancellables)

    defaultResults
      .sink { [weak self] results in

        self?.defaultImagesToDisplay = results
        self?.collectionView.reloadData()
        // load search results into data source
      }
      .store(in: &cancellables)
  }

  override func viewWillAppear(_ animated: Bool) {
    super.viewWillAppear(animated)
  }

  override func loadView() {
    view = UIView()
    view.backgroundColor = .systemBackground
    view.addSubview(collectionView)

    collectionView.snp.makeConstraints {
      $0.edges.equalToSuperview()
    }
  }

  private lazy var searchBar: UISearchBar = {
    let searchBar = UISearchBar()
    searchBar.placeholder = "search gifs..."
    searchBar.delegate = self
    return searchBar
  }()

  private var layout: UICollectionViewLayout {
    let layout = UICollectionViewFlowLayout()
    layout.scrollDirection = .vertical
    layout.minimumLineSpacing = cellSpacing
    layout.minimumInteritemSpacing = cellSpacing
    let size = (UIScreen.main.bounds.width / 2) - (cellSpacing / 2)
    layout.itemSize = CGSize(width: size, height: size)
    return layout
  }

  private lazy var collectionView: UICollectionView = {
    let collectionView = UICollectionView(
      frame: .zero,
      collectionViewLayout: layout
    )
    collectionView.backgroundColor = .clear
    collectionView.keyboardDismissMode = .onDrag
    collectionView.delegate = self
    collectionView.dataSource = self
    collectionView.register(UICollectionViewCell.self, forCellWithReuseIdentifier: imageCellId)
    return collectionView
  }()
}

// MARK: UISearchBarDelegate

extension MainViewController: UISearchBarDelegate {
  func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
    searchTextChangedSubject.send(searchText)
  }
}

// MARK: Collection View Delegates

extension MainViewController: UICollectionViewDelegate, UICollectionViewDataSource {
  func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
    return imageSet.count
  }

  func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
    let cell = collectionView.dequeueReusableCell(withReuseIdentifier: imageCellId, for: indexPath)
    cell.subviews.forEach { $0.removeFromSuperview() }
    let imageView = UIImageView(frame: .zero)
    cell.addSubview(imageView)
    imageView.snp.makeConstraints{( $0.edges.equalToSuperview() )}
    imageView.contentMode = .scaleAspectFill
    imageView.clipsToBounds = true
    ImageDownloader
      .download(url: imageSet[indexPath.row].gifUrl)
      .receive(on: DispatchQueue.main)
      .sink { imageView.image = $0 }
      .store(in: &cancellables)
    return cell
  }

  func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
    cellTappedPublisher.send(imageSet[indexPath.row])
  }

  private var imageSet: [SearchResult] { imagesToDisplay.count == 0 ? defaultImagesToDisplay : imagesToDisplay }
}
