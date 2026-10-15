# HIDPP

HIDPP contains the platform-independent Logitech HID++ protocol support used by LinearMouse. It provides report transport, receiver-slot routing, feature discovery, Adjustable DPI, and Hi-Res Wheel commands.

Platform-specific device wrappers conform to `HIDPPDeviceIO`; the module does not depend on LinearMouse or PointerKit.

## Vendored copy in Rebind

Copied on 2026-10-15 from [linearmouse/linearmouse](https://github.com/linearmouse/linearmouse) `Modules/HIDPP` at commit `843d9a070cc64d56b07fc7f16d03b0f34ff33412` under its MIT license (`LICENSE`). Rebind changes:

- `HIDPPFeatureID` gains `smartShift` (0x2110) and `smartShiftEnhanced` (0x2111).
- `HIDPPTransport` treats a HID++ 1.0 error reply (sub-ID 0x8F) as a failure, so a request to an empty receiver slot ends at once instead of timing out.
- New `Features/SmartShift.swift`, `Features/DeviceName.swift`, `Features/Battery.swift` (0x1000/0x1004), `Features/ReprogControls.swift` (0x1B04 diversion and its notifications) and `Features/OnboardProfiles.swift` (0x8100 host mode), with tests.
