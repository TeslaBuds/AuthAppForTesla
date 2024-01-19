//
//  AuthWebViewController.swift
//  AuthAppForTesla
//
//  Created by Kim Hansen on 03/02/2021.
//

import UIKit
import WebKit

public class AuthWebViewController: UIViewController {
    var webView = WKWebView()
    var result: ((Result<URL, Error>) -> Void)?
    let redirectUrl: String

    @available(*, unavailable)
    required init?(coder _: NSCoder) {
        fatalError("not supported")
    }

    init(url: URL, redirectUrl: String) {
        self.redirectUrl = redirectUrl
        super.init(nibName: nil, bundle: nil)

        let configuration = WKWebViewConfiguration()
        configuration.websiteDataStore = WKWebsiteDataStore.nonPersistent()
        webView = WKWebView(frame: view.bounds, configuration: configuration)
        webView.navigationDelegate = self
        webView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(webView)
        view.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "|-0-[view]-0-|", options: [], metrics: nil, views: ["view": webView]))
        view.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "V:|-0-[view]-0-|", options: [], metrics: nil, views: ["view": webView]))
        webView.load(URLRequest(url: url))
    }

    override public func loadView() {
        view = webView
    }
}

extension AuthWebViewController: WKNavigationDelegate {
    public func webView(_: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
        if let url = navigationAction.request.url, url.absoluteString.starts(with: redirectUrl) {
            decisionHandler(.cancel)
            dismiss(animated: true, completion: nil)
            result?(Result.success(url))
        } else {
            decisionHandler(.allow)
        }
    }

    public func webView(_: WKWebView, didFail _: WKNavigation!, withError _: Error) {
        result?(Result.failure(TeslaError.authenticationFailed))
        dismiss(animated: true, completion: nil)
    }
}
