import UIKit
import WebKit

/// Контролер для відображення списку обраних товарів через WebView
class FavoritesViewController: UIViewController, WKNavigationDelegate {

    private var webView: WKWebView!
    private var progressView: UIProgressView!
    
    private let favoritesURL = "https://v3magazin.glyanec.net/user/favorites"

    override func viewDidLoad() {
        super.viewDidLoad()
        
        title = "Списки покупок"
        view.backgroundColor = .systemBackground
        
        setupWebView()
        setupProgressBar()
        setupNavigationBar()
        
        print("✅ [FavoritesVC] Initialized with WebView")
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        // ✅ ВАЖЛИВО: Фіксуємо колір навігації (завжди чорний)
        navigationController?.navigationBar.tintColor = .black
        navigationController?.navigationBar.isHidden = false
        
        // Завантажуємо сторінку обраного при кожному відображенні
        loadFavoritesPage()
    }
    
    deinit {
        webView?.removeObserver(self, forKeyPath: "estimatedProgress")
    }
    
    // MARK: - Setup
    
    private func setupWebView() {
        let config = WKWebViewConfiguration()
        config.websiteDataStore = .default()  // Спільні cookies з іншими WebView
        
        webView = WKWebView(frame: .zero, configuration: config)
        webView.navigationDelegate = self
        webView.translatesAutoresizingMaskIntoConstraints = false
        
        view.addSubview(webView)
        
        NSLayoutConstraint.activate([
            webView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            webView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            webView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            webView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
        
        webView.addObserver(self, forKeyPath: "estimatedProgress", options: .new, context: nil)
    }
    
    private func setupProgressBar() {
        progressView = UIProgressView(progressViewStyle: .default)
        progressView.progressTintColor = UIColor.systemGreen
        progressView.trackTintColor = UIColor.systemGray5
        progressView.translatesAutoresizingMaskIntoConstraints = false
        progressView.isHidden = true
        
        view.addSubview(progressView)
        
        NSLayoutConstraint.activate([
            progressView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            progressView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            progressView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            progressView.heightAnchor.constraint(equalToConstant: 2)
        ])
    }
    
    private func setupNavigationBar() {
        // Можна додати кнопку "Назад" або інші елементи при потребі
        navigationItem.leftBarButtonItem = UIBarButtonItem(
            image: UIImage(systemName: "chevron.left"),
            style: .plain,
            target: self,
            action: #selector(goBack)
        )
    }
    
    @objc private func goBack() {
        if webView.canGoBack {
            webView.goBack()
        } else {
            navigationController?.popViewController(animated: true)
        }
    }
    
    private func loadFavoritesPage() {
        guard let url = URL(string: favoritesURL) else {
            print("❌ [FavoritesVC] Invalid URL")
            return
        }
        
        print("🔄 [FavoritesVC] Loading favorites page: \(favoritesURL)")
        webView.load(URLRequest(url: url))
    }
    
    // MARK: - Progress Observer
    
    override func observeValue(forKeyPath keyPath: String?, of object: Any?,
                               change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        guard keyPath == "estimatedProgress" else { return }
        
        progressView.isHidden = webView.estimatedProgress >= 1.0
        progressView.progress = Float(webView.estimatedProgress)
    }
    
    // MARK: - WKNavigationDelegate
    
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        print("✅ [FavoritesVC] Page loaded: \(webView.url?.absoluteString ?? "unknown")")
    }
    
    func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
        print("❌ [FavoritesVC] Failed to load: \(error.localizedDescription)")
    }
}
