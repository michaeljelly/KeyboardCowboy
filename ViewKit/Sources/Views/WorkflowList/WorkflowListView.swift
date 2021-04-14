import SwiftUI
import ModelKit

struct WorkflowListView: View {
  let workflow: Workflow
  @State private var isHovering: Bool = false

  var body: some View {
    VStack(alignment: .center, spacing: 0) {
      HStack(alignment: .center) {
        VStack(alignment: .leading, spacing: 3) {
          name
          HStack {
            numberOfCommands.font(.callout)
            switch workflow.trigger {
            case .keyboardShortcuts(let shortcuts):
              keyboardShortcuts(shortcuts).font(.caption)
            case .none:
              Spacer()
            }
          }
        }.frame(height: 48)
        Spacer()
        icon
      }.padding(.leading, 10)
      Divider().opacity(0.33)
    }
  }
}

// MARK: - Subviews

private extension WorkflowListView {
  var name: some View {
    Text(workflow.name)
      .foregroundColor(.primary)
  }

  var numberOfCommands: some View {
    Group {
    if workflow.commands.count > 1 {
      Text("\(workflow.commands.count) commands")
    } else if workflow.commands.count > 0 {
      Text("\(workflow.commands.count) command")
    }
    }.foregroundColor(.secondary)
  }

  @ViewBuilder
  func keyboardShortcuts(_ shortcuts: [ModelKit.KeyboardShortcut]) -> some View {
    if !shortcuts.isEmpty {
      Divider().frame(height: 10)
    }
    ForEach(shortcuts) { shortcut in
      KeyboardShortcutView(shortcut: shortcut)
    }
  }

  var icon: some View {
    ZStack {
      ForEach(0..<workflow.commands.count, id: \.self) { index in
        let command = workflow.commands[index]
        let cgIndex = CGFloat(index)
        let multiplierX = -cgIndex * 5 - 10
        let multiplierY = -cgIndex * 5
        let shadowRadius = max(cgIndex - 1, 0)
        let scale: CGFloat = isHovering
          ? workflow.commands.count > 1 ? 0.9 + ( 0.05 * cgIndex) : 1.0
          : 1.0

        IconView(path: command.icon)
          .frame(width: 32, height: 32)
          .scaleEffect(scale, anchor: .center)
          .offset(x: isHovering ?  multiplierX : -10,
                  y: isHovering ? multiplierY : 0)
          .rotationEffect(.degrees( isHovering ? -Double(index) * 10 : 0 ))
          .shadow(color: Color(NSColor.black).opacity( isHovering ? 0.025 : 0.005),
                  radius: isHovering ? shadowRadius : 3,
                  x: isHovering ? -multiplierX : 0,
                  y: isHovering ? -multiplierY : 1)
          .onHover { value in
            withAnimation(.easeInOut(duration: 0.15)) {
              if isHovering != value { isHovering = value }
            }
          }
      }
    }
  }
}

// MARK: - Previews

struct WorkflowListView_Previews: PreviewProvider, TestPreviewProvider {
  static var previews: some View {
    testPreview.previewAllColorSchemes()
  }

  static var testPreview: some View {
    let models = [
      Command.application(.init(application: Application.messages())),
      Command.script(.appleScript(id: UUID().uuidString, name: nil, source: .path("path/to/applescript.scpt"))),
      Command.script(.shell(id: UUID().uuidString, name: nil, source: .path("path/to/script.sh"))),
      Command.keyboard(KeyboardCommand(keyboardShortcut: KeyboardShortcut.empty())),
      Command.open(OpenCommand(path: "http://www.github.com")),
      Command.open(OpenCommand.empty())
    ]

    return Group {
      ForEach(models) { command in
        WorkflowListView(workflow: ModelFactory().workflowDetail(
          [command], name: command.name
        ))
      }
    }
  }
}
