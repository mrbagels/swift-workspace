#if os(macOS)
  import SwiftUI
  import WorkspaceCore

  extension View {
    @ViewBuilder
    func macWorkspaceKeyboardShortcut(_ shortcut: WorkspaceKeyboardShortcut?) -> some View {
      if let shortcut, let keyEquivalent = shortcut.keyEquivalent {
        keyboardShortcut(keyEquivalent, modifiers: shortcut.modifiers.eventModifiers)
      } else {
        self
      }
    }
  }

  extension WorkspaceKeyboardShortcut {
    var keyEquivalent: KeyEquivalent? {
      guard key.count == 1, let character = key.first
      else { return nil }
      return KeyEquivalent(character)
    }
  }

  extension WorkspaceKeyboardModifiers {
    var eventModifiers: EventModifiers {
      var modifiers: EventModifiers = []
      if contains(.command) { modifiers.insert(.command) }
      if contains(.control) { modifiers.insert(.control) }
      if contains(.option) { modifiers.insert(.option) }
      if contains(.shift) { modifiers.insert(.shift) }
      return modifiers
    }
  }
#endif
