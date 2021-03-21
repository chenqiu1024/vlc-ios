/*****************************************************************************
 * NewPlaybackSpeedView.swift
 *
 * Copyright © 2020 VLC authors and VideoLAN
 * Copyright © 2020 Videolabs
 *
 * Authors: Diogo Simao Marques <diogo.simaomarquespro@gmail.com>
 *
 * Refer to the COPYING file of the official project for license.
 *****************************************************************************/

import UIKit

protocol NewPlaybackSpeedViewDelegate: AnyObject {
    func newPlaybackSpeedViewHandleOptionChange(title: String)
    func newPlaybackSpeedViewShowIcon()
    func newPlaybackSpeedViewHideIcon()
}

class NewPlaybackSpeedView: UIView {

    @IBOutlet weak var minLabel: UILabel!
    @IBOutlet weak var currentButton: UIButton!
    @IBOutlet weak var maxLabel: UILabel!
    @IBOutlet weak var speedSlider: UISlider!
    @IBOutlet weak var increaseSpeedButton: UIButton!
    @IBOutlet weak var decreaseSpeedButton: UIButton!
    @IBOutlet weak var optionsSegmentedControl: UISegmentedControl!

    weak var delegate: NewPlaybackSpeedViewDelegate?

    private let minDelay: Float = -5000.0
    private let maxDelay: Float = 5000.0
    private let minSpeed: Float = 0.25
    private let maxSpeed: Float = 4.00

    private let increaseDelay: Float = 50.0
    private let decreaseDelay: Float = -50.0
    private let increaseSpeed: Float = 0.05
    private let decreaseSpeed: Float = -0.05

    private var currentSubtitlesDelay: Float = 0.0
    private var currentAudioDelay: Float = 0.0
    private var currentSpeed: Float = 1.0

    private let defaultDelay: Float = 0.0
    private let defaultSpeed: Float = 1.0

    let vpc = PlaybackService.sharedInstance()

    override func awakeFromNib() {
        super.awakeFromNib()

        themeDidChange()
        setupSegmentedControl()
    }


    private func themeDidChange() {
        minLabel.tintColor = PresentationTheme.current.colors.cellTextColor
        currentButton.setTitleColor(PresentationTheme.current.colors.orangeUI, for: .normal)
        maxLabel.tintColor = PresentationTheme.current.colors.cellTextColor
        speedSlider.tintColor = PresentationTheme.current.colors.orangeUI
        increaseSpeedButton.tintColor = PresentationTheme.current.colors.orangeUI
        decreaseSpeedButton.tintColor = PresentationTheme.current.colors.orangeUI
        self.backgroundColor = PresentationTheme.current.colors.background
    }


