import Apps
import Bonzai
import Inject
import SwiftUI

struct OpenCommandView: View {
  @ObserveInjection var inject
  enum Action {
    case updatePath(newPath: String)
    case openWith(Application?)
    case commandAction(CommandContainerAction)
    case reveal(path: String)
  }
  @State var metaData: CommandViewModel.MetaData
  @State var model: CommandViewModel.Kind.OpenModel
  private let iconSize: CGSize
  private let debounce: DebounceManager<String>
  private let onAction: (Action) -> Void

  init(_ metaData: CommandViewModel.MetaData,
       model: CommandViewModel.Kind.OpenModel,
       iconSize: CGSize,
       onAction: @escaping (Action) -> Void) {
    _metaData = .init(initialValue: metaData)
    _model = .init(initialValue: model)
    self.iconSize = iconSize
    self.debounce = DebounceManager(for: .milliseconds(500)) { newPath in
      onAction(.updatePath(newPath: newPath))
    }
    self.onAction = onAction
  }

  var body: some View {
    CommandContainerView($metaData, placeholder: model.placheolder, icon: { command in
      ZStack(alignment: .bottomTrailing) {
        switch command.icon.wrappedValue {
        case .some(let icon):
          IconView(icon: icon, size: iconSize)
          if let appPath = model.applicationPath {
            IconView(icon: .init(bundleIdentifier: appPath, path: appPath), 
                     size: iconSize.applying(.init(scaleX: 0.5, y: 0.5)))
              .shadow(radius: 3)
              .id("open-with-\(appPath)")
          }
        case .none:
          EmptyView()
        }
      }
    }, content: { command in
      HStack(spacing: 2) {
        TextField("", text: $model.path)
          .textFieldStyle(.regular(Color(.windowBackgroundColor)))
          .onChange(of: model.path, perform: { debounce.send($0) })
          .frame(maxWidth: .infinity)

        if !model.applications.isEmpty {
          Menu(content: {
            ForEach(model.applications) { app in
              Button(app.displayName, action: {
                model.appName = app.displayName
                model.applicationPath = app.path
                onAction(.openWith(app))
              })
            }
            Divider()
            Button("Default", action: {
              model.appName = nil
              model.applicationPath = nil
              onAction(.openWith(nil))
            })
          }, label: {
            Text(model.appName ?? "Default")
              .font(.caption)
              .truncationMode(.middle)
              .lineLimit(1)
              .allowsTightening(true)
              .padding(4)
          })
          .menuStyle(.zen(.init(color: .systemGray, grayscaleEffect: .constant(false))))
          .menuIndicator(model.applications.isEmpty ? .hidden : .visible)
          .fixedSize(horizontal: true, vertical: false)
        }
      }
    }, subContent: { command in
      HStack {
        if model.path.hasPrefix("http") == false {
          Button("Reveal", action: { onAction(.reveal(path: model.path)) })
            .buttonStyle(.zen(.init(color: .systemBlue)))
        }
      }
      .frame(maxWidth: .infinity, alignment: .leading)
      .font(.caption)
    }, onAction: { onAction(.commandAction($0)) })
    .enableInjection()
  }
}

struct OpenCommandView_Previews: PreviewProvider {
  static let command = DesignTime.openCommand
  static var previews: some View {
    OpenCommandView(command.model.meta, model: command.kind, iconSize: .init(width: 24, height: 24)) { _ in }
      .designTime()
  }
}
