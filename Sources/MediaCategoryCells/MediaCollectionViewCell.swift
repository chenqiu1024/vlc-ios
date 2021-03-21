/*****************************************************************************
 * MediaCollectionViewCell.swift
 * VLC for iOS
 *****************************************************************************
 * Copyright (c) 2018 VideoLAN. All rights reserved.
 * $Id$
 *
 * Authors: Carola Nitz <nitz.carola # googlemail.com>
 *
 * Refer to the COPYING file of the official project for license.
 *****************************************************************************/

import Foundation

// MARK: - Delegate
protocol MediaCollectionViewCellDelegate: AnyObject {
    func mediaCollectionViewCellHandleDelete(of cell: MediaCollectionViewCell)
    func mediaCollectionViewCellMediaTapped(in cell: MediaCollectionViewCell)
    func mediaCollectionViewCellSetScrolledCellIndex(of cell: MediaCollectionViewCell?)
    func mediaCollectionViewCellGetScrolledCell() -> MediaCollectionViewCell?
}

// MARK: -
class MediaCollectionViewCell: BaseCollectionViewCell, UIScrollViewDelegate {

    @IBOutlet weak var thumbnailView: UIImageView!
    @IBOutlet private(set) weak var titleLabel: VLCMarqueeLabel!
    @IBOutlet private(set) weak var descriptionLabel: VLCMarqueeLabel!
    @IBOutlet private(set) weak var newLabel: UILabel!
    @IBOutlet weak var deleteButton: UIButton!
    @IBOutlet private(set) weak var thumbnailWidth: NSLayoutConstraint!
    @IBOutlet private(set) weak var sizeLabel: UILabel!
    @IBOutlet weak var descriptionStackView: UIStackView!

    @IBOutlet weak var scrollView: UIScrollView!
    @IBOutlet weak var scrollContentView: UIView!
    @IBOutlet weak var checkboxImageView: UIImageView!
    @IBOutlet weak var selectionOverlay: UIView!
    @IBOutlet weak var dragIndicatorImageView: UIImageView!

    private var separatorLabel: UILabel = UILabel()

    private var maxXOffset: CGFloat = 0.0
    private var vibrationTriggered: Bool = false
    private var isDeleteDisplayed: Bool = false
    private var hasXGoneNegative: Bool = false

    weak var delegate: MediaCollectionViewCellDelegate?

    override var media: VLCMLObject? {
        didSet {
            if let media = media as? VLCMLMedia {
                if media.subtype() == .albumTrack {
                    update(audiotrack: media)
                } else {
                    update(movie: media)
                }
            } else if let album = media as? VLCMLAlbum {
                update(album:album)
            } else if let artist = media as? VLCMLArtist {
                update(artist:artist)
            } else if let playlist = media as? VLCMLPlaylist {
                update(playlist: playlist)
            } else if let genre = media as? VLCMLGenre {
                update(genre: genre)
            } else if let mediaGroup = media as? VLCMLMediaGroup {
                update(mediaGroup: mediaGroup)
            } else {
                assertionFailure("MovieCollectionViewCell: media: Needs to be of a supported Type.")
            }
        }
    }

    override var checkImageView: UIImageView? {
        return checkboxImageView
    }

    override var selectionViewOverlay: UIView? {
        return selectionOverlay
    }

    override var descriptionSeparatorLabel: UILabel? {
        return separatorLabel
    }

    override var secondDescriptionLabelView: UILabel? {
        return sizeLabel
    }

    override var isSelected: Bool {
        didSet {
            checkboxImageView.image = isSelected ? UIImage(named: "checkboxSelected")
                : UIImage(named: "checkboxEmpty")
        }
    }

    private var enableMarquee: Bool {
        return !UserDefaults.standard.bool(forKey: kVLCSettingEnableMediaCellTextScrolling)
    }


