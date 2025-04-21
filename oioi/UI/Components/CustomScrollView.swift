import SwiftUI
import AppKit

struct CustomScrollView<Content: View>: NSViewRepresentable {
    let content: Content
    
    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }
    
    func makeNSView(context: Context) -> NSScrollView {
        let scrollView = NSScrollView()
        
        // Configure scrollbar
        scrollView.hasVerticalScroller = true
        scrollView.scrollerStyle = .overlay
        
        // Make scrollbar more subtle
        if let scroller = scrollView.verticalScroller {
            scroller.alphaValue = 0.35
            scroller.controlSize = .mini
        }
        
        // Configure scroll view
        scrollView.drawsBackground = false
        scrollView.backgroundColor = .clear
        scrollView.verticalScrollElasticity = .allowed
        scrollView.scrollerInsets = NSEdgeInsets(top: 0, left: 0, bottom: 0, right: -6)
        
        // Set up content
        let hostingView = NSHostingView(rootView: content)
        hostingView.translatesAutoresizingMaskIntoConstraints = false
//        hostingView.backgroundColor = .clear
        
        // Configure document view
        scrollView.documentView = hostingView
        
        // Set up constraints to make content fill width
        if let documentView = scrollView.documentView {
            NSLayoutConstraint.activate([
                documentView.leadingAnchor.constraint(equalTo: scrollView.contentView.leadingAnchor),
                documentView.trailingAnchor.constraint(equalTo: scrollView.contentView.trailingAnchor),
                documentView.topAnchor.constraint(equalTo: scrollView.contentView.topAnchor)
            ])
        }
        
        return scrollView
    }
    
    func updateNSView(_ scrollView: NSScrollView, context: Context) {
        if let hostingView = scrollView.documentView as? NSHostingView<Content> {
            hostingView.rootView = content
        }
    }
}

// Helper view modifier
extension View {
    func customScrollBar() -> some View {
        CustomScrollView {
            self
        }
    }
} 
