import SwiftUI
import Combine
import AppKit

struct HistoryPanel: View {
    @StateObject private var viewModel = HistoryViewModel()
    @Environment(\.colorScheme) var colorScheme
    @State private var selectedIndex: Int? = nil
    @State private var hoveredItemID: UUID? = nil
    
    // New mode flag to distinguish between popover and panel
    var isPanelMode: Bool = false
    
    // Keyboard navigation
    @State private var keyboardNavigationEnabled = false
    
    var body: some View {
        ZStack(alignment: .topLeading) {
        VStack(spacing: 0) {
                // Search bar removed
                
                // Clipboard content area
                enhancedClipboardItems
                
                // Footer with app name
                footer
            }
            .background(VisualEffectView(cornerRadius: 30))
            .overlay(
                // Subtle border for better definition
                RoundedRectangle(cornerRadius: 30)
                    .stroke(Color.white.opacity(0.1), lineWidth: 0.5)
            )
            
            // Close button
            Button(action: {
                closePanel()
            }) {
                Circle()
                    .fill(Color.red.opacity(0.9))
                    .frame(width: 14, height: 14)
                    // .overlay(
                    //     Image(systemName: "xmark")
                    //         .font(.system(size: 8, weight: .bold))
                    //         .foregroundColor(.white)
                    //         .opacity(0.85)
                    // )
                    // .shadow(color: Color.black.opacity(0.2), radius: 1, x: 0, y: 1)
            }
            .buttonStyle(BorderlessButtonStyle())
            .padding(.top, 16)
            .padding(.leading, 16)
            .help("Close")
        }
        .onAppear {
            // Enable keyboard navigation by default
            keyboardNavigationEnabled = true
        }
        .onKeyDown { key in
            handleKeyDown(key)
        }
    }
    
