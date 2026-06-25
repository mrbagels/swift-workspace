import Foundation

/// How command reference surfaces group commands.
public enum WorkspaceCommandGrouping: String, CaseIterable, Codable, Equatable, Hashable, Sendable {
  case flat
  case category
  case role
  case source
}

/// Configuration for command reference surfaces such as help, settings, and onboarding.
public struct WorkspaceCommandReferenceConfiguration: Codable, Equatable, Sendable {
  public var grouping: WorkspaceCommandGrouping
  public var includesDisabledCommands: Bool

  public init(
    includesDisabledCommands: Bool = true,
    grouping: WorkspaceCommandGrouping = .category
  ) {
    self.grouping = grouping
    self.includesDisabledCommands = includesDisabledCommands
  }

  public static let `default` = Self()
}

/// A grouped command section derived from a flat command registry.
public struct WorkspaceCommandSection<RouteID: Hashable & Sendable>:
  Equatable,
  Identifiable,
  Sendable
{
  public var commands: [WorkspaceCommand<RouteID>]
  public var id: String
  public var title: String

  public init(
    title: String,
    commands: [WorkspaceCommand<RouteID>]
  ) {
    self.commands = commands
    self.id = title
    self.title = title
  }
}

extension WorkspaceCommandSection: Codable where RouteID: Codable {}

/// Helpers for turning command registries into stable reference sections.
public enum WorkspaceCommandSections {
  public static func make<RouteID: Hashable & Sendable>(
    for commands: [WorkspaceCommand<RouteID>],
    grouping: WorkspaceCommandGrouping = .category,
    includesDisabledCommands: Bool = true
  ) -> [WorkspaceCommandSection<RouteID>] {
    let visibleCommands = commands.filter { command in
      !command.isHidden && (includesDisabledCommands || command.isEnabled)
    }

    switch grouping {
    case .flat:
      guard !visibleCommands.isEmpty
      else { return [] }
      return [
        WorkspaceCommandSection(
          title: "Commands",
          commands: visibleCommands
        ),
      ]

    case .category, .role, .source:
      var sections: [WorkspaceCommandSection<RouteID>] = []
      for command in visibleCommands {
        let title = sectionTitle(for: command, grouping: grouping)
        if let index = sections.firstIndex(where: { $0.title == title }) {
          sections[index].commands.append(command)
        } else {
          sections.append(
            WorkspaceCommandSection(
              title: title,
              commands: [command]
            )
          )
        }
      }
      return sections
    }
  }

  public static func sectionTitle<RouteID: Hashable & Sendable>(
    for command: WorkspaceCommand<RouteID>,
    grouping: WorkspaceCommandGrouping
  ) -> String {
    switch grouping {
    case .flat:
      "Commands"
    case .category:
      command.categoryTitle
    case .role:
      command.role.displayTitle
    case .source:
      command.source.displayTitle
    }
  }
}
