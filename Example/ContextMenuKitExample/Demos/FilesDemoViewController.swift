import ContextMenuKit
import UIKit

/// A grid of files whose menus follow the state of each file:
/// - the delegate builds the menu from the current state when it is asked for one: Favorite or Unfavorite,
///   Pin or Unpin (`if` in the builder), an action that depends on the kind of the file (`switch`);
/// - the actions change the data: a star appears, a pinned file moves to the top, a copy is inserted,
///   a deleted file goes away. They run once the preview is back in place, so the grid changes calmly;
/// - files in the left column get a menu aligned with their left edge, in the right column — with the right one
///   (`.automatic` alignment);
/// - on the way back the preview is clipped to the grid and doesn't fly over the navigation bar.
final class FilesDemoViewController: UIViewController, DemoScreen {
    private enum Section {
        case files
    }

    private enum Constants {
        /// The second file in the right column: its menu is aligned with the right edge.
        static let primaryFileIndex = 3
        static let tileHeight: CGFloat = 132
        static let tileSpacing: CGFloat = 12
        static let gridInset: CGFloat = 16
    }

    private var files = DemoFile.samples
    private lazy var collectionView = UICollectionView(frame: .zero, collectionViewLayout: makeLayout())
    private lazy var dataSource = makeDataSource()

