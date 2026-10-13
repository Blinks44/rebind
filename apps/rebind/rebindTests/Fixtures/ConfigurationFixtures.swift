enum ConfigurationFixtures {
    // The version-1 persisted representation, independent of the current encoder.
    static let version1 = """
    {
      "schemaVersion": 1,
      "isEnabled": true,
      "bindings": [
        {
          "id": "00000000-0000-0000-0000-000000000001",
          "scope": "allKeyboards",
          "trigger": { "key": { "_0": 0 } },
          "modifiers": 6,
          "action": { "shortcut": { "_0": { "keyCode": 13, "modifiers": 1 } } },
          "isEnabled": true
        },
        {
          "id": "00000000-0000-0000-0000-000000000002",
          "scope": "allMice",
          "trigger": { "mouseButton": { "_0": 3 } },
          "modifiers": 2,
          "action": { "shortcut": { "_0": { "keyCode": 17, "modifiers": 9 } } },
          "isEnabled": false
        }
      ]
    }
    """
}
