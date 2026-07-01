import SwiftUI
import SafariServices
import UIKit

/// Presents a remote URL (Terms, Privacy, UPL disclaimer) in an in-app
/// `SFSafariViewController`, tinted to the brand.
struct SafariView: UIViewControllerRepresentable {
    let url: URL

    func makeUIViewController(context: Context) -> SFSafariViewController {
        let controller = SFSafariViewController(url: url)
        controller.preferredControlTintColor = UIColor(Theme.brandPrimary)
        return controller
    }

    func updateUIViewController(_ controller: SFSafariViewController, context: Context) {}
}