    // Enhanced clipboard items view with better visuals and keyboard navigation
    private var enhancedClipboardItems: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(spacing: 0) {
                    if viewModel.items.isEmpty {
                        enhancedEmptyState
                    } else {
                        ForEach(Array(viewModel.items.enumerated()), id: \.element.id) { index, item in
                            VStack(spacing: 0) {
                                EnhancedClipboardItemView(
                                    item: item,
                                    viewModel: viewModel,
                                    isLastCopied: viewModel.lastCopiedId == item.id,
                                    isSelected: selectedIndex == index,
                                    isHovered: hoveredItemID == item.id
                                )
                                .id(item.id)
                                .onHover { isHovered in
                                    if isHovered {
                                        hoveredItemID = item.id
                                        if hoveredItemID == item.id {
                                            NSCursor.pointingHand.push()
                                        }
                                    } else {
                                        if hoveredItemID == item.id {
                                            hoveredItemID = nil
                                            NSCursor.pop()
                                        }
                                    }
                                }
                    .onTapGesture {
                                    withAnimation(.spring()) {
                        viewModel.copyToClipboard(item)
                                    }
                                }
                                .transition(
                                    .asymmetric(
                                        insertion: .scale(scale: 0.8)
                                            .combined(with: .opacity)
                                            .combined(with: .offset(x: -20, y: 0)),
                                        removal: .opacity.animation(.easeOut(duration: 0.2))
                                    )
                                )
                                .padding(.vertical, 6)
                                
                                // Add divider if not the last item
                                if index < viewModel.items.count - 1 {
                                    Divider()
                                        .background(colorScheme == .dark ? Color.white.opacity(0.08) : Color.black.opacity(0.05))
                                        .padding(.horizontal, 14)
                                }
                            }
                        }
                        .animation(.spring(response: 0.4, dampingFraction: 0.7), value: viewModel.items.count)
                    }
                }
                .padding(.horizontal, 12)
                .padding(.top, 12)
            }
            .scrollIndicators(.hidden)
            .onChange(of: selectedIndex) { index in
                if let index = index, index < viewModel.items.count {
                    let id = viewModel.items[index].id
                    withAnimation {
                        proxy.scrollTo(id, anchor: .center)
                    }
                }
            }
        }
    }
    
    // Visually enhanced empty state
    private var enhancedEmptyState: some View {
        VStack(spacing: 24) {
            Spacer()
            
            Image(systemName: "clipboard")
                .font(.system(size: 42))
                .foregroundColor(.secondary.opacity(0.7))
                .padding(.bottom, 8)
            
            VStack(spacing: 8) {
                Text("Your clipboard history will appear here")
                    .font(.system(size: 18, weight: .medium))
                    .foregroundColor(.secondary)
                
                Text("Copy text to see it in your history")
                    .font(.system(size: 16))
                    .foregroundColor(.secondary.opacity(0.7))
            }
            
            Spacer()
        }
        .frame(minHeight: 300)
        .padding()
        .multilineTextAlignment(.center)
    }
    
    // Handle keyboard navigation
    private func handleKeyDown(_ key: KeyEquivalent) {
        switch key {
        case .upArrow:
            selectedIndex = max(0, (selectedIndex ?? 0) - 1)
            keyboardNavigationEnabled = true
        case .downArrow:
            if selectedIndex == nil {
                selectedIndex = 0
            } else {
                selectedIndex = min((viewModel.items.count - 1), (selectedIndex ?? -1) + 1)
            }
            keyboardNavigationEnabled = true
        case .return, .space:
            if let index = selectedIndex, index < viewModel.items.count {
                let item = viewModel.items[index]
                            viewModel.copyToClipboard(item)
                        }
        case .escape:
            keyboardNavigationEnabled = false
            selectedIndex = nil
        default:
            break
        }
    }
    
    // Modified to handle first result selection without search
    private func selectFirstResult() {
        if !viewModel.items.isEmpty {
            selectedIndex = 0
            keyboardNavigationEnabled = true
        }
    }
    
    // Replace the current footer implementation with this more elegant version
    private var footer: some View {
        HStack(spacing: 12) {
            // App Logo - now with consistent color
            Text("oioi")
                .font(.system(size: 13, weight: .semibold, design: .rounded))
                .foregroundColor(colorScheme == .dark ? .white.opacity(0.9) : .black.opacity(0.9))
                .padding(.horizontal, 10)
                .padding(.vertical, 5)
                .background(
                    RoundedRectangle(cornerRadius: 14)
                        .fill(colorScheme == .dark ? Color.black.opacity(0.2) : Color.white.opacity(0.3))
                )
            
            Spacer()
            
            // Keyboard shortcuts reminder
            HStack(spacing: 10) {
                keyboardShortcutLabel(symbol: "⌥V", text: "Open")
                keyboardShortcutLabel(symbol: "↑↓", text: "Navigate")
                keyboardShortcutLabel(symbol: "⏎", text: "Copy")
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(Color.clear)
    }
    
    // Helper for consistent keyboard shortcut styling
    private func keyboardShortcutLabel(symbol: String, text: String) -> some View {
        HStack(spacing: 4) {
            Text(symbol)
                .font(.system(size: 12, weight: .semibold))
                .padding(.horizontal, 5)
                .padding(.vertical, 2)
                .background(
                    RoundedRectangle(cornerRadius: 4)
                        .fill(colorScheme == .dark ? Color.white.opacity(0.1) : Color.black.opacity(0.05))
                )
            
            Text(text)
                .font(.system(size: 11))
                .foregroundColor(.secondary)
        }
    }
    
    // Add this function to handle panel closing
    private func closePanel() {
        // Close the panel by notifying the parent controller
        if isPanelMode {
            // For the Option+V floating panel
            NotificationCenter.default.post(name: NSNotification.Name("ClosePanel"), object: nil)
        } else {
            // For the menu bar popover
            NotificationCenter.default.post(name: NSNotification.Name("ClosePopover"), object: nil)
        }
    }
}

// Keyboard shortcut handling for entire view
extension View {
    func onKeyDown(perform action: @escaping (KeyEquivalent) -> Void) -> some View {
        self.modifier(KeyEventModifier(onKeyDown: action))
    }
}

struct KeyEventModifier: ViewModifier {
    let onKeyDown: (KeyEquivalent) -> Void
    
    func body(content: Content) -> some View {
        content
            .overlay(
                KeyHandlingView(onKeyDown: onKeyDown)
                    .frame(width: 0, height: 0)
            )
    }
}

struct KeyHandlingView: NSViewRepresentable {
    let onKeyDown: (KeyEquivalent) -> Void
    
    func makeNSView(context: Context) -> NSView {
        let view = KeyHandlingNSView()
        view.onKeyDown = onKeyDown
        DispatchQueue.main.async {
            view.window?.makeFirstResponder(view)
        }
        return view
    }
    
    func updateNSView(_ nsView: NSView, context: Context) {
        if let view = nsView as? KeyHandlingNSView {
            view.onKeyDown = onKeyDown
        }
    }
    
    class KeyHandlingNSView: NSView {
        var onKeyDown: ((KeyEquivalent) -> Void)?
        
        override var acceptsFirstResponder: Bool { true }
        
        override func keyDown(with event: NSEvent) {
            if let key = KeyEquivalent(rawValue: event.charactersIgnoringModifiers ?? "") {
                onKeyDown?(key)
            }
            super.keyDown(with: event)
        }
    }
}

// Replace the ImprovedTextField with this simpler, more reliable version
struct ImprovedTextField: NSViewRepresentable {
    @Binding var text: String
    @Binding var isActive: Bool
    var onCommit: () -> Void
    var onKeyDown: (KeyEquivalent) -> Void
    
    func makeNSView(context: Context) -> CustomNSTextField {
        let textField = CustomNSTextField()
        textField.stringValue = text
        textField.isBordered = false
        textField.drawsBackground = false
        textField.focusRingType = .none
        textField.delegate = context.coordinator
        textField.font = NSFont.systemFont(ofSize: 18)
        textField.textColor = NSColor.textColor
        textField.placeholderString = ""
        textField.onKeyDown = { key in
            if let keyEquivalent = KeyEquivalent(rawValue: key) {
                onKeyDown(keyEquivalent)
            }
        }
        
        // Make sure the cursor is visible with high contrast
        if let fieldEditor = textField.currentEditor() as? NSTextView {
            fieldEditor.insertionPointColor = NSColor.systemBlue
        }
        
        // Immediately become first responder
        DispatchQueue.main.async {
            if let window = textField.window {
                window.makeFirstResponder(textField)
            }
        }
        
        return textField
    }
    
    func updateNSView(_ nsView: CustomNSTextField, context: Context) {
        // Only update if values differ to prevent cursor jumping
        if nsView.stringValue != text {
            nsView.stringValue = text
        }
        
        // Force focus when needed with a small delay
        if isActive {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                if let window = nsView.window, window.firstResponder != nsView {
                    window.makeFirstResponder(nsView)
                    
                    // Additionally, force the field editor to appear
                    if let fieldEditor = window.fieldEditor(true, for: nsView) as? NSTextView {
                        fieldEditor.insertionPointColor = NSColor.systemBlue
                        fieldEditor.selectedTextAttributes = [NSAttributedString.Key.foregroundColor: NSColor.white]
                    }
                }
            }
        }
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, NSTextFieldDelegate {
        var parent: ImprovedTextField
        
        init(_ parent: ImprovedTextField) {
            self.parent = parent
        }
        
        func controlTextDidChange(_ obj: Notification) {
            if let textField = obj.object as? NSTextField {
                DispatchQueue.main.async {
                    self.parent.text = textField.stringValue
                }
            }
        }
        
        func controlTextDidBeginEditing(_ obj: Notification) {
            DispatchQueue.main.async {
                self.parent.isActive = true
            }
        }
        
        func controlTextDidEndEditing(_ obj: Notification) {
            DispatchQueue.main.async {
                self.parent.isActive = false
            }
        }
        
        func control(_ control: NSControl, textView: NSTextView, doCommandBy commandSelector: Selector) -> Bool {
            if commandSelector == #selector(NSResponder.insertNewline(_:)) {
                parent.onCommit()
                return true
            } else if commandSelector == #selector(NSResponder.moveDown(_:)) {
                parent.onKeyDown(.downArrow)
                return true
            } else if commandSelector == #selector(NSResponder.moveUp(_:)) {
                parent.onKeyDown(.upArrow)
                return true
            }
            return false
        }
    }
}

