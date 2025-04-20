import AppKit

final class HistoryPanelController: NSWindowController {
    private var tableView: NSTableView!
    private var searchField: NSSearchField!

    convenience init() {
        let panel = NSPanel(contentRect: NSRect(x: 0, y: 0, width: 500, height: 400),
                            styleMask: [.titled, .closable, .resizable, .fullSizeContentView],
                            backing: .buffered,
                            defer: false)
        panel.title = "OiOi - Clipboard History"
        panel.isMovableByWindowBackground = true
        panel.level = .floating
        self.init(window: panel)
        setupUI()
    }

    private func setupUI() {
        guard let contentView = window?.contentView else { return }
        contentView.translatesAutoresizingMaskIntoConstraints = false

        // Search Field
        searchField = NSSearchField()
        searchField.placeholderString = "Search history..."
        searchField.translatesAutoresizingMaskIntoConstraints = false
        searchField.target = self
        searchField.action = #selector(handleSearch)

        // Table View
        tableView = NSTableView()
        tableView.delegate = self
        tableView.dataSource = self
        tableView.rowHeight = 24
        tableView.usesAlternatingRowBackgroundColors = true

        let column = NSTableColumn(identifier: .init("ContentColumn"))
        column.title = "History"
        column.width = 480
        tableView.addTableColumn(column)

        // Scroll View wrapping Table View
        let scrollView = NSScrollView()
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.documentView = tableView
        scrollView.hasVerticalScroller = true
        scrollView.hasHorizontalScroller = false
        scrollView.autohidesScrollers = true

        // Stack View to hold search bar and table
        let stackView = NSStackView()
        stackView.orientation = .vertical
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.spacing = 8
        stackView.edgeInsets = NSEdgeInsets(top: 10, left: 10, bottom: 10, right: 10)

        stackView.addArrangedSubview(searchField)
        stackView.addArrangedSubview(scrollView)

        contentView.addSubview(stackView)

        // Auto Layout Constraints
        NSLayoutConstraint.activate([
            stackView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            stackView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            stackView.topAnchor.constraint(equalTo: contentView.topAnchor),
            stackView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
            searchField.heightAnchor.constraint(equalToConstant: 28)
        ])

        // Notification for data reload
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(reloadData),
            name: .historyUpdated,
            object: nil
        )
    }

    @objc private func reloadData() {
        tableView.reloadData()
    }

    @objc private func handleSearch(_ sender: NSSearchField) {
        // Filter history here if using a view model or a search mechanism
        print("Search text: \(sender.stringValue)")
    }
}

extension HistoryPanelController: NSTableViewDataSource, NSTableViewDelegate {
    func numberOfRows(in tableView: NSTableView) -> Int {
        HistoryManager.shared.items.count
    }

    func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
        let item = HistoryManager.shared.items[row]

        let identifier = NSUserInterfaceItemIdentifier("Cell")
        var cell = tableView.makeView(withIdentifier: identifier, owner: self) as? NSTableCellView

        if cell == nil {
            cell = NSTableCellView()
            let textField = NSTextField(labelWithString: item.content)
            textField.lineBreakMode = .byTruncatingTail
            textField.translatesAutoresizingMaskIntoConstraints = false
            cell?.addSubview(textField)
            cell?.textField = textField
            cell?.identifier = identifier

            NSLayoutConstraint.activate([
                textField.leadingAnchor.constraint(equalTo: cell!.leadingAnchor, constant: 8),
                textField.trailingAnchor.constraint(equalTo: cell!.trailingAnchor, constant: -8),
                textField.topAnchor.constraint(equalTo: cell!.topAnchor),
                textField.bottomAnchor.constraint(equalTo: cell!.bottomAnchor)
            ])
        } else {
            cell?.textField?.stringValue = item.content
        }

        return cell
    }

    func tableViewSelectionDidChange(_ notification: Notification) {
        guard tableView.selectedRow >= 0 else { return }
        let item = HistoryManager.shared.items[tableView.selectedRow]
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(item.content, forType: .string)
    }
}
