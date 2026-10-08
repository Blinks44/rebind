import Foundation
import IOKit.hid
import Testing
@testable import rebind

struct HIDCapabilitiesTests {
    @Test func absentDescriptionIsUnknownRatherThanZeroButtons() {
        #expect(HIDCapabilities(elementDescriptions: nil).buttonUsages == nil)
        #expect(HIDCapabilities(elementDescriptions: []).buttonUsages == nil)
        let collection: [String: Any] = [kIOHIDElementTypeKey: kIOHIDElementTypeCollection.rawValue,
                                         kIOHIDElementUsagePageKey: kHIDPage_GenericDesktop,
                                         kIOHIDElementUsageKey: kHIDUsage_GD_Mouse]
        #expect(HIDCapabilities(elementDescriptions: [collection]).buttonUsages == nil)
    }

    @Test func nestedCollectionsKeepSparseButtonsAboveFiveWithoutDuplicates() {
        let description: [[String: Any]] = [
            [kIOHIDElementTypeKey: kIOHIDElementTypeCollection.rawValue,
             kIOHIDElementKey: [button(99), button(3), button(65535), button(99)]],
            button(1), button(8)
        ]
        #expect(HIDCapabilities(elementDescriptions: description).buttonUsages == [1, 3, 8, 99, 65535])
    }

    @Test func outputFeatureCollectionsAndNonButtonPagesAreExcluded() {
        var keyboardElement = button(4)
        keyboardElement[kIOHIDElementUsagePageKey] = kHIDPage_KeyboardOrKeypad
        let description = [button(7), keyboardElement,
                           button(10, type: kIOHIDElementTypeOutput.rawValue),
                           button(11, type: kIOHIDElementTypeFeature.rawValue),
                           button(12, type: kIOHIDElementTypeCollection.rawValue)]
        #expect(HIDCapabilities(elementDescriptions: description).buttonUsages == [7])
    }

    @Test func arraySelectorsDoNotPretendToBeIndividualButtons() {
        var array = button(13)
        array[kIOHIDElementIsArrayKey] = true
        #expect(HIDCapabilities(elementDescriptions: [array, button(8)]).buttonUsages == [8])
    }

    @Test func malformedUnknownAndZeroUsagesAreExcludedWithoutTruncation() {
        let invalid: [Any] = [0, -1, 1.5, Double.infinity, Double.nan, Double(UInt32.max) + 1, "12"]
        let elements = invalid.map { value in
            [kIOHIDElementTypeKey: kIOHIDElementTypeInput_Button.rawValue,
             kIOHIDElementUsagePageKey: kHIDPage_Button,
             kIOHIDElementUsageKey: value] as [String: Any]
        }
        #expect(HIDCapabilities(elementDescriptions: elements + [button(42)]).buttonUsages == [42])
        #expect(HIDCapabilities(elementDescriptions: [[kIOHIDElementKey: "invalid"]]).buttonUsages == nil)
    }

    @Test func trackpadRequiresExplicitCollectionMetadata() {
        let collection: [String: Any] = [kIOHIDElementTypeKey: kIOHIDElementTypeCollection.rawValue,
                                         kIOHIDElementUsagePageKey: kHIDPage_Digitizer,
                                         kIOHIDElementUsageKey: kHIDUsage_Dig_TouchPad]
        #expect(HIDCapabilities(elementDescriptions: [collection]).declaresTrackpad)
        #expect(HIDCapabilities(elementDescriptions: [button(5)]).declaresTrackpad == false)
    }

    @Test func deepNestingDoesNotRequireRecursiveCalls() {
        var description = button(128)
        for _ in 0..<256 { description = [kIOHIDElementKey: [description]] }
        #expect(HIDCapabilities(elementDescriptions: [description]).buttonUsages == [128])
    }

    private func button(_ usage: UInt32, type: UInt32 = kIOHIDElementTypeInput_Button.rawValue) -> [String: Any] {
        [kIOHIDElementTypeKey: type, kIOHIDElementUsagePageKey: kHIDPage_Button, kIOHIDElementUsageKey: usage]
    }
}
