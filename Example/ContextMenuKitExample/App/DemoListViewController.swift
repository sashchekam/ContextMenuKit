import UIKit

/// Root screen: the list of demos and the debug settings.
final class DemoListViewController: UITableViewController {
    private enum Section: Int, CaseIterable {
        case demos
        case settings
    }

    private enum Constants {
        static let cellIdentifier = "Cell"
        static let slowAnimationSpeed: Float = 0.1
    }

    init() {
        super.init(style: .insetGrouped)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        nil
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "ContextMenuKit"
        navigationItem.backButtonDisplayMode = .minimal
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: Constants.cellIdentifier)
    }

    override func numberOfSections(in tableView: UITableView) -> Int {
        Section.allCases.count
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch Section(rawValue: section) {
        case .demos:
            Demo.available.count
        case .settings:
            1
        case nil:
            0
        }
    }

    override func tableView(_ tableView: UITableView, titleForFooterInSection section: Int) -> String? {
        Section(rawValue: section) == .settings ? "Slows down all animations in the window ten times." : nil
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: Constants.cellIdentifier, for: indexPath)
        switch Section(rawValue: indexPath.section) {
        case .demos:
            configureDemoCell(cell, demo: Demo.available[indexPath.row])
        case .settings:
            configureSlowAnimationsCell(cell)
        case nil:
            break
        }
        return cell
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        guard Section(rawValue: indexPath.section) == .demos else {
            return
        }
        navigationController?.pushViewController(Demo.available[indexPath.row].makeViewController(), animated: true)
    }

    private func configureDemoCell(_ cell: UITableViewCell, demo: Demo) {
        var content = UIListContentConfiguration.subtitleCell()
        content.text = demo.title
        content.secondaryText = demo.subtitle
        content.secondaryTextProperties.color = .secondaryLabel
        cell.contentConfiguration = content
        cell.accessoryType = .disclosureIndicator
        cell.accessoryView = nil
        cell.selectionStyle = .default
    }

    private func configureSlowAnimationsCell(_ cell: UITableViewCell) {
        var content = UIListContentConfiguration.cell()
        content.text = "Slow animations"
        cell.contentConfiguration = content
        cell.selectionStyle = .none

        let toggle = UISwitch()
        toggle.isOn = view.window?.layer.speed == Constants.slowAnimationSpeed
        toggle.addAction(
            UIAction { [weak self] action in
                guard let toggle = action.sender as? UISwitch else {
                    return
                }
                self?.view.window?.layer.speed = toggle.isOn ? Constants.slowAnimationSpeed : 1
            },
            for: .valueChanged
        )
        cell.accessoryView = toggle
    }
}
