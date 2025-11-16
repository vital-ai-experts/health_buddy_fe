import UIKit
import SwiftUI

/// UICollectionView-based message list with smart scrolling and history loading support
public final class MessageListCollectionView: UICollectionView {

    // MARK: - Types

    typealias DataSource = UICollectionViewDiffableDataSource<Section, MessageItem>
    typealias Snapshot = NSDiffableDataSourceSnapshot<Section, MessageItem>

    enum Section {
        case main
    }

    // MARK: - Properties

    private var diffableDataSource: DataSource!
    private var messages: [MessageItem] = []

    // Scroll tracking
    private var isUserScrolling = false
    private var shouldAutoScroll = true
    private var lastContentHeight: CGFloat = 0

    // Callbacks
    public var onLoadMoreHistory: (() -> Void)?
    public var onHealthProfileConfirm: (() -> Void)?
    public var onHealthProfileReject: (() -> Void)?
    public var onRetry: ((String) -> Void)?  // Retry callback with failed message ID

    // Configuration
    public var configuration: ChatConfiguration = .default

    // MARK: - Initialization

    public init() {
        // Create compositional layout
        let layout = Self.createLayout()
        super.init(frame: .zero, collectionViewLayout: layout)

        setupCollectionView()
        setupDataSource()
        setupScrollObserver()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Setup

    private func setupCollectionView() {
        backgroundColor = .systemBackground
        delegate = self
        alwaysBounceVertical = true
        keyboardDismissMode = .interactive

        // Enable automatic height calculation but limit invalidation scope
        if #available(iOS 16.0, *) {
            // 使用 .enabled 而不是 .enabledIncludingConstraints
            // 这样可以减少布局刷新的范围，避免影响其他 cell
            selfSizingInvalidation = .enabled
        }
    }

    private static func createLayout() -> UICollectionViewCompositionalLayout {
        // 使用更精细的布局配置来减少全局刷新
        let itemSize = NSCollectionLayoutSize(
            widthDimension: .fractionalWidth(1.0),
            heightDimension: .estimated(100)  // 使用估算高度
        )
        let item = NSCollectionLayoutItem(layoutSize: itemSize)

        let groupSize = NSCollectionLayoutSize(
            widthDimension: .fractionalWidth(1.0),
            heightDimension: .estimated(100)
        )
        let group = NSCollectionLayoutGroup.horizontal(layoutSize: groupSize, subitems: [item])

        let section = NSCollectionLayoutSection(group: group)
        section.interGroupSpacing = 0  // 卡片间距

        let layout = UICollectionViewCompositionalLayout(section: section)

        // 配置布局更新时的行为
        let configuration = UICollectionViewCompositionalLayoutConfiguration()
        configuration.scrollDirection = .vertical
        layout.configuration = configuration

        return layout
    }

    private func setupDataSource() {
        // Cell registrations
        let userCellRegistration = createUserCellRegistration()
        let systemCellRegistration = createSystemCellRegistration()
        let loadingCellRegistration = createLoadingCellRegistration()
        let errorCellRegistration = createErrorCellRegistration()

        // Create data source
        diffableDataSource = DataSource(collectionView: self) { collectionView, indexPath, item in
            switch item {
            case .user:
                return collectionView.dequeueConfiguredReusableCell(
                    using: userCellRegistration,
                    for: indexPath,
                    item: item
                )
            case .system:
                return collectionView.dequeueConfiguredReusableCell(
                    using: systemCellRegistration,
                    for: indexPath,
                    item: item
                )
            case .loading:
                return collectionView.dequeueConfiguredReusableCell(
                    using: loadingCellRegistration,
                    for: indexPath,
                    item: item
                )
            case .error:
                return collectionView.dequeueConfiguredReusableCell(
                    using: errorCellRegistration,
                    for: indexPath,
                    item: item
                )
            }
        }
    }

