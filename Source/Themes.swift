import UIKit
import Foundation

public protocol ThemeColor {
    var backgroundColor: UIColor { get }
    var btnTintColor: UIColor { get set }
    var iconBtnTintColor: UIColor { get set }
    var normalIconBtnTitleColor: UIColor { get set }
    var highlightedIconBtnTitleColor: UIColor { get set }
    var normalTextBtnTitleColor: UIColor { get set }
    var highlightedTextBtnTitleColor: UIColor { get set }
    var waveViewBackgroundColor: UIColor { get set }
    var waveNormalColor: UIColor { get set }
    var waveHighlightedColor: UIColor { get set }
}

public struct DarkTheme: ThemeColor {
    public var backgroundColor: UIColor = UIColor.clearColor()
    public var btnTintColor: UIColor = UIColor(white: 1, alpha: 0.9) // Configuration.defaultBlueTintColor
    public var iconBtnTintColor: UIColor = Configuration.defaultBlueTintColor
    public var normalIconBtnTitleColor: UIColor = UIColor(red: 255, green: 0, blue: 0, alpha: 0.9)
    public var highlightedIconBtnTitleColor: UIColor = UIColor.grayColor()
    public var normalTextBtnTitleColor: UIColor = UIColor(white: 1, alpha: 0.9)
    public var highlightedTextBtnTitleColor: UIColor = UIColor.grayColor()
    public var waveViewBackgroundColor: UIColor = UIColor.clearColor()
    public var waveNormalColor: UIColor = UIColor(red: 0, green: 118, blue: 255, alpha: 1)
    public var waveHighlightedColor: UIColor = Configuration.defaultBlueTintColor
}

public struct LightTheme: ThemeColor {
    public var backgroundColor: UIColor = UIColor.whiteColor()
    public var btnTintColor: UIColor = Configuration.defaultBlueTintColor
    public var iconBtnTintColor: UIColor = Configuration.defaultBlueTintColor
    public var normalIconBtnTitleColor: UIColor = UIColor(red: 255, green: 0, blue: 0, alpha: 0.9)
    public var highlightedIconBtnTitleColor: UIColor = UIColor.grayColor()
    public var normalTextBtnTitleColor: UIColor = Configuration.defaultBlueTintColor
    public var highlightedTextBtnTitleColor: UIColor = UIColor.grayColor()
    public var waveViewBackgroundColor: UIColor = UIColor.darkGrayColor()
    public var waveNormalColor: UIColor = UIColor(red: 0, green: 118, blue: 255, alpha: 1)
    public var waveHighlightedColor: UIColor = Configuration.defaultBlueTintColor
}

