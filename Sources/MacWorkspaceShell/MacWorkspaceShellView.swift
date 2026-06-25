#if os(macOS)
  import ComposableArchitecture
  import SwiftUI
  import WorkspaceCore
  import WorkspaceTCA

  /// A first-pass macOS renderer for the platform-neutral workspace engine.
  public struct MacWorkspaceShellView<
    RouteID: Hashable & Sendable,
    Content: View,
    SidebarFooter: View
  >: View {
    @Bindable public var store: StoreOf<WorkspaceFeature<RouteID>>

    private let content: (WorkspaceRouteDescriptor<RouteID>?) -> Content
    private let sidebarFooter: () -> SidebarFooter

    public init(
      store: StoreOf<WorkspaceFeature<RouteID>>,
      @ViewBuilder sidebarFooter: @escaping () -> SidebarFooter,
      @ViewBuilder content: @escaping (WorkspaceRouteDescriptor<RouteID>?) -> Content
    ) {
      self.store = store
      self.sidebarFooter = sidebarFooter
      self.content = content
    }

    public var body: some View {
      NavigationSplitView {
        sidebar
          .navigationSplitViewColumnWidth(min: 220, ideal: 260, max: 360)
      } detail: {
        content(store.selectedRoute)
          .frame(maxWidth: .infinity, maxHeight: .infinity)
      }
    }

    private var sidebar: some View {
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
              .buttonStyle(.plain)
              .disabled(!route.availability.isEnabled)
              .contextMenu {
                if route.scenePresentation.opensInSeparateScene {
                  Button("Open in New Window") {
                    store.send(.sceneRequested(route.id))
                  }
                }
              }
            }
          }
        }

        sidebarFooter()
      }
      .listStyle(.sidebar)
    }
  }

  public extension MacWorkspaceShellView where SidebarFooter == EmptyView {
    init(
      store: StoreOf<WorkspaceFeature<RouteID>>,
      @ViewBuilder content: @escaping (WorkspaceRouteDescriptor<RouteID>?) -> Content
    ) {
      self.init(
        store: store,
        sidebarFooter: { EmptyView() },
        content: content
      )
    }
  }
#else
  public enum MacWorkspaceShellUnavailable {}
#endif
