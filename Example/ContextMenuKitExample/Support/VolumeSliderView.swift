import UIKit

/// A slider between two speaker icons for an interactive custom menu item.
/// Reports every change and doesn't close the menu.
final class VolumeSliderView: UIView {
    private enum Constants {
        static let insets = NSDirectionalEdgeInsets(top: 12, leading: 16, bottom: 12, trailing: 16)
    }

    init(value: Float, onChange: @escaping @MainActor (Float) -> Void) {
        super.init(frame: .zero)

        let slider = UISlider()
        slider.value = value
        slider.minimumValueImage = Self.icon(named: "speaker.fill")
        slider.maximumValueImage = Self.icon(named: "speaker.wave.3.fill")
        slider.accessibilityLabel = "Volume"
        slider.addAction(
            UIAction { action in
                guard let slider = action.sender as? UISlider else {
                    return
                }
                onChange(slider.value)
            },
            for: .valueChanged
        )
        slider.translatesAutoresizingMaskIntoConstraints = false
        addSubview(slider)

        NSLayoutConstraint.activate([
            slider.topAnchor.constraint(equalTo: topAnchor, constant: Constants.insets.top),
            slider.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -Constants.insets.bottom),
            slider.leadingAnchor.constraint(equalTo: leadingAnchor, constant: Constants.insets.leading),
            slider.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -Constants.insets.trailing)
        ])
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        nil
    }

    private static func icon(named systemName: String) -> UIImage? {
        UIImage(systemName: systemName)?.withTintColor(.secondaryLabel, renderingMode: .alwaysOriginal)
    }
}
