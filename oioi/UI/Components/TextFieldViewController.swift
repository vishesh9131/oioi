import AppKit

// Create this as a new separate file for better organization
public class TextFieldViewController: NSViewController, NSTextFieldDelegate {
    var text: String = ""
    var onTextChange: ((String) -> Void)? = nil
    var onCommit: (() -> Void)? = nil
    var onArrowDown: (() -> Void)? = nil
    private var textField: NSTextField!
    
    public override func loadView() {
        let containerView = NSView()
        textField = CustomSearchTextField()
        textField.isBordered = false
        textField.drawsBackground = false
        textField.focusRingType = .none
        textField.font = NSFont.systemFont(ofSize: 18)
        textField.textColor = NSColor.textColor
        textField.delegate = self
        textField.stringValue = text
        
        containerView.addSubview(textField)
        textField.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            textField.topAnchor.constraint(equalTo: containerView.topAnchor),
            textField.bottomAnchor.constraint(equalTo: containerView.bottomAnchor),
            textField.leadingAnchor.constraint(equalTo: containerView.leadingAnchor),
            textField.trailingAnchor.constraint(equalTo: containerView.trailingAnchor),
        ])
        
        self.view = containerView
    }
    
    public override func viewDidAppear() {
        super.viewDidAppear()
        focusTextField()
    }
    
    func focusTextField() {
        view.window?.makeFirstResponder(textField)
        
        if let editor = view.window?.fieldEditor(true, for: textField) as? NSTextView {
            editor.insertionPointColor = NSColor.systemBlue
            editor.selectedRange = NSRange(location: textField.stringValue.count, length: 0)
        }
    }
    
    // MARK: - NSTextFieldDelegate
    
    public func controlTextDidChange(_ obj: Notification) {
        guard let textField = obj.object as? NSTextField else { return }
        text = textField.stringValue
        onTextChange?(text)
    }
    
    public func control(_ control: NSControl, textView: NSTextView, doCommandBy commandSelector: Selector) -> Bool {
        if commandSelector == #selector(NSResponder.insertNewline(_:)) {
            onCommit?()
            return true
        } else if commandSelector == #selector(NSResponder.moveDown(_:)) {
            onArrowDown?()
            return true
        }
        return false
    }
}

// Custom text field with enhanced focus handling
public class CustomSearchTextField: NSTextField {
    public override var acceptsFirstResponder: Bool { true }
    
    public override func viewDidMoveToWindow() {
        super.viewDidMoveToWindow()
        
        if let window = window {
            DispatchQueue.main.async {
                window.makeFirstResponder(self)
            }
        }
    }
} 
