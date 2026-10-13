import Foundation

enum BindingEditorValidation {
    /// Uses the persistence contract without saving or changing runtime rules.
    static func error(for binding: Binding, in configuration: Configuration) -> ConfigurationError? {
        var candidate = configuration
        if let index = candidate.bindings.firstIndex(where: { $0.id == binding.id }) {
            candidate.bindings[index] = binding
        } else { candidate.bindings.append(binding) }
        do { try candidate.validate(); return nil }
        catch let error as ConfigurationError { return error }
        catch { return .invalid }
    }
}
