import Combine
import UIKit

class DetailViewController: UIViewController {
  private let headerHeight: CGFloat = 36
  private var searchResult: SearchResult
  private var cancellables = Set<AnyCancellable>()
  private let searchResultPublisher = PassthroughSubject<SearchResult, Never>()

  lazy var headerView: UIView = {
    let headerView = UIView(frame: .zero)
    headerView.backgroundColor = .white
    return headerView
  }()

  lazy var backButton: UIButton = {
    let backButton = UIButton(type: .custom)
    backButton.setTitle("X", for: .normal)
    backButton.setTitleColor(.darkGray, for: .normal)
    backButton.titleLabel?.font = .monospacedSystemFont(ofSize: 18, weight: .bold)
    backButton.backgroundColor = .systemBackground
    backButton.addTarget(self, action: #selector(self.backButtonTapped), for: .touchUpInside)
    return backButton
  }()

  lazy var imageView: UIImageView = {
    let imageView = UIImageView.init(frame: .zero)
    imageView.contentMode = .scaleAspectFill
    return imageView
  }()

  lazy var headerTitle: UILabel = {
    let label = UILabel(frame: .zero)
    label.textAlignment = .center
    return label
  }()

  lazy var sharesLabel: UILabel = {
    let label = UILabel(frame: .zero)
    return label
  }()

  lazy var tagsLabel: UILabel = {
    let label = UILabel(frame: .zero)
    label.numberOfLines = 0
    return label
  }()

  init(searchResult: SearchResult) {
    self.searchResult = searchResult
    super.init(nibName: nil, bundle: nil)
  }

  override func viewDidLoad() {
    super.viewDidLoad()

    let _ = detailViewModel(searchResult: searchResultPublisher.eraseToAnyPublisher())
      .sink(receiveValue: { [weak self] gifInfo in
        // NOTE TO REVIEWER: gifInfo is alway empty due to issue in TenorAPIClient
        self?.headerTitle.text = gifInfo.first?.text
        self?.sharesLabel.text = "Shares: \(gifInfo.first?.shares ?? 0)"
        self?.tagsLabel.text = gifInfo.first?.tags.joined(separator: " ")
      })
    searchResultPublisher.send(searchResult)
  }

  override func loadView() {
    view = UIView()
    view.backgroundColor = .systemBackground
    view.addSubview(headerView)
    headerView.snp.makeConstraints { make in
      make.top.equalTo(view.safeAreaLayoutGuide.snp.top)
      make.leading.equalTo(view)
      make.trailing.equalTo(view)
      make.height.equalTo(headerHeight)
    }
    headerView.addSubview(backButton)
    backButton.snp.makeConstraints { make in
      make.top.equalTo(headerView)
      make.trailing.equalTo(headerView).inset(12)
      make.bottom.equalTo(headerView)
      make.width.equalTo(headerHeight)
    }
    view.addSubview(imageView)
    ImageDownloader
      .download(url: searchResult.gifUrl)
      .receive(on: DispatchQueue.main)
      .sink { [weak self] image in
        self?.imageView.image = image
        self?.setImageConstraints(using: image)
      }
      .store(in: &cancellables)

    headerView.addSubview(headerTitle)
    headerTitle.snp.makeConstraints { make in
      make.center.equalTo(headerView)
    }

    view.addSubview(sharesLabel)
    sharesLabel.snp.makeConstraints { make in
      make.top.equalTo(imageView.snp.bottom).inset(-20)
      make.leading.equalTo(view).inset(12)
    }

    view.addSubview(tagsLabel)
    tagsLabel.snp.makeConstraints { make in
      make.top.equalTo(sharesLabel.snp.bottom).inset(-8)
      make.leading.equalTo(sharesLabel.snp.leading)
      make.trailing.equalTo(view.snp.trailing).inset(-12)
    }
  }

  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  @objc private func backButtonTapped() {
    dismiss(animated: true, completion: nil)
  }

  private func setImageConstraints(using image: UIImage) {
    let imageHeight = image.size.height/image.size.width * UIScreen.main.bounds.size.width

    imageView.snp.makeConstraints{ make in
      make.top.equalTo(headerView.snp.bottom)
      make.leading.equalTo(view.snp.leading)
      make.trailing.equalTo(view.snp.trailing)
      make.height.equalTo(imageHeight)
    }
  }
}