    private func setupScrollObserver() {
        // Observe content size changes
        addObserver(self, forKeyPath: #keyPath(UICollectionView.contentSize), options: [.new], context: nil)
    }

    deinit {
        removeObserver(self, forKeyPath: #keyPath(UICollectionView.contentSize))
    }

    // MARK: - Cell Registrations

    private func createUserCellRegistration() -> UICollectionView.CellRegistration<UICollectionViewCell, MessageItem> {
        UICollectionView.CellRegistration<UICollectionViewCell, MessageItem> { [weak self] cell, indexPath, item in
            guard case .user(let message) = item,
                  let self = self else { return }

            cell.contentConfiguration = UIHostingConfiguration {
                UserMessageView(message: message, configuration: self.configuration)
            }
            .margins(.all, 0)

            cell.backgroundColor = .clear
        }
    }

    private func createSystemCellRegistration() -> UICollectionView.CellRegistration<UICollectionViewCell, MessageItem> {
        UICollectionView.CellRegistration<UICollectionViewCell, MessageItem> { [weak self] cell, indexPath, item in
            guard case .system(let message) = item,
                  let self = self else { return }

            cell.contentConfiguration = UIHostingConfiguration {
                SystemMessageView(
                    message: message,
                    configuration: self.configuration,
                    onHealthProfileConfirm: self.onHealthProfileConfirm,
                    onHealthProfileReject: self.onHealthProfileReject
                )
            }
            .margins(.all, 0)

            cell.backgroundColor = .clear
        }
    }

    private func createLoadingCellRegistration() -> UICollectionView.CellRegistration<UICollectionViewCell, MessageItem> {
        UICollectionView.CellRegistration<UICollectionViewCell, MessageItem> { [weak self] cell, indexPath, item in
            guard case .loading(let loading) = item,
                  let self = self else { return }

            cell.contentConfiguration = UIHostingConfiguration {
                SystemLoadingView(loading: loading, configuration: self.configuration)
            }
            .margins(.all, 0)

            cell.backgroundColor = .clear
        }
    }

    private func createErrorCellRegistration() -> UICollectionView.CellRegistration<UICollectionViewCell, MessageItem> {
        UICollectionView.CellRegistration<UICollectionViewCell, MessageItem> { [weak self] cell, indexPath, item in
            guard case .error(let error) = item,
                  let self = self else { return }

            cell.contentConfiguration = UIHostingConfiguration {
                SystemErrorView(error: error, configuration: self.configuration) {
                    // Call retry callback with failed message ID
                    if let messageId = error.failedMessageId {
                        self.onRetry?(messageId)
                    }
                }
            }
            .margins(.all, 0)

            cell.backgroundColor = .clear
        }
    }

    // MARK: - Content Size Observer

    public override func observeValue(
        forKeyPath keyPath: String?,
        of object: Any?,
        change: [NSKeyValueChangeKey : Any]?,
        context: UnsafeMutableRawPointer?
    ) {
        if keyPath == #keyPath(UICollectionView.contentSize) {
            handleContentSizeChange()
        }
    }

    private func handleContentSizeChange() {
        let currentHeight = contentSize.height
        let heightDiff = currentHeight - lastContentHeight

        // Only auto-scroll if user is at bottom and content is growing
        if shouldAutoScroll && heightDiff > 0 {
            scrollToBottom(animated: true)
        }

        lastContentHeight = currentHeight
    }

    // MARK: - Public Methods

    /// Updates the message list
    public func updateMessages(_ newMessages: [MessageItem], animated: Bool = true) {
        let oldMessages = messages
        messages = newMessages

        // Detect if we're adding to the top (history load)
        let isHistoryLoad = detectHistoryLoad(old: oldMessages, new: newMessages)

        // Create snapshot
        var snapshot = Snapshot()
        snapshot.appendSections([.main])
        snapshot.appendItems(newMessages, toSection: .main)

        if isHistoryLoad {
            // Preserve scroll position when loading history
            preserveScrollPositionDuringHistoryLoad(oldMessages: oldMessages, newMessages: newMessages) {
                self.diffableDataSource.apply(snapshot, animatingDifferences: animated)
            }
        } else {
            // Normal update
            diffableDataSource.apply(snapshot, animatingDifferences: animated) {
                // Auto-scroll to bottom on first load or when at bottom
                if oldMessages.isEmpty || self.shouldAutoScroll {
                    self.scrollToBottom(animated: animated)
                }
            }
        }
    }

    /// Scrolls to the bottom of the list
    public func scrollToBottom(animated: Bool) {
        guard !messages.isEmpty else { return }

        let lastIndexPath = IndexPath(item: messages.count - 1, section: 0)
        scrollToItem(at: lastIndexPath, at: .bottom, animated: animated)
    }

    // MARK: - History Loading

    private func detectHistoryLoad(old: [MessageItem], new: [MessageItem]) -> Bool {
        guard !old.isEmpty && !new.isEmpty else { return false }

        // Check if new messages start with items not in old messages
        // and old messages are contained at the end of new messages
        let oldFirstId = old.first?.id
        let newFirstId = new.first?.id

        return oldFirstId != newFirstId && new.count > old.count
    }

    private func preserveScrollPositionDuringHistoryLoad(
        oldMessages: [MessageItem],
        newMessages: [MessageItem],
        applySnapshot: @escaping () -> Void
    ) {
        // Find the first visible item before update
        guard let firstVisibleIndexPath = indexPathsForVisibleItems.sorted().first,
              firstVisibleIndexPath.item < oldMessages.count else {
            applySnapshot()
            return
        }

        let firstVisibleMessage = oldMessages[firstVisibleIndexPath.item]
        let offsetBefore = contentOffset.y

        // Apply the snapshot
        applySnapshot()

        // Find the same message in new data
        DispatchQueue.main.async {
            if let newIndex = newMessages.firstIndex(where: { $0.id == firstVisibleMessage.id }) {
                let newIndexPath = IndexPath(item: newIndex, section: 0)

                // Scroll to maintain the same visible message
                self.scrollToItem(at: newIndexPath, at: .top, animated: false)

                // Fine-tune the offset
                let offsetAfter = self.contentOffset.y
                let adjustment = offsetBefore - offsetAfter
                self.contentOffset.y += adjustment
            }
        }
    }
}

// MARK: - UICollectionViewDelegate

extension MessageListCollectionView: UICollectionViewDelegate {

    public func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        isUserScrolling = true
    }

    public func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        if !decelerate {
            isUserScrolling = false
            updateAutoScrollState()
        }
    }

    public func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        isUserScrolling = false
        updateAutoScrollState()
    }

    public func scrollViewDidScroll(_ scrollView: UIScrollView) {
        // Check if user scrolled to top (for loading more history)
        if scrollView.contentOffset.y < 100 && !isUserScrolling {
            onLoadMoreHistory?()
        }

        updateAutoScrollState()
    }

    private func updateAutoScrollState() {
        // Check if user is near bottom
        let threshold: CGFloat = 100
        let bottomOffset = contentSize.height - (contentOffset.y + bounds.height)
        shouldAutoScroll = bottomOffset < threshold
    }

    public func scrollViewDidScrollToTop(_ scrollView: UIScrollView) {
        onLoadMoreHistory?()
    }
}
