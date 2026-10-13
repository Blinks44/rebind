/// What the main window's detail column shows.
nonisolated enum MainDestination: Hashable {
    case input(DeviceScope)
    case settings(SettingsSection)
}
