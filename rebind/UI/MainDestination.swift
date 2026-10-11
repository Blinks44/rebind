/// Navigation available in the current main-window implementation.
nonisolated enum MainDestination: Hashable {
    case input(DeviceScope)
    case settings(SettingsSection)
}
