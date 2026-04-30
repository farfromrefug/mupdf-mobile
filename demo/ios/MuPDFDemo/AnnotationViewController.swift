import UIKit
import MuPDFMobile

/// Demonstrates annotation add/edit/remove on a page.
final class AnnotationViewController: UIViewController {

    // MARK: - Dependencies

    private let document: MuPDFDocument
    private var currentPage: MuPDFPage?
    private var annotations: [MuPDFAnnotation] = []
    private var currentPageIndex = 0

    init(document: MuPDFDocument) {
        self.document = document
        super.init(nibName: nil, bundle: nil)
        title = "Annotations"
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError() }

    // MARK: - UI

    private lazy var pageImageView: UIImageView = {
        let iv = UIImageView()
        iv.translatesAutoresizingMaskIntoConstraints = false
        iv.contentMode = .scaleAspectFit
        iv.backgroundColor = .white
        iv.isUserInteractionEnabled = true
        let tap = UITapGestureRecognizer(target: self, action: #selector(pageTapped(_:)))
        iv.addGestureRecognizer(tap)
        return iv
    }()

    private lazy var tableView: UITableView = {
        let tv = UITableView(frame: .zero, style: .plain)
        tv.translatesAutoresizingMaskIntoConstraints = false
        tv.dataSource = self
        tv.delegate   = self
        tv.register(UITableViewCell.self, forCellReuseIdentifier: "Cell")
        return tv
    }()

    private lazy var toolbar: UIToolbar = {
        let tb = UIToolbar()
        tb.translatesAutoresizingMaskIntoConstraints = false
        return tb
    }()

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground

        let stackView = UIStackView(arrangedSubviews: [pageImageView, tableView])
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.axis = .vertical
        stackView.distribution = .fill

        view.addSubview(stackView)
        view.addSubview(toolbar)

        NSLayoutConstraint.activate([
            stackView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            stackView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            stackView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            stackView.bottomAnchor.constraint(equalTo: toolbar.topAnchor),
            pageImageView.heightAnchor.constraint(equalTo: view.heightAnchor, multiplier: 0.5),
            toolbar.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            toolbar.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            toolbar.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),
        ])

        setupToolbar()
        loadPage(at: 0)
    }

    private func setupToolbar() {
        let highlightBtn = UIBarButtonItem(title: "Highlight", style: .plain, target: self, action: #selector(addHighlight))
        let inkBtn = UIBarButtonItem(title: "Ink", style: .plain, target: self, action: #selector(addInk))
        let spacer = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)
        let clearBtn = UIBarButtonItem(title: "Clear All", style: .plain, target: self, action: #selector(clearAllAnnotations))
        toolbar.items = [highlightBtn, spacer, inkBtn, spacer, clearBtn]
    }

    private func loadPage(at index: Int) {
        guard index >= 0 && index < document.pageCount else { return }
        currentPageIndex = index
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self else { return }
            let page = try? self.document.loadPage(at: index)
            let bitmap = page?.render(scale: 1.5)
            let annots = page?.annotations() ?? []
            DispatchQueue.main.async {
                // Release the previous page before replacing
                self.currentPage?.invalidate()
                self.currentPage = page
                #if canImport(UIKit)
                self.pageImageView.image = bitmap?.image
                #endif
                self.annotations = annots
                self.tableView.reloadData()
            }
        }
    }

    // MARK: - Actions

    @objc private func pageTapped(_ gesture: UITapGestureRecognizer) {
        let point = gesture.location(in: pageImageView)
        let bounds = pageImageView.bounds
        guard bounds.width > 0, bounds.height > 0, let page = currentPage else { return }
        let pdfX = Float(point.x / bounds.width) * page.width
        let pdfY = Float(point.y / bounds.height) * page.height
        let rect = MuPDFRect(x: pdfX - 50, y: pdfY - 10, width: 100, height: 20)
        let alert = UIAlertController(title: "Add Annotation", message: nil, preferredStyle: .actionSheet)
        let types: [(String, MuPDFAnnotationType)] = [
            ("Highlight", .highlight), ("Underline", .underline),
            ("Strikeout", .strikeout), ("Text Note", .text)
        ]
        for (name, type) in types {
            alert.addAction(UIAlertAction(title: name, style: .default) { [weak self] _ in
                try? self?.addAnnotation(type: type, rect: rect)
            })
        }
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        present(alert, animated: true)
    }

    @objc private func addHighlight() {
        guard currentPage != nil else { return }
        let rect = MuPDFRect(x: 72, y: 100, width: 200, height: 20)
        try? addAnnotation(type: .highlight, rect: rect)
    }

    @objc private func addInk() {
        guard currentPage != nil else { return }
        let rect = MuPDFRect(x: 72, y: 140, width: 100, height: 50)
        try? addAnnotation(type: .ink, rect: rect)
    }

    @objc private func clearAllAnnotations() {
        guard let page = currentPage else { return }
        for annotation in annotations {
            try? page.removeAnnotation(annotation)
        }
        annotations.removeAll()
        tableView.reloadData()
    }

    private func addAnnotation(type: MuPDFAnnotationType, rect: MuPDFRect) throws {
        guard let page = currentPage else { return }
        let annot = try page.addAnnotation(type: type, rect: rect)
        annot.color = MuPDFColor.highlightYellow
        annot.update()
        annotations.append(annot)
        tableView.reloadData()
    }
}

// MARK: - UITableViewDataSource

extension AnnotationViewController: UITableViewDataSource {
    func tableView(_ tv: UITableView, numberOfRowsInSection section: Int) -> Int {
        annotations.count
    }

    func tableView(_ tv: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tv.dequeueReusableCell(withIdentifier: "Cell", for: indexPath)
        let annot = annotations[indexPath.row]
        cell.textLabel?.text = "\(annot.type.name)  (p\(currentPageIndex + 1))"
        cell.detailTextLabel?.text = annot.contents.isEmpty ? annot.rect.description : annot.contents
        return cell
    }

    func tableView(_ tv: UITableView, canEditRowAt indexPath: IndexPath) -> Bool { true }

    func tableView(_ tv: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        guard editingStyle == .delete, let page = currentPage else { return }
        let annot = annotations[indexPath.row]
        try? page.removeAnnotation(annot)
        annotations.remove(at: indexPath.row)
        tv.deleteRows(at: [indexPath], with: .automatic)
    }
}

// MARK: - UITableViewDelegate

extension AnnotationViewController: UITableViewDelegate {
    func tableView(_ tv: UITableView, didSelectRowAt indexPath: IndexPath) {
        tv.deselectRow(at: indexPath, animated: true)
        let annot = annotations[indexPath.row]
        let alert = UIAlertController(title: "Edit Note", message: nil, preferredStyle: .alert)
        alert.addTextField { tf in tf.text = annot.contents; tf.placeholder = "Annotation note…" }
        alert.addAction(UIAlertAction(title: "Save", style: .default) { [weak self] _ in
            annot.contents = alert.textFields?.first?.text ?? ""
            annot.update()
            self?.tableView.reloadRows(at: [indexPath], with: .none)
        })
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        present(alert, animated: true)
    }
}
