import Apps
import Bonzai
import Inject
import SwiftUI

struct IconMenuStyle: MenuStyle {
  func makeBody(configuration: Configuration) -> some View {
    Menu(configuration)
      .menuStyle(.borderlessButton)
      .menuIndicator(.hidden)
  }
}

struct ApplicationCommandView: View {
  @ObserveInjection var inject
  enum Action {
    case changeApplication(Application)
    case updateName(newName: String)
    case changeApplicationModifier(modifier: ApplicationCommand.Modifier, newValue: Bool)
    case changeApplicationAction(ApplicationCommand.Action)
    case commandAction(CommandContainerAction)
  }

  @State private var metaData: CommandViewModel.MetaData
  @State private var model: CommandViewModel.Kind.ApplicationModel

  private let debounce: DebounceManager<String>

  @EnvironmentObject var applicationStore: ApplicationStore

  private let iconSize: CGSize
  private let onAction: (Action) -> Void

  init(_ metaData: CommandViewModel.MetaData,
       model: CommandViewModel.Kind.ApplicationModel,
       iconSize: CGSize,
       onAction: @escaping (Action) -> Void) {
    _metaData = .init(initialValue: metaData)
    _model = .init(initialValue: model)
    self.onAction = onAction
    self.iconSize = iconSize
    self.debounce = DebounceManager(for: .milliseconds(500)) { newName in
      onAction(.updateName(newName: newName))
    }
  }

  var body: some View {
    CommandContainerView(
      $metaData,
      placeholder: model.placheolder,
      icon: { metaData in
        ApplicationCommandImageView(metaData.wrappedValue, iconSize: iconSize, onAction: onAction)
      },
      content: { command in
        HStack(spacing: 8) {
          Menu(content: {
            Button(action: {
              model.action = "Open"
              onAction(.changeApplicationAction(.open))
            }, label: {
              Image(systemName: "power")
              Text("Open")
                .font(.subheadline)
            })

            Button(action: {
              model.action = "Close"
              onAction(.changeApplicationAction(.close))
            }, label: {
              Image(systemName: "poweroff")
              Text("Close")
                .font(.subheadline)
            })
          }, label: {
            Text(model.action)
              .font(.caption)
              .fixedSize(horizontal: false, vertical: true)
              .truncationMode(.middle)
              .allowsTightening(true)
          })
          .menuStyle(.zen(.init(color: .systemGray)))
          .fixedSize()
          .compositingGroup()

          ZenCheckbox("In background", style: .small, isOn: $model.inBackground) { newValue in
            onAction(.changeApplicationModifier(modifier: .background, newValue: newValue))
          }
          ZenCheckbox("Hide when opening", style: .small, isOn: $model.hideWhenRunning) { newValue in
            onAction(.changeApplicationModifier(modifier: .hidden, newValue: newValue))
          }
          ZenCheckbox("If not running", style: .small, isOn: $model.ifNotRunning) { newValue in
            onAction(.changeApplicationModifier(modifier: .onlyIfNotRunning, newValue: newValue))
          }
        }
        .buttonStyle(.regular)
        .lineLimit(1)
        .allowsTightening(true)
        .truncationMode(.tail)
        .font(.caption)
      }, subContent: { _ in },
      onAction: { onAction(.commandAction($0)) })
    .id(metaData.id)
    .enableInjection()
  }
}

struct ApplicationCommandImageView: View {
  @ObserveInjection var inject
  @EnvironmentObject var applicationStore: ApplicationStore
  @State private var isHovered: Bool = false
  @State private var metaData: CommandViewModel.MetaData
  private let onAction: (ApplicationCommandView.Action) -> Void
  private let iconSize: CGSize

  init(_ metaData: CommandViewModel.MetaData,
       iconSize: CGSize,
       onAction: @escaping (ApplicationCommandView.Action) -> Void) {
    _metaData = .init(initialValue: metaData)
    self.iconSize = iconSize
    self.onAction = onAction
  }

  var body: some View {
    Menu(content: {
      ForEach(applicationStore.applications.lazy, id: \.path) { app in
        Button(action: {
          onAction(.changeApplication(app))
          metaData.icon = .init(bundleIdentifier: app.bundleIdentifier, path: app.path)
        }, label: {
          if app.metadata.isSafariWebApp {
            Text("\(app.displayName) (Safari Web App)")
          } else {
            Text(app.displayName)
          }
        })
      }
    }, label: { })
    .contentShape(Rectangle())
    .menuStyle(IconMenuStyle())
    .padding(4)
    .overlay(content: {
      if let icon = metaData.icon {
        IconView(icon: icon, size: iconSize)
          .fixedSize()
          .allowsHitTesting(false)
      }
    })
    .enableInjection()
  }
}

struct ApplicationCommandView_Previews: PreviewProvider {
  static let command = DesignTime.applicationCommand
  static var previews: some View {
    ApplicationCommandView(command.model.meta, model: command.kind, iconSize: .init(width: 24, height: 24)) { _ in }
      .designTime()
  }
}