    private func setupSegmentedControl() {
        optionsSegmentedControl.setTitle(NSLocalizedString("PLAYBACK_SPEED", comment: ""), forSegmentAt: 0)
        optionsSegmentedControl.setTitle(NSLocalizedString("SPU_DELAY", comment: ""), forSegmentAt: 1)
        optionsSegmentedControl.setTitle(NSLocalizedString("AUDIO_DELAY", comment: ""), forSegmentAt: 2)

//        optionsSegmentedControl.accessibilityLabel =
//        optionsSegmentedControl.accessibilityHint =
        optionsSegmentedControl.selectedSegmentIndex = 0

        optionsSegmentedControl.addTarget(self, action: #selector(self.handleSegmentedControlChange(_:)), for: .valueChanged)
        handleSegmentedControlChange(optionsSegmentedControl)
    }


    private func setupSlider() {
        let selectedIndex = optionsSegmentedControl.selectedSegmentIndex
        var currentButtonText: String = ""

        if selectedIndex == 0 {
            speedSlider.minimumValue = minSpeed
            speedSlider.maximumValue = maxSpeed
            speedSlider.setValue(currentSpeed, animated: true)
            minLabel.text = String(minSpeed)
            maxLabel.text = String(maxSpeed)
            currentButtonText = String(format: "%.2fx", speedSlider.value)
        } else {
            speedSlider.minimumValue = minDelay
            speedSlider.maximumValue = maxDelay
            minLabel.text = String(minDelay)
            maxLabel.text = String(maxDelay)

            if selectedIndex == 1 {
                speedSlider.setValue(currentSubtitlesDelay, animated: true)
            } else {
                speedSlider.setValue(currentAudioDelay, animated: true)
            }

            currentButtonText = String(format: "%.0f ms", speedSlider.value)
        }

        currentButton.setTitle(currentButtonText, for: .normal)
    }


    @objc func handleSegmentedControlChange(_ control: UISegmentedControl) {
        let selectedIndex = control.selectedSegmentIndex
        delegate?.newPlaybackSpeedViewHandleOptionChange(title: optionsSegmentedControl.titleForSegment(at: selectedIndex)!)
        setupSlider()
    }


    @IBAction func handleSliderMovement(_ sender: UISlider) {
        let selectedIndex = optionsSegmentedControl.selectedSegmentIndex
        var currentValue: Float = speedSlider.value
        var currentButtonText: String = ""
        var showIcon: Bool = true

        if selectedIndex == 0 {
            currentSpeed = sender.value
            currentValue = currentSpeed
            currentButtonText = String(format: "%.2fx", currentValue)
            //vpc.playbackRate = exp2(currentValue)
            vpc.playbackRate = currentValue

            if currentValue == defaultSpeed {
                showIcon = false
            }
        } else if selectedIndex == 1 {
            currentSubtitlesDelay = sender.value
            currentValue = currentSubtitlesDelay
            currentButtonText = String(format: "%.0f ms", currentValue)
            //vpc.subtitleDelay = round(currentValue / 50) * 50
            vpc.subtitleDelay = currentValue

            if currentValue == defaultDelay {
                showIcon = false
            }
        } else {
            currentAudioDelay = sender.value
            currentValue = currentAudioDelay
            currentButtonText = String(format: "%.0f ms", currentValue)
            //vpc.audioDelay = round(currentValue / 50) * 50
            vpc.audioDelay = currentValue

            if currentValue == defaultDelay {
                showIcon = false
            }
        }

        currentButton.setTitle(currentButtonText, for: .normal)
        speedSlider.setValue(currentValue, animated: true)

        if showIcon {
            delegate?.newPlaybackSpeedViewShowIcon()
        }
    }

    func resetSlidersIfNeeded() {
        if vpc.playbackRate != currentSpeed ||
           round(vpc.subtitleDelay) != round(currentSubtitlesDelay) ||
           round(vpc.audioDelay) != round(currentAudioDelay) {
            optionsSegmentedControl.selectedSegmentIndex = 0

            currentSpeed = defaultSpeed
            currentSubtitlesDelay = defaultDelay
            currentAudioDelay = defaultDelay
            setupSlider()

            delegate?.newPlaybackSpeedViewHideIcon()
        }
    }

    @IBAction func handleResetTap(_ sender: UIButton) {
        let selectedIndex = optionsSegmentedControl.selectedSegmentIndex
        if selectedIndex == 0 {
            currentSpeed = defaultSpeed
            vpc.playbackRate = defaultSpeed
            currentButton.setTitle(String(format: "%.2fx", currentSpeed), for: .normal)
            speedSlider.setValue(currentSpeed, animated: true)
        } else if selectedIndex == 1 {
            currentSubtitlesDelay = defaultDelay
            vpc.subtitleDelay = defaultDelay
            currentButton.setTitle(String(format: "%.0f ms", currentSubtitlesDelay), for: .normal)
            speedSlider.setValue(currentSubtitlesDelay, animated: true)
        } else {
            currentAudioDelay = defaultDelay
            vpc.audioDelay = defaultDelay
            currentButton.setTitle(String(format: "%.0f ms", currentAudioDelay), for: .normal)
            speedSlider.setValue(currentAudioDelay, animated: true)
        }

        if currentSpeed == defaultSpeed && currentSubtitlesDelay == defaultDelay && currentAudioDelay == defaultDelay {
            delegate?.newPlaybackSpeedViewHideIcon()
        }
    }

    func reset() {
        currentSpeed = defaultSpeed
        vpc.playbackRate = currentSpeed

        currentSubtitlesDelay = defaultDelay
        vpc.subtitleDelay = currentSubtitlesDelay

        currentAudioDelay = defaultDelay
        vpc.audioDelay = currentAudioDelay

        setupSlider()
    }


    private func computeValue(currentValue: Float, offset: Float, lowerBound: Float, upperBound: Float) -> Float {
        let finalValue: Float = currentValue + offset
        if finalValue >= lowerBound && finalValue <= upperBound {
            return finalValue
        }

        return offset < 0 ? lowerBound : upperBound
    }


    @IBAction func handleIncreaseDecreaseButton(_ sender: UIButton) {
        let selectedIndex = optionsSegmentedControl.selectedSegmentIndex
        var currentValue: Float = speedSlider.value
        var currentButtonText: String = ""

        let speedOffset: Float = sender.tag == 1 ? increaseSpeed : decreaseSpeed
        let delayOffset: Float = sender.tag == 1 ? increaseDelay : decreaseDelay

        var showIcon: Bool = true

        if selectedIndex == 0 {
            currentSpeed = computeValue(currentValue: currentValue, offset: speedOffset, lowerBound: minSpeed, upperBound: maxSpeed)
            currentValue = currentSpeed
            currentButtonText = String(format: "%.2fx", currentValue)
            //vpc.playbackRate = exp2(currentValue)
            vpc.playbackRate = currentValue

            if currentValue == defaultSpeed {
                showIcon = false
            }
        } else {
            let finalValue = computeValue(currentValue: currentValue, offset: delayOffset, lowerBound: minDelay, upperBound: maxDelay)

            if selectedIndex == 1 {
                currentSubtitlesDelay = finalValue
                currentValue = currentSubtitlesDelay
                //vpc.subtitleDelay = round(currentValue / 50) * 50
                vpc.subtitleDelay = currentValue
            } else {
                currentAudioDelay = finalValue
                currentValue = currentAudioDelay
                //vpc.audioDelay = round(currentValue / 50) * 50
                vpc.audioDelay = currentValue
            }

            currentButtonText = String(format: "%.0f ms", currentValue)

            if currentValue == defaultDelay {
                showIcon = false
            }
        }

        currentButton.setTitle(currentButtonText, for: .normal)
        speedSlider.setValue(currentValue, animated: true)

        if showIcon {
            delegate?.newPlaybackSpeedViewShowIcon()
        }

        if currentSpeed == defaultSpeed && currentSubtitlesDelay == defaultDelay && currentAudioDelay == defaultDelay {
            delegate?.newPlaybackSpeedViewHideIcon()
        }
    }
}
