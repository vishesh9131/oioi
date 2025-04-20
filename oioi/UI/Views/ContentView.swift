//////// UI/Views/ContentView.swift
//import SwiftUI
//
//struct ContentView: View {
//    @ObservedObject var viewModel = HistoryViewModel()
//    
//    var body: some View {
//        VStack {
//            Text("IN DEVELOPMENT")
//                .font(.headline)
//            List(viewModel.items) { item in
//                Text(item.content)
//                    .lineLimit(2)
//            }
//        }
//        .frame(minWidth: 300, minHeight: 400)
//    }
//}
//


import SwiftUI

struct ContentView: View {
    @ObservedObject var viewModel = HistoryViewModel()
    
    var body: some View {
        ZStack {
            // Blurred background using NSVisualEffectView (for macOS)
            VisualEffectBlurView()
                .edgesIgnoringSafeArea(.all)

            VStack(spacing: 20) {
                // Header
                Text("IN DEVELOPMENT")
                    .font(.largeTitle)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                    .padding(.top, 20)
                Text("Shortcut : option + v")
                    .foregroundColor(.white.opacity(0.7))
                    .padding(.bottom, 10)
                
//                // Fancy list
//                List(viewModel.items) { item in
//                    Text(item.content)
//                        .padding()
//                        .background(
//                            RoundedRectangle(cornerRadius: 10)
//                                .fill(Color.white.opacity(0.1))
//                        )
//                        .foregroundColor(.white)
//                        .listRowBackground(Color.clear)
//                        .listRowSeparator(.hidden)
//                }
//                .listStyle(.plain)
//                .scrollContentBackground(.hidden)
                
                Spacer()
                
                // Credit
                Text("Crafted with ❤️ by Vishesh Yadav")
                    .font(.footnote)
                    .foregroundColor(.white.opacity(0.7))
                    .padding(.bottom, 10)
            }
            .padding(.horizontal)
        }
        .frame(minWidth: 350, minHeight: 50)
    }
}

// Inline macOS blur view
struct VisualEffectBlurView: NSViewRepresentable {
    func makeNSView(context: Context) -> NSVisualEffectView {
        let view = NSVisualEffectView()
        view.blendingMode = .behindWindow
        view.state = .active
        view.material = .hudWindow // You can try .sidebar, .fullScreenUI etc.
        return view
    }

    func updateNSView(_ nsView: NSVisualEffectView, context: Context) {}
}