// Add this custom NSTextField subclass that properly handles key events
class CustomNSTextField: NSTextField {
    var onKeyDown: ((String) -> Void)?
    
    override func keyDown(with event: NSEvent) {
        if let characters = event.charactersIgnoringModifiers {
            onKeyDown?(characters)
        }
        super.keyDown(with: event)
    }
    
    override var acceptsFirstResponder: Bool { return true }
    
    override func becomeFirstResponder() -> Bool {
        let result = super.becomeFirstResponder()
        if result, let fieldEditor = currentEditor() {
            fieldEditor.selectedRange = NSRange(location: fieldEditor.string.count, length: 0)
        }
        return result
    }
}

// Beautiful clipboard item view with animations and visual polish
struct EnhancedClipboardItemView: View {
    let item: ClipboardItem
    let viewModel: HistoryViewModel
    let isLastCopied: Bool
    let isSelected: Bool
    let isHovered: Bool
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        HStack(spacing: 14) {
            // Content stack
            contentStack
            
            Spacer()
            
            // Copy button
            copyButton
        }
        .padding(.vertical, 12)
        .padding(.horizontal, 14)
        .background(backgroundShape)
        .contentShape(Rectangle())
    }
    
    // Break down complex parts into separate computed properties
    private var contentStack: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(item.content)
                .font(.system(size: 18))
                .lineLimit(2)
                .truncationMode(.middle)
                .foregroundColor(contentTextColor)
            
            // Only show timestamp if needed
            if isSelected || isHovered || isLastCopied {
                timeStampView
            }
        }
    }
    
    private var contentTextColor: Color {
        if isSelected || isLastCopied {
            return colorScheme == .dark ? .white : .black
        } else {
            return colorScheme == .dark ? .white.opacity(0.9) : .black.opacity(0.9)
        }
    }
    
    private var timeStampView: some View {
        HStack(spacing: 8) {
            Text(timeAgo(from: item.timestamp))
                .font(.system(size: 13))
                .foregroundColor(.secondary.opacity(0.8))
            
            if isLastCopied {
                Text("• oioi")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(colorScheme == .dark ? .white : .black)
            }
        }
        .transition(.opacity)
        .animation(.easeInOut(duration: 0.2), value: isSelected || isHovered || isLastCopied)
    }
    
    private var copyButton: some View {
        ZStack {
            Circle()
                .fill(circleBackgroundColor)
                .frame(width: 36, height: 36)
            
            Group {
                if isLastCopied {
                    // Show checkmark with animated entrance
                    Image(systemName: "checkmark")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(.green)
                        .transition(.scale.combined(with: .opacity))
                } else {
                    // Show copy icon
                    Image(systemName: "doc.on.doc")
                        .font(.system(size: 14))
                        .foregroundColor(.secondary)
                        .transition(.scale.combined(with: .opacity))
                }
            }
            .animation(.spring(response: 0.2), value: isLastCopied)
        }
        .scaleEffect(isSelected || isHovered ? 1.05 : 1.0)
        .animation(.spring(response: 0.3), value: isSelected || isHovered)
    }
    
    private var circleBackgroundColor: Color {
        if isLastCopied {
            return Color.green.opacity(colorScheme == .dark ? 0.3 : 0.2)
        } else if isSelected || isHovered {
            return colorScheme == .dark ? Color.white.opacity(0.15) : Color.black.opacity(0.08)
        } else {
            return Color.clear
        }
    }
    
    private var backgroundShape: some View {
        RoundedRectangle(cornerRadius: 14)
            .fill(backgroundColor)
            .animation(.easeOut(duration: 0.2), value: isSelected || isHovered || isLastCopied)
    }
    
    private var backgroundColor: Color {
        if isLastCopied {
            return colorScheme == .dark ? Color.green.opacity(0.1) : Color.green.opacity(0.05)
        } else if isSelected {
            return colorScheme == .dark ? Color.blue.opacity(0.1) : Color.blue.opacity(0.05)
        } else if isHovered {
            return colorScheme == .dark ? Color.white.opacity(0.07) : Color.black.opacity(0.03)
        } else {
            return Color.clear
        }
    }
    
    private func timeAgo(from date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: date, relativeTo: Date())
    }
}

