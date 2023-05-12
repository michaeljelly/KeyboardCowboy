import SwiftUI
import UniformTypeIdentifiers

struct WorkflowCommandListView: View {
  static let animation: Animation = .spring(response: 0.3, dampingFraction: 0.65, blendDuration: 0.2)

  @ObserveInjection var inject
  @Environment(\.openWindow) var openWindow
  var namespace: Namespace.ID
  @EnvironmentObject var applicationStore: ApplicationStore
  @ObservedObject private var detailPublisher: DetailPublisher
  @ObservedObject private var selectionManager: SelectionManager<DetailViewModel.CommandViewModel>
  @State private var selections = Set<String>()
  @State private var dropOverlayIsVisible: Bool = false
  @State private var dropUrls = Set<URL>()
  private var focusPublisher = FocusPublisher<DetailViewModel.CommandViewModel>()
  private let scrollViewProxy: ScrollViewProxy?
  private let onAction: (SingleDetailView.Action) -> Void
  private let focus: FocusState<AppFocus?>.Binding

  init(_ focus: FocusState<AppFocus?>.Binding,
       namespace: Namespace.ID,
       publisher: DetailPublisher,
       selectionManager: SelectionManager<DetailViewModel.CommandViewModel>,
       scrollViewProxy: ScrollViewProxy? = nil,
       onAction: @escaping (SingleDetailView.Action) -> Void) {
    self.focus = focus
    self.namespace = namespace
    _detailPublisher = .init(initialValue: publisher)
    self.selectionManager = selectionManager
    self.scrollViewProxy = scrollViewProxy
    self.onAction = onAction
  }

  @ViewBuilder
  var body: some View {
    Group {
      if detailPublisher.data.commands.isEmpty {
        WorkflowCommandEmptyListView(namespace: namespace,
                                     detailPublisher: detailPublisher, onAction: onAction)
          .matchedGeometryEffect(id: "command-list", in: namespace)
      } else {
        LazyVStack(spacing: 0) {
          ForEach($detailPublisher.data.commands, id: \.self) { element in
            let command = element
            CommandView(command, workflowId: detailPublisher.data.id) { action in
              onAction(.commandView(workflowId: detailPublisher.data.id, action: action))
            }
            .contextMenu(menuItems: { contextMenu(command) })
            .onTapGesture {
              selectionManager.handleOnTap(detailPublisher.data.commands, element: element.wrappedValue)
              focusPublisher.publish(element.id)
            }
            .background(
              FocusView(focusPublisher, element: element,
                        selectionManager: selectionManager, cornerRadius: 8,
                        style: .focusRing)
            )
            .draggable(element.wrappedValue.draggablePayload(prefix: "WC:", selections: selectionManager.selections))
            .dropDestination(for: DropItem.self) { items, location in
              var urls = [URL]()
              for item in items {
                switch item {
                case .text(let item):
                  if let url = URL(string: item) {
                    urls.append(url)
                    continue
                  }
                  guard let (from, destination) = detailPublisher.data.commands.moveOffsets(for: element.wrappedValue,
                                                                                            with: item.draggablePayload(prefix: "WC:")) else {
                    return false
                  }
                  withAnimation(Self.animation) {
                    detailPublisher.data.commands.move(fromOffsets: IndexSet(from), toOffset: destination)
                  }
                  onAction(.moveCommand(workflowId: element.id, indexSet: from, toOffset: destination))
                  return true
                case .url(let url):
                  urls.append(url)
                case .none:
                  return false
                }
              }

              if !urls.isEmpty {
                onAction(.dropUrls(workflowId: detailPublisher.data.id, urls: urls))
                return true
              }
              return false
            }
          }
          .padding(.vertical, 5)
          .onCommand(#selector(NSResponder.insertBacktab(_:)), perform: {
            switch detailPublisher.data.trigger {
            case .applications:
              focus.wrappedValue = .detail(.applicationTriggers)
            case .keyboardShortcuts:
              focus.wrappedValue = .detail(.keyboardShortcuts)
            case .none:
              focus.wrappedValue = .detail(.name)
            }
          })
          .onCommand(#selector(NSResponder.insertTab(_:)), perform: {
            focus.wrappedValue = .groups
          })
          .onCommand(#selector(NSResponder.selectAll(_:)), perform: {
            selectionManager.selections = Set(detailPublisher.data.commands.map(\.id))
          })
          .onMoveCommand(perform: { direction in
            if let elementID = selectionManager.handle(direction, detailPublisher.data.commands,
                                                       proxy: scrollViewProxy) {
              focusPublisher.publish(elementID)
            }
          })
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
        .focused(focus, equals: .detail(.commands))
        .matchedGeometryEffect(id: "command-list", in: namespace)
      }
    }
    .overlay {
      LinearGradient(stops: [
        .init(color: Color(.systemGreen).opacity(0.75), location: 0.0),
        .init(color: Color(.systemGreen).opacity(0.25), location: 1.0),
      ], startPoint: .bottomTrailing, endPoint: .topLeading)
      .mask(
        RoundedRectangle(cornerRadius: 4)
          .stroke(style: StrokeStyle(lineWidth: 2, dash: [8]))
          .foregroundColor(Color(.systemGreen))
          .padding(8)
      )
      .shadow(color: .black, radius: 1)
      .opacity(dropOverlayIsVisible ? 1 : 0)

      Color(.systemGreen).opacity(0.1)
        .cornerRadius(4)
        .padding(8)
        .opacity(dropOverlayIsVisible ? 1 : 0)
        .animation(.linear, value: dropOverlayIsVisible)
    }
    .animation(Self.animation, value: detailPublisher.data.commands.isEmpty)
    .debugEdit()
  }

  @ViewBuilder
  private func contextMenu(_ command: Binding<DetailViewModel.CommandViewModel>) -> some View {
    Button("Run", action: {})
    Divider()
    Button("Remove", action: {
      if !selections.isEmpty {
        var indexSet = IndexSet()
        selections.forEach { id in
          if let index = detailPublisher.data.commands.firstIndex(where: { $0.id == id }) {
            indexSet.insert(index)
          }
        }
        onAction(.removeCommands(workflowId: detailPublisher.data.id, commandIds: selections))
      } else {
        onAction(.commandView(workflowId: detailPublisher.data.id, action: .remove(workflowId: detailPublisher.data.id, commandId: command.id)))
      }
    })
  }
}

struct WorkflowCommandListView_Previews: PreviewProvider {
  @Namespace static var namespace
  @FocusState static var focus: AppFocus?
  static var previews: some View {
    WorkflowCommandListView($focus,
                            namespace: namespace,
                            publisher: DetailPublisher(DesignTime.detail),
                            selectionManager: .init()) { _ in }
      .frame(height: 900)
  }
}
