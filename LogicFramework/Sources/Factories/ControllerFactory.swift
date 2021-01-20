import Cocoa
import ModelKit

public final class ControllerFactory {
  private let _keycodeMapper = KeyCodeMapper.shared
  private let _groupsController = GroupsController(groups: [])

  public init() {}

  public func permissionsController() -> PermissionsControlling {
    PermissionsController()
  }

  public func hotkeyController() throws -> HotKeyControlling {
    try HotKeyController()
  }

  public func coreController(_ initialState: CoreControllerState,
                             commandController: CommandControlling? = nil,
                             builtInCommandController: BuiltInCommandControlling,
                             groupsController: GroupsControlling? = nil,
                             hotKeyController: HotKeyControlling? = nil,
                             installedApplications: [Application],
                             keyboardCommandController: KeyboardCommandControlling? = nil,
                             keycodeMapper: KeyCodeMapping? = nil,
                             workflowController: WorkflowControlling? = nil,
                             workspace: WorkspaceProviding = NSWorkspace.shared) -> CoreControlling {
    let commandController = commandController ??
      self.commandController(builtInCommandController: builtInCommandController)
    let groupsController = groupsController ?? self._groupsController
    let keycodeMapper = keycodeMapper ?? self._keycodeMapper
    let keyboardCommandController = keyboardCommandController ??
      KeyboardCommandController(keyCodeMapper: _keycodeMapper)
    let workflowController = workflowController ?? WorkflowController()
    let keyboardValidator = KeyboardShortcutValidator(keycodeMapper: keycodeMapper)
    return CoreController(initialState,
                          commandController: commandController,
                          groupsController: groupsController,
                          hotKeyController: hotKeyController,
                          installedApplications: installedApplications,
                          keyboardCommandController: keyboardCommandController,
                          keyboardShortcutValidator: keyboardValidator,
                          keycodeMapper: keycodeMapper,
                          workflowController: workflowController,
                          workspace: workspace)
  }

  public func groupsController(groups: [Group]) -> GroupsControlling {
    _groupsController.groups = groups
    return _groupsController
  }

  public func workflowController() -> WorkflowControlling {
    WorkflowController()
  }

  public func storageController(path: String, fileName: String = "config.json") -> StorageControlling {
    StorageController(path: path, fileName: fileName)
  }

  public func commandController(
    appleScriptCommandController: AppleScriptControlling? = nil,
    applicationCommandController: ApplicationCommandControlling? = nil,
    builtInCommandController: BuiltInCommandControlling? = nil,
    keyboardCommandController: KeyboardCommandControlling? = nil,
    openCommandController: OpenCommandControlling? = nil,
    shellScriptCommandController: ShellScriptControlling? = nil
  ) -> CommandControlling {
    let workspace = NSWorkspace.shared
    let applicationCommandController = applicationCommandController ??
      self.applicationCommandController(
        windowListProvider: WindowListProvider(),
        workspace: workspace)
    let keyboardCommandController = keyboardCommandController ??
      KeyboardCommandController(keyCodeMapper: _keycodeMapper)
    let openCommandController = openCommandController ?? self.openCommandController(workspace: workspace)
    let appleScriptCommandController = appleScriptCommandController ?? AppleScriptController()
    let builtInCommandController = builtInCommandController ?? BuiltInCommandControllerMock()
    let shellScriptCommandController = shellScriptCommandController ?? ShellScriptController()

    return CommandController(appleScriptCommandController: appleScriptCommandController,
                             applicationCommandController: applicationCommandController,
                             builtInCommandController: builtInCommandController,
                             keyboardCommandController: keyboardCommandController,
                             openCommandController: openCommandController,
                             shellScriptCommandController: shellScriptCommandController)
  }

  public func applicationCommandController(windowListProvider: WindowListProviding? = nil,
                                           workspace: WorkspaceProviding = NSWorkspace.shared)
  -> ApplicationCommandControlling {
    ApplicationCommandController(
      windowListProvider: windowListProvider ?? WindowListProvider(),
      workspace: workspace)
  }

  public func openCommandController(workspace: WorkspaceProviding = NSWorkspace.shared) -> OpenCommandControlling {
    OpenCommandController(workspace: workspace)
  }
}
