import Cocoa
import Combine
import SwiftUI
import ModelKit

class KeyboardShortcutRecorderView: NSSearchField {
  typealias OnCommit = (KeyboardShortcutRecorderView, ModelKit.KeyboardShortcut?) -> Void

  @State private var keyboardShortcut: ModelKit.KeyboardShortcut?
  private var cancellables = Set<AnyCancellable>()
  private let viewController: KeyboardShortcutRecorderViewController
  private let onCommit: OnCommit

  required init(keyboardShortcut: ModelKit.KeyboardShortcut?,
                placeholder: String? = nil,
                onCommit: @escaping OnCommit) {
    self.viewController = KeyboardShortcutRecorderViewController(keyboardShortcut: keyboardShortcut)
    self.keyboardShortcut = keyboardShortcut
    self.onCommit = onCommit
    super.init(frame: .zero)
    self.placeholderString = placeholder
    self.centersPlaceholder = true
    self.alignment = .center
    self.delegate = viewController
    (self.cell as? NSSearchFieldCell)?.searchButtonCell = nil
    self.update(keyboardShortcut)

    self.viewController.onCommit = { [weak self] keyboardShortcut in
      guard let self = self else { return }
      self.update(keyboardShortcut)
      self.onCommit(self, keyboardShortcut)
    }
  }

  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  func update(_ keyboardShortcut: ModelKit.KeyboardShortcut?) {
    guard let keyboardShortcut = keyboardShortcut else {
      stringValue = ""
      return
    }

    var newValue = keyboardShortcut.modifiers?.compactMap({ $0.pretty }).joined() ?? ""
    newValue += keyboardShortcut.key

    stringValue = newValue
  }

  override func becomeFirstResponder() -> Bool {
    let shouldBecomeFirstResponder = super.becomeFirstResponder()

    guard shouldBecomeFirstResponder else {
      return shouldBecomeFirstResponder
    }

    viewController.didBecomeFirstResponder()
    return true
  }
}

struct Recorder: NSViewRepresentable {
  typealias OnCommit = (ModelKit.KeyboardShortcut?) -> Void
  typealias NSViewType = KeyboardShortcutRecorderView

  @Binding var keyboardShortcut: ModelKit.KeyboardShortcut?

  func makeNSView(context: Context) -> KeyboardShortcutRecorderView {
    KeyboardShortcutRecorderView(keyboardShortcut: keyboardShortcut,
                                 placeholder: "Record Keyboard Shortcut",
                                 onCommit: { view, model in
                                  view.resignFirstResponder()
                                  keyboardShortcut = model
                                 })
  }

  func updateNSView(_ nsView: KeyboardShortcutRecorderView, context: Context) {}
}

// MARK: - Previews

struct Recorder_Previews: PreviewProvider, TestPreviewProvider {
  static var previews: some View {
    testPreview.previewAllColorSchemes()
  }

  static var testPreview: some View {
    SwiftUI.Group {
      Recorder(keyboardShortcut: .constant(nil))
      Recorder(keyboardShortcut: .constant(ModelKit.KeyboardShortcut(key: "F",
                                                                     modifiers: [.command, .option])))
    }
  }
}
