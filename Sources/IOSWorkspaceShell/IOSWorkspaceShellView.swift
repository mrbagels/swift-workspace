#if os(iOS)
  import ComposableArchitecture
  import SwiftUI
  import WorkspaceCore
  import WorkspaceTCA

  /// A first-pass iOS and iPadOS renderer for the platform-neutral workspace engine.
  public struct IOSWorkspaceShellView<RouteID: Hashable & Sendable, Content: View>: View {
    @Bindable public var store: StoreOf<WorkspaceFeature<RouteID>>

    private let content: (WorkspaceRouteDescriptor<RouteID>?) -> Content

    public init(
      store: StoreOf<WorkspaceFeature<RouteID>>,
      @ViewBuilder content: @escaping (WorkspaceRouteDescriptor<RouteID>?) -> Content
    ) {
      self.store = store
      self.content = content
    }

    public var body: some View {
      NavigationSplitView {
        List {
          ForEach(store.visibleSections) { section in
            Section(section.title) {
              ForEach(section.routes) { route in
                Button {
                  store.send(.routeSelected(route.id))
                } label: {
                  HStack {
                    Label(route.title, systemImage: route.systemImage)
                    Spacer()
                    if let badge = route.badge {
                      Text("\(badge)")
                        .font(.caption.monospacedDigit())
                        .foregroundStyle(.secondary)
                    }
                  }
                }
                .disabled(!route.availability.isEnabled)
              }
            }
          }
        }
        .navigationTitle("Workspace")
      } detail: {
        content(store.selectedRoute)
          .frame(maxWidth: .infinity, maxHeight: .infinity)
      }
    }
  }
#else
  public enum IOSWorkspaceShellUnavailable {}
#endif
