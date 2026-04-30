import UIKit
import MuPDFMobile

/// A full-screen UICollectionView that shows page thumbnails for a document.
///
/// Tap any thumbnail to jump to that page in the viewer.
final class ThumbnailViewController: UIViewController {

    // MARK: - Dependencies

    private let document: MuPDFDocument
    private var onPageSelected: ((Int) -> Void)?

    init(document: MuPDFDocument, onPageSelected: @escaping (Int) -> Void) {
        self.document = document
        self.onPageSelected = onPageSelected
        super.init(nibName: nil, bundle: nil)
        title = "Page Thumbnails"
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError() }

    // MARK: - UI

    private lazy var collectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        layout.minimumInteritemSpacing = 8
        layout.minimumLineSpacing = 12
        layout.sectionInset = UIEdgeInsets(top: 12, left: 12, bottom: 12, right: 12)
        let cv = UICollectionView(frame: .zero, collectionViewLayout: layout)
        cv.translatesAutoresizingMaskIntoConstraints = false
        cv.backgroundColor = .systemGroupedBackground
        cv.register(ThumbnailCell.self, forCellWithReuseIdentifier: ThumbnailCell.reuseID)
        cv.dataSource = self
        cv.delegate   = self
        return cv
    }()

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemGroupedBackground
        view.addSubview(collectionView)
        NSLayoutConstraint.activate([
            collectionView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            collectionView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            collectionView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            collectionView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),
        ])
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        if let layout = collectionView.collectionViewLayout as? UICollectionViewFlowLayout {
            let columns: CGFloat = traitCollection.horizontalSizeClass == .compact ? 3 : 5
            let inset: CGFloat = 12 * 2 + 8 * (columns - 1)
            let side = floor((collectionView.bounds.width - inset) / columns)
            layout.itemSize = CGSize(width: side, height: side * 1.4)
        }
    }
}

// MARK: - UICollectionViewDataSource

extension ThumbnailViewController: UICollectionViewDataSource {
    func collectionView(_ cv: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        document.pageCount
    }

    func collectionView(_ cv: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = cv.dequeueReusableCell(withReuseIdentifier: ThumbnailCell.reuseID, for: indexPath) as! ThumbnailCell
        cell.configure(pageIndex: indexPath.item, document: document)
        return cell
    }
}

// MARK: - UICollectionViewDelegate

extension ThumbnailViewController: UICollectionViewDelegate {
    func collectionView(_ cv: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        onPageSelected?(indexPath.item)
        navigationController?.popViewController(animated: true)
    }
}

// MARK: - ThumbnailCell

private final class ThumbnailCell: UICollectionViewCell {
    static let reuseID = "ThumbnailCell"

    private let imageView: UIImageView = {
        let iv = UIImageView()
        iv.translatesAutoresizingMaskIntoConstraints = false
        iv.contentMode   = .scaleAspectFit
        iv.backgroundColor = .white
        iv.layer.cornerRadius = 4
        iv.clipsToBounds = true
        return iv
    }()

    private let pageLabel: UILabel = {
        let lbl = UILabel()
        lbl.translatesAutoresizingMaskIntoConstraints = false
        lbl.textAlignment = .center
        lbl.font = .systemFont(ofSize: 10, weight: .medium)
        lbl.textColor = .secondaryLabel
        return lbl
    }()

    private var renderTask: Task<Void, Never>?

    override init(frame: CGRect) {
        super.init(frame: frame)
        contentView.addSubview(imageView)
        contentView.addSubview(pageLabel)
        NSLayoutConstraint.activate([
            imageView.topAnchor.constraint(equalTo: contentView.topAnchor),
            imageView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            imageView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            imageView.bottomAnchor.constraint(equalTo: pageLabel.topAnchor, constant: -4),
            pageLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            pageLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            pageLabel.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
            pageLabel.heightAnchor.constraint(equalToConstant: 16),
        ])
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError() }

    override func prepareForReuse() {
        super.prepareForReuse()
        renderTask?.cancel()
        imageView.image = nil
    }

    func configure(pageIndex: Int, document: MuPDFDocument) {
        pageLabel.text = "\(pageIndex + 1)"
        renderTask = Task { [weak self] in
            guard let self else { return }
            let bitmap: MuPDFBitmap? = await Task.detached(priority: .userInitiated) {
                guard let page = try? document.loadPage(at: pageIndex) else { return nil }
                return page.render(scale: 0.3)
            }.value
            await MainActor.run {
                guard !Task.isCancelled else { return }
                self.imageView.image = bitmap?.image
            }
        }
    }
}
