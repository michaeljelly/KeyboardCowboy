import Foundation
import AppKit
import MachPort

final class CommandEngine {
  struct Engines {
    let application: ApplicationEngine
    let keyboard: KeyboardEngine
    let open: OpenEngine
    let script: ScriptEngine
    let shortcut: ShortcutsEngine
    let type: TypeEngine
    let system: SystemCommandEngine
  }

  var machPort: MachPortEventController? {
    didSet {
      engines.keyboard.machPort = machPort
      if let machPort {
        engines.system.machPort = machPort
        engines.system.subscribe(to: machPort.$flagsChanged)
      }
    }
  }

  private let engines: Engines
  private let workspace: WorkspaceProviding
  private var runningTask: Task<Void, Error>?

  @MainActor
  var lastExecutedCommand: Command?
  var eventSource: CGEventSource?

  init(_ workspace: WorkspaceProviding, scriptEngine: ScriptEngine, keyboardEngine: KeyboardEngine) {
    let systemCommandEngine = SystemCommandEngine()
    self.engines = .init(
      application: ApplicationEngine(
        scriptEngine: scriptEngine,
        keyboard: keyboardEngine,
        windowListStore: WindowListStore(),
        workspace: workspace
      ),
      keyboard: keyboardEngine,
      open: OpenEngine(scriptEngine, workspace: workspace),
      script: scriptEngine,
      shortcut: ShortcutsEngine(engine: scriptEngine),
      type: TypeEngine(keyboardEngine: keyboardEngine),
      system: systemCommandEngine
    )
    self.workspace = workspace
  }

  func reveal(_ commands: [Command]) {
    for command in commands {
      switch command {
      case .application(let applicationCommand):
        workspace.reveal(applicationCommand.application.path)
      case .open(let openCommand):
        workspace.reveal(openCommand.path)
      case .script(let scriptCommand):
        switch scriptCommand {
        case .appleScript(_, _, _, let source),
            .shell(_, _, _, let source):
          switch source {
          case .path(let path):
            workspace.reveal(path)
          case .inline:
            // TODO: Open editing for this particular script.
            break
          }
        }
      case .shortcut(let shortcut):
        Task(priority: .userInitiated) {
          let source = """
          shortcuts view "\(shortcut.shortcutIdentifier)"
          """
          _ = try await engines.script.run(.shell(id: UUID().uuidString, isEnabled: true,
                                                  name: "Reveal \(shortcut.shortcutIdentifier)",
                                                  source: .inline(source)))
        }
      case .builtIn(_):
        break
      case .keyboard(_):
        break
      case .type(_):
        break
      case .systemCommand(_):
        break
      }
    }
  }

  func serialRun(_ commands: [Command]) {
    runningTask?.cancel()
    runningTask = Task.detached(priority: .userInitiated) { [weak self] in
      guard let self else { return }
      do {
        for command in commands {
          let id = UUID().uuidString
          FileLogger.log("🏁 Running serial:\(id) \(command.fileLoggerValue)")
          try Task.checkCancellation()
          do {
            try await self.run(command)
          } catch {
            FileLogger.log("⛔️ Failed serial:\(id) \(command.fileLoggerValue)")
          }
          try await Task.sleep(for: .milliseconds(50))
          FileLogger.log("✅ Done serial:\(id) \(command.fileLoggerValue)")
        }
      }
    }
  }

  func concurrentRun(_ commands: [Command]) {
    runningTask?.cancel()
    runningTask = Task.detached(priority: .userInitiated) { [weak self] in
      guard let self else { return }
      for command in commands {
        let id = UUID().uuidString
        FileLogger.log("🏁 Running concurrent:\(id) \(command.fileLoggerValue)")
        do {
          try Task.checkCancellation()
          try await self.run(command)
          FileLogger.log("✅ Running concurrent:\(id) \(command.fileLoggerValue)")
        } catch {
          FileLogger.log("⛔️ Failed concurrent:\(id) \(command.fileLoggerValue)")
        }
      }
    }
  }

  private func run(_ command: Command) async throws {
    if command.notification {
      await MainActor.run {
        lastExecutedCommand = command
      }
    }

    do {
      switch command {
      case .application(let applicationCommand):
        try await engines.application.run(applicationCommand)
      case .builtIn(let builtInCommand):
        switch builtInCommand.kind {
        case .quickRun:
          break
        case .recordSequence:
          break
        case .repeatLastKeystroke:
          break
        }
      case .keyboard(let keyboardCommand):
        try engines.keyboard.run(keyboardCommand,
                                 type: .keyDown,
                                 originalEvent: nil,
                                 with: eventSource)
        try engines.keyboard.run(keyboardCommand,
                                 type: .keyUp,
                                 originalEvent: nil,
                                 with: eventSource)
        try await Task.sleep(for: .milliseconds(1))
      case .open(let openCommand):
        try await engines.open.run(openCommand)
      case .script(let scriptCommand):
        _ = try await self.engines.script.run(scriptCommand)
      case .shortcut(let shortcutCommand):
        try await engines.shortcut.run(shortcutCommand)
      case .type(let typeCommand):
        try await engines.type.run(typeCommand)
      case .systemCommand(let systemCommand):
        try await engines.system.run(systemCommand)
      }
    } catch {
      FileLogger.log("⛔️ Failed to run: \(command.fileLoggerValue)")
      throw error
    }
  }
}