// KeyEquivalent enum for keyboard navigation
enum KeyEquivalent: String {
    case upArrow = "\u{F700}"
    case downArrow = "\u{F701}"
    case leftArrow = "\u{F702}"
    case rightArrow = "\u{F703}"
    case `return` = "\r"
    case space = " "
    case escape = "\u{1B}"
}

// Add a completely different approach for panel mode using NSViewControllerRepresentable
struct DirectTextField: NSViewControllerRepresentable {
    @Binding var text: String
    @Binding var isActive: Bool
    var isPanelMode: Bool
    var onCommit: () -> Void
    var onArrowDown: () -> Void
    
    func makeNSViewController(context: Context) -> TextFieldViewController {
        let controller = TextFieldViewController()
        controller.text = text
        controller.onTextChange = { newText in
            DispatchQueue.main.async {
                self.text = newText
            }
        }
        controller.onCommit = onCommit
        controller.onArrowDown = onArrowDown
        return controller
    }
    
    func updateNSViewController(_ nsViewController: TextFieldViewController, context: Context) {
        nsViewController.text = text
        nsViewController.onTextChange = { newText in
            DispatchQueue.main.async {
                self.text = newText
            }
        }
        nsViewController.onCommit = onCommit
        nsViewController.onArrowDown = onArrowDown
        
        if isActive {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                nsViewController.focusTextField()
            }
        }
    }
}
