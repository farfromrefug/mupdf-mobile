import UIKit
import MuPDFMobile

/// Root view controller that provides a button to open the bundled sample PDF.
final class ViewController: UIViewController {

    // ─────────────────────────────────────────────────────────────────────────
    // MARK: UI
    // ─────────────────────────────────────────────────────────────────────────

    private lazy var openButton: UIButton = {
        var config = UIButton.Configuration.filled()
        config.title        = "Open Sample PDF"
        config.image        = UIImage(systemName: "doc.fill")
        config.imagePadding = 8
        let btn = UIButton(configuration: config)
        btn.translatesAutoresizingMaskIntoConstraints = false
        btn.addTarget(self, action: #selector(openSamplePDF), for: .touchUpInside)
        return btn
    }()

    private lazy var infoLabel: UILabel = {
        let lbl = UILabel()
        lbl.translatesAutoresizingMaskIntoConstraints = false
        lbl.text          = "MuPDF Mobile Demo"
        lbl.font          = .preferredFont(forTextStyle: .title2)
        lbl.textAlignment = .center
        lbl.numberOfLines = 0
        return lbl
    }()

    private lazy var subtitleLabel: UILabel = {
        let lbl = UILabel()
        lbl.translatesAutoresizingMaskIntoConstraints = false
        lbl.text          = "Cross-platform PDF rendering powered by MuPDF"
        lbl.font          = .preferredFont(forTextStyle: .subheadline)
        lbl.textColor     = .secondaryLabel
        lbl.textAlignment = .center
        lbl.numberOfLines = 0
        return lbl
    }()

    // ─────────────────────────────────────────────────────────────────────────
    // MARK: Lifecycle
    // ─────────────────────────────────────────────────────────────────────────

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "MuPDF Demo"
        view.backgroundColor = .systemBackground

        view.addSubview(infoLabel)
        view.addSubview(subtitleLabel)
        view.addSubview(openButton)

        NSLayoutConstraint.activate([
            infoLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            infoLabel.centerYAnchor.constraint(equalTo: view.centerYAnchor, constant: -60),
            infoLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 24),
            infoLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -24),

            subtitleLabel.topAnchor.constraint(equalTo: infoLabel.bottomAnchor, constant: 8),
            subtitleLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 24),
            subtitleLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -24),

            openButton.topAnchor.constraint(equalTo: subtitleLabel.bottomAnchor, constant: 32),
            openButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            openButton.widthAnchor.constraint(greaterThanOrEqualToConstant: 220),
            openButton.heightAnchor.constraint(equalToConstant: 50),
        ])
    }

    // ─────────────────────────────────────────────────────────────────────────
    // MARK: Actions
    // ─────────────────────────────────────────────────────────────────────────

    @objc private func openSamplePDF() {
        guard let pdfURL = Bundle.main.url(forResource: "sample", withExtension: "pdf") else {
            showAlert(title: "No PDF found",
                      message: "Add a 'sample.pdf' to the app bundle to try the viewer.")
            return
        }

        do {
            let doc = try MuPDFDocument.open(path: pdfURL.path)
            let viewer = PDFViewerViewController(document: doc)
            navigationController?.pushViewController(viewer, animated: true)
        } catch {
            showAlert(title: "Error", message: error.localizedDescription)
        }
    }

    private func showAlert(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
}