    override func viewDidLoad() {
        super.viewDidLoad()
        title = Demo.files.title
        view.backgroundColor = .systemGroupedBackground
        navigationItem.largeTitleDisplayMode = .never

        collectionView.backgroundColor = .systemGroupedBackground
        collectionView.register(FileCell.self, forCellWithReuseIdentifier: FileCell.reuseIdentifier)
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(collectionView)

        NSLayoutConstraint.activate([
            collectionView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            collectionView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            collectionView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            collectionView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
        applySnapshot(animated: false)
    }

    func presentPrimaryMenu() {
        let indexPath = IndexPath(item: Constants.primaryFileIndex, section: 0)
        (collectionView.cellForItem(at: indexPath) as? FileCell)?.interaction.presentMenu()
    }

    // MARK: - Grid

    private func makeLayout() -> UICollectionViewLayout {
        // Two columns: each item is half of the row, the insets make the gap between the tiles.
        let halfSpacing = Constants.tileSpacing / 2
        let item = NSCollectionLayoutItem(
            layoutSize: NSCollectionLayoutSize(widthDimension: .fractionalWidth(0.5), heightDimension: .fractionalHeight(1))
        )
        item.contentInsets = NSDirectionalEdgeInsets(top: 0, leading: halfSpacing, bottom: 0, trailing: halfSpacing)
        let group = NSCollectionLayoutGroup.horizontal(
            layoutSize: NSCollectionLayoutSize(widthDimension: .fractionalWidth(1), heightDimension: .absolute(Constants.tileHeight)),
            subitems: [item]
        )
        let section = NSCollectionLayoutSection(group: group)
        section.interGroupSpacing = Constants.tileSpacing
        let sideInset = Constants.gridInset - halfSpacing
        section.contentInsets = NSDirectionalEdgeInsets(
            top: Constants.gridInset,
            leading: sideInset,
            bottom: Constants.gridInset,
            trailing: sideInset
        )
        return UICollectionViewCompositionalLayout(section: section)
    }

    private func makeDataSource() -> UICollectionViewDiffableDataSource<Section, UUID> {
        UICollectionViewDiffableDataSource(collectionView: collectionView) { [weak self] collectionView, indexPath, id in
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: FileCell.reuseIdentifier, for: indexPath)
            guard let self, let fileCell = cell as? FileCell, let file = file(withID: id) else {
                return cell
            }
            fileCell.configure(with: file)
            // The cell asks for the menu by the identifier: the menu reflects the state at the moment of the press.
            fileCell.menuConfigurationProvider = { [weak self] in
                self?.menuConfiguration(forFileWithID: id)
            }
            return fileCell
        }
    }

    private func applySnapshot(reconfiguring ids: [UUID] = [], animated: Bool = true) {
        var snapshot = NSDiffableDataSourceSnapshot<Section, UUID>()
        snapshot.appendSections([.files])
        snapshot.appendItems(files.map(\.id))
        snapshot.reconfigureItems(ids)
        dataSource.apply(snapshot, animatingDifferences: animated)
    }

    private func file(withID id: UUID) -> DemoFile? {
        files.first { $0.id == id }
    }

    // MARK: - Menu

    private func menuConfiguration(forFileWithID id: UUID) -> ContextMenuConfiguration? {
        guard let file = file(withID: id) else {
            return nil
        }
        let menu = ContextMenu {
            openingSection(for: file)
            organizingSection(for: file)
            ContextMenuSection {
                ContextMenuAction(title: "Delete", image: .system(.delete), isDestructive: true) { [weak self] in
                    self?.deleteFile(withID: id)
                }
            }
        }
        return ContextMenuConfiguration(
            menu: menu,
            clipping: .rect { [weak self] in
                guard let collectionView = self?.collectionView else {
                    return .infinite
                }
                return collectionView.convert(collectionView.bounds, to: nil)
            }
        )
    }

    /// Opening and sharing. The middle action depends on the kind of the file: `switch` in the builder.
    private func openingSection(for file: DemoFile) -> ContextMenuSection {
        ContextMenuSection {
            ContextMenuAction(title: "Quick Look", image: .system(.show)) { [weak self] in
                self?.showToast("Opened \(file.name)")
            }
            switch file.kind {
            case .document:
                ContextMenuAction(title: "Print", image: Self.image(named: "printer")) { [weak self] in
                    self?.showToast("Printing \(file.name)")
                }
            case .image:
                ContextMenuAction(title: "Save to Photos", image: .system(.save)) { [weak self] in
                    self?.showToast("Saved \(file.name)")
                }
            case .audio:
                ContextMenuAction(title: "Play", image: Self.image(named: "play")) { [weak self] in
                    self?.showToast("Playing \(file.name)")
                }
            case .archive:
                ContextMenuAction(title: "Uncompress", image: .system(.archive)) { [weak self] in
                    self?.showToast("Uncompressed \(file.name)")
                }
            }
            ContextMenuAction.toast("Share", image: .system(.share), in: view)
        }
    }

    /// Actions that change the file. The titles follow its state: `if` in the builder.
    private func organizingSection(for file: DemoFile) -> ContextMenuSection {
        let id = file.id
        return ContextMenuSection {
            if file.isFavorite {
                ContextMenuAction(title: "Unfavorite", image: .system(.unfavorite)) { [weak self] in
                    self?.toggleFavorite(ofFileWithID: id)
                }
            } else {
                ContextMenuAction(title: "Favorite", image: .system(.favorite)) { [weak self] in
                    self?.toggleFavorite(ofFileWithID: id)
                }
            }
            if file.isPinned {
                ContextMenuAction(title: "Unpin", image: .system(.unpin)) { [weak self] in
                    self?.togglePin(ofFileWithID: id)
                }
            } else {
                ContextMenuAction(title: "Pin", image: .system(.pin)) { [weak self] in
                    self?.togglePin(ofFileWithID: id)
                }
            }
            ContextMenuAction(title: "Duplicate", image: .system(.duplicate)) { [weak self] in
                self?.duplicateFile(withID: id)
            }
        }
    }

    private static func image(named systemName: String) -> ContextMenuImage? {
        UIImage(systemName: systemName).map(ContextMenuImage.custom)
    }

    // MARK: - Actions

    private func toggleFavorite(ofFileWithID id: UUID) {
        guard let index = files.firstIndex(where: { $0.id == id }) else {
            return
        }
        files[index].isFavorite.toggle()
        applySnapshot(reconfiguring: [id])
    }

    /// A pinned file goes to the top of the grid, an unpinned one — right after the pinned files.
    private func togglePin(ofFileWithID id: UUID) {
        guard let index = files.firstIndex(where: { $0.id == id }) else {
            return
        }
        var file = files.remove(at: index)
        file.isPinned.toggle()
        let destination = file.isPinned ? 0 : files.firstIndex { !$0.isPinned } ?? files.endIndex
        files.insert(file, at: destination)
        applySnapshot(reconfiguring: [id])
    }

    private func duplicateFile(withID id: UUID) {
        guard let index = files.firstIndex(where: { $0.id == id }) else {
            return
        }
        files.insert(files[index].copy(), at: index + 1)
        applySnapshot()
    }

    private func deleteFile(withID id: UUID) {
        files.removeAll { $0.id == id }
        applySnapshot()
    }

    private func showToast(_ text: String) {
        Toast.show(text, in: view)
    }
}
