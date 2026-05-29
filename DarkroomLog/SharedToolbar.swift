import SwiftUI

extension View {
    /// Shared overflow menu (Equipment / Settings / About) used by every tab root.
    /// Keeping it in one place guarantees the three tabs stay visually identical.
    func darkroomOverflowMenu() -> some View {
        toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Menu {
                    NavigationLink(destination: EquipmentLibraryView()) {
                        Label("Equipment", systemImage: "tray.full")
                    }
                    NavigationLink(destination: SettingsView()) {
                        Label("Settings", systemImage: "gearshape")
                    }
                    NavigationLink(destination: AboutView()) {
                        Label("About", systemImage: "info.circle")
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                }
            }
        }
    }
}