    private func setupScrollView() {
        scrollView.delegate = self
        scrollView.showsVerticalScrollIndicator = false
        scrollView.showsHorizontalScrollIndicator = false
        scrollView.isUserInteractionEnabled = true
    }

    private func setupGestureRecognizer() {
        let mediaTapGesture = UITapGestureRecognizer(target: self, action: #selector(mediaTapped))

        scrollContentView.addGestureRecognizer(mediaTapGesture)
    }


    @IBAction func deleteButtonPressed(_ sender: Any) {
        delegate?.mediaCollectionViewCellHandleDelete(of: self)
        resetScrollView()
    }

    @objc private func mediaTapped() {
        delegate?.mediaCollectionViewCellMediaTapped(in: self)
    }

    func resetScrollView() {
        let offset: CGPoint = CGPoint(x: 0, y: scrollView.contentOffset.y)
        scrollView.setContentOffset(offset, animated: true)
        isDeleteDisplayed = false
    }

    func disableScrollView() {
        if isDeleteDisplayed {
            resetScrollView()
        }
        scrollView.isScrollEnabled = false
        scrollView.isUserInteractionEnabled = false
    }

    func enableScrollView() {
        scrollView.isScrollEnabled = true
        scrollView.isUserInteractionEnabled = true
    }

    private func checkScrollView() {
        if let cell = delegate?.mediaCollectionViewCellGetScrolledCell() {
            if cell != self && cell.isDeleteDisplayed {
                cell.resetScrollView()
                delegate?.mediaCollectionViewCellSetScrolledCellIndex(of: cell)
            }
        }
    }

    func applyScrolling(x: CGFloat, y: CGFloat) {
        let offset = CGPoint(x: x, y: y)
        scrollView.setContentOffset(offset, animated: true)
    }

    func scrollViewWillBeginDecelerating(_ scrollView: UIScrollView) {
        var x: CGFloat = 0

        if hasXGoneNegative {
            // Disable the scroll view from bouncing to the right
            hasXGoneNegative = false
        } else if isDeleteDisplayed &&
                    (scrollView.contentOffset.x < maxXOffset || maxXOffset == 0) {
            // The user wants to hide the delet button or the delete button
            // is displayed and the user tapped outside of the button
            isDeleteDisplayed = false
        } else if !vibrationTriggered {
            // The user wants to display the delete button
            x = deleteButton.frame.width
            isDeleteDisplayed = true
            delegate?.mediaCollectionViewCellSetScrolledCellIndex(of: self)
        } else {
            // The user scrolled until the vibration
            vibrationTriggered = false
            scrollContentView.isHidden = false
            isDeleteDisplayed = false
            delegate?.mediaCollectionViewCellHandleDelete(of: self)
        }

        applyScrolling(x: x, y: scrollView.contentOffset.y)
    }

    func scrollViewDidEndScrollingAnimation(_ scrollView: UIScrollView) {
        maxXOffset = 0.0
    }

    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        if scrollView.contentOffset.x < 0 {
            scrollView.contentOffset.x = 0
            hasXGoneNegative = true
        }

        if maxXOffset < scrollView.contentOffset.x {
            checkScrollView()
            maxXOffset = scrollView.contentOffset.x
        }

        if scrollView.contentOffset.x >= deleteButton.frame.size.width + 30 {
            if #available(iOS 10.0, *), !vibrationTriggered {
                let impactFeedbackGenerator = UIImpactFeedbackGenerator(style: .light)
                impactFeedbackGenerator.prepare()
                impactFeedbackGenerator.impactOccurred()
            }

            vibrationTriggered = true
            scrollContentView.isHidden = true
        } else {
            vibrationTriggered = false
            scrollContentView.isHidden = false
        }
    }

    override func awakeFromNib() {
        super.awakeFromNib()
        if #available(iOS 11.0, *) {
            thumbnailView.accessibilityIgnoresInvertColors = true
        }
        newLabel.text = NSLocalizedString("NEW", comment: "")
        newLabel.textColor = PresentationTheme.current.colors.orangeUI
        titleLabel.labelize = enableMarquee
        descriptionLabel.labelize = enableMarquee
        separatorLabel.setContentCompressionResistancePriority(.required, for: .horizontal)
        separatorLabel.setContentHuggingPriority(.required, for: .horizontal)
        separatorLabel.font = sizeLabel.font
        let isIpad = UIDevice.current.userInterfaceIdiom == UIUserInterfaceIdiom.pad
        thumbnailWidth.constant = isIpad ? 72 : 56
        NotificationCenter.default.addObserver(self, selector: #selector(themeDidChange), name: .VLCThemeDidChangeNotification, object: nil)
        setupScrollView()
        setupGestureRecognizer()
        deleteButton.setTitle(NSLocalizedString("BUTTON_DELETE", comment: ""), for: .normal)
        deleteButton.accessibilityLabel = NSLocalizedString("BUTTON_DELETE", comment: "")
        deleteButton.accessibilityHint = NSLocalizedString("DELETE_HINT", comment: "")
        themeDidChange()
    }

    @objc fileprivate func themeDidChange() {
        scrollContentView.backgroundColor = PresentationTheme.current.colors.background
        backgroundColor = PresentationTheme.current.colors.background
        titleLabel?.textColor = PresentationTheme.current.colors.cellTextColor
        descriptionLabel?.textColor = PresentationTheme.current.colors.cellDetailTextColor
        sizeLabel.textColor = PresentationTheme.current.colors.cellDetailTextColor
        separatorLabel.textColor = PresentationTheme.current.colors.cellDetailTextColor
        dragIndicatorImageView.tintColor = PresentationTheme.current.colors.cellDetailTextColor
    }

    func update(audiotrack: VLCMLMedia) {
        titleLabel.text = audiotrack.title()
        accessibilityLabel = audiotrack.accessibilityText(editing: false)
        var descriptionText = audiotrack.albumTrackArtistName()
        if let albumTitle = audiotrack.albumTrack?.album?.title, !albumTitle.isEmpty {
            descriptionText += " - " + albumTitle
        }
        descriptionLabel.text = descriptionText
        newLabel.isHidden = !audiotrack.isNew
        thumbnailView.image = audiotrack.thumbnailImage()
        sizeLabel.text = audiotrack.formatSize()
        separatorLabel.text = "·"
        separatorLabel.isHidden = true
        descriptionStackView.insertArrangedSubview(separatorLabel, at: 1)
        scrollView.isScrollEnabled = true
    }

    func update(album: VLCMLAlbum) {
        newLabel.isHidden = true
        titleLabel.text = album.albumName()
        accessibilityLabel = album.accessibilityText(editing: false)
        descriptionLabel.text = album.albumArtistName()
        thumbnailView.image = album.thumbnail()
        scrollView.isScrollEnabled = false
    }

    func update(artist: VLCMLArtist) {
        newLabel.isHidden = true
        thumbnailView.layer.masksToBounds = true
        thumbnailView.layer.cornerRadius = thumbnailView.frame.size.width / 2.0
        titleLabel.text = artist.artistName()
        accessibilityLabel = artist.accessibilityText()
        descriptionLabel.text = artist.numberOfTracksString()
        thumbnailView.image = artist.thumbnail()
        scrollView.isScrollEnabled = false
    }

    func update(movie: VLCMLMedia) {
        titleLabel.text = movie.title()
        accessibilityLabel = movie.accessibilityText(editing: false)
        thumbnailView.layer.cornerRadius = 3
        thumbnailView.image = movie.thumbnailImage()
        newLabel.isHidden = !movie.isNew
        sizeLabel.text = movie.mediaDuration()
        descriptionLabel.text = movie.formatSize()
        sizeLabel.isHidden = false
        separatorLabel.text = "·"
        scrollView.isScrollEnabled = true
    }

    func update(playlist: VLCMLPlaylist) {
        newLabel.isHidden = true
        titleLabel.text = playlist.name
        accessibilityLabel = playlist.accessibilityText()
        descriptionLabel.text = playlist.numberOfTracksString()
        thumbnailView.layer.cornerRadius = 3
        thumbnailView.image = playlist.thumbnail()
        dragIndicatorImageView.image = UIImage(named: "disclosureChevron")
        dragIndicatorImageView.tintColor = PresentationTheme.current.colors.orangeUI
        dragIndicatorImageView.isHidden = false
        scrollView.isScrollEnabled = true
    }

    func update(mediaGroup: VLCMLMediaGroup) {
        if mediaGroup.nbMedia() == 1 && !mediaGroup.userInteracted() {
            guard let media = mediaGroup.media(of: .video)?.first else {
                assertionFailure("EditActions: rename: Failed to retrieve media.")
                return
            }

            update(movie: media)
            return
        }

        descriptionLabel.text = mediaGroup.numberOfTracksString()
        titleLabel.text = mediaGroup.title()
        accessibilityLabel = mediaGroup.accessibilityText()
        sizeLabel.text = String(mediaGroup.duration())
        accessibilityLabel = mediaGroup.accessibilityText()

        thumbnailView.layer.cornerRadius = 3
        thumbnailView.image = mediaGroup.thumbnail()
        dragIndicatorImageView.image = UIImage(named: "disclosureChevron")
        dragIndicatorImageView.tintColor = PresentationTheme.current.colors.orangeUI

        newLabel.isHidden = true
        dragIndicatorImageView.isHidden = false
        scrollView.isScrollEnabled = true
    }

    func update(genre: VLCMLGenre) {
        newLabel.isHidden = true
        titleLabel.text = genre.name
        accessibilityLabel = genre.accessibilityText()

        thumbnailView.image = genre.thumbnail()
        descriptionLabel.text = genre.numberOfTracksString()
        scrollView.isScrollEnabled = false
    }

    override class func numberOfColumns(for width: CGFloat) -> CGFloat {
        if width <= DeviceWidth.iPhone12ProMaxPortrait.rawValue {
            return 1
        } else if width <= DeviceWidth.iPadLandscape.rawValue {
            return 2
        } else {
            return 3
        }
    }

    override class func cellSizeForWidth(_ width: CGFloat) -> CGSize {
        let numberOfCells: CGFloat = numberOfColumns(for: width)

        // We have the number of cells and we always have numberofCells + 1 interItemPadding spaces.
        //
        // edgePadding-interItemPadding-[Cell]-interItemPadding-[Cell]-interItemPadding-edgePadding
        //

        let overallWidth = (numberOfCells == 1) ? width - edgePadding : width - (2 * edgePadding)
        let overallCellWidthWithoutPadding = overallWidth - (numberOfCells + 1) * interItemPadding
        let cellWidth = floor(overallCellWidthWithoutPadding / numberOfCells)

        let isIpad = UIDevice.current.userInterfaceIdiom == UIUserInterfaceIdiom.pad
        return CGSize(width: cellWidth, height: isIpad ? 94 : 60)
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        titleLabel.text = ""
        accessibilityLabel = ""
        descriptionLabel.text = ""
        titleLabel.labelize = enableMarquee
        descriptionLabel.labelize = enableMarquee
        thumbnailView.image = nil
        thumbnailView.contentMode = .scaleAspectFill
        descriptionLabel.isHidden = false
        newLabel.isHidden = true
        checkboxImageView.isHidden = true
        selectionOverlay.isHidden = true
        dragIndicatorImageView.image = UIImage(named: "list")
        dragIndicatorImageView.isHidden = true
        sizeLabel.isHidden = true
        separatorLabel.isHidden = true
        enableScrollView()
    }
}
