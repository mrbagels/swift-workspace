import Foundation

/// Search and ranking helpers for workspace command surfaces.
public enum WorkspaceCommandSearch {
  public static func filteredCommands<RouteID: Hashable & Sendable>(
    _ commands: [WorkspaceCommand<RouteID>],
    query: String,
    recentCommandIDs: [WorkspaceCommandIdentifier<RouteID>] = []
  ) -> [WorkspaceCommand<RouteID>] {
    let enabledCommands = commands.filter { !$0.isHidden && $0.isEnabled }
    let recentRanks = recentRanks(for: recentCommandIDs)
    let normalizedQuery = normalize(query)

    guard !normalizedQuery.isEmpty
    else {
      return enabledCommands
        .enumerated()
        .sorted { lhs, rhs in
          let lhsRank = recentRanks[lhs.element.id]
          let rhsRank = recentRanks[rhs.element.id]
          switch (lhsRank, rhsRank) {
          case let (lhsRank?, rhsRank?):
            if lhsRank != rhsRank {
              return lhsRank < rhsRank
            }
          case (.some, .none):
            return true
          case (.none, .some):
            return false
          case (.none, .none):
            break
          }
          return lhs.offset < rhs.offset
        }
        .map(\.element)
    }

    let tokens = normalizedQuery.split(separator: " ").map(String.init)

    return enabledCommands
      .enumerated()
      .compactMap { index, command -> (
        score: Int,
        index: Int,
        command: WorkspaceCommand<RouteID>
      )? in
        guard let score = score(command, tokens: tokens, query: normalizedQuery)
        else { return nil }
        let recencyBoost = recentRanks[command.id]
          .map { max(0, 180 - ($0 * 24)) }
          ?? 0
        return (score + recencyBoost, index, command)
      }
      .sorted { lhs, rhs in
        if lhs.score != rhs.score {
          return lhs.score > rhs.score
        }
        return lhs.index < rhs.index
      }
      .map(\.command)
  }

  private static func recentRanks<RouteID: Hashable & Sendable>(
    for commandIDs: [WorkspaceCommandIdentifier<RouteID>]
  ) -> [WorkspaceCommandIdentifier<RouteID>: Int] {
    var ranks: [WorkspaceCommandIdentifier<RouteID>: Int] = [:]
    for commandID in commandIDs {
      if ranks[commandID] == nil {
        ranks[commandID] = ranks.count
      }
    }
    return ranks
  }

  private static func score<RouteID: Hashable & Sendable>(
    _ command: WorkspaceCommand<RouteID>,
    tokens: [String],
    query: String
  ) -> Int? {
    let title = normalize(command.title)
    let subtitle = command.subtitle.map(normalize) ?? ""
    let keywords = command.keywords.map(normalize)
    let shortcut = command.shortcut.map { normalize($0.displayLabel) } ?? ""
    let category = normalize(command.categoryTitle)
    let source = normalize(command.source.displayTitle)
    let haystack = ([title, subtitle, shortcut, category, source] + keywords)
      .joined(separator: " ")

    guard tokens.allSatisfy({ haystack.contains($0) })
    else { return nil }

    var score = 0
    if title == query { score += 1_000 }
    if title.hasPrefix(query) { score += 450 }
    if title.contains(query) { score += 250 }
    if keywords.contains(where: { $0 == query }) { score += 220 }
    if keywords.contains(where: { $0.hasPrefix(query) }) { score += 160 }
    if shortcut.contains(query) { score += 120 }
    if category.contains(query) { score += 60 }
    if subtitle.contains(query) { score += 40 }
    if source.contains(query) { score += 20 }
    return score
  }

  private static func normalize(_ value: String) -> String {
    value
      .folding(options: [.caseInsensitive, .diacriticInsensitive], locale: .current)
      .components(separatedBy: .whitespacesAndNewlines)
      .filter { !$0.isEmpty }
      .joined(separator: " ")
  }
}
