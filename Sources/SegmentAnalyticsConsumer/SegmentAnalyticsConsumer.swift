/*
MIT License

Copyright (c) 2025 Tech Artists Agency

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
*/


import Segment
import TAAnalytics
    
/// Sends messages to Segment about analytics events & user properties.
public class SegmentAnalyticsConsumer: AnalyticsConsumer, AnalyticsConsumerWithWriteOnlyUserID {

    private let enabledInstallTypes: [TAAnalyticsConfig.InstallType]
    private let sdkKey: String
    private let isRedacted: Bool

    // MARK: AnalyticsConsumer

    /// - Parameters:
    ///   - isRedacted: If parameter & user property values should be redacted.
    ///   - enabledInstallTypes: Install types for which the consumer is enabled.
    init(
        enabledInstallTypes: [TAAnalyticsConfig.InstallType] = TAAnalyticsConfig.InstallType.allCases,
        sdkKey: String,
        isRedacted: Bool = true
    ) {
        self.enabledInstallTypes = enabledInstallTypes
        self.sdkKey = sdkKey
        self.isRedacted = isRedacted
    }

    public func startFor(
        installType: TAAnalyticsConfig.InstallType,
        userDefaults: UserDefaults,
        TAAnalytics: TAAnalytics
    ) async throws {
        if !self.enabledInstallTypes.contains(installType) {
            throw InstallTypeError.invalidInstallType
        }

        Analytics.setup(with: AnalyticsConfiguration(writeKey: sdkKey))
    }

    public func track(trimmedEvent: EventAnalyticsModelTrimmed, params: [String: any AnalyticsBaseParameterValue]?) {
        let event = trimmedEvent.rawValue

        let debugString = OSLogAnalyticsConsumer().debugStringForLog(eventRawValue: event, params: params, privacyRedacted: isRedacted)
        Analytics.shared().track(event, properties: ["debug": debugString])
    }

    public func set(trimmedUserProperty: UserPropertyAnalyticsModelTrimmed, to value: String?) {
        let userPropertyKey = trimmedUserProperty.rawValue

        let debugString = OSLogAnalyticsConsumer().debugStringForSet(userPropertyRawValue: userPropertyKey, to: value, privacyRedacted: isRedacted)
        Analytics.shared().track("set_user_property", properties: ["debug": debugString])
        if let value = value {
            Analytics.shared().identify(nil, traits: [userPropertyKey: value])
        }
    }

    public func trim(event: EventAnalyticsModel) -> EventAnalyticsModelTrimmed {
        return EventAnalyticsModelTrimmed(event.rawValue.ta_trim(toLength: 40, debugType: "event"))
    }

    public func trim(userProperty: UserPropertyAnalyticsModel) -> UserPropertyAnalyticsModelTrimmed {
        return UserPropertyAnalyticsModelTrimmed(userProperty.rawValue.ta_trim(toLength: 24, debugType: "user property"))
    }

    public var wrappedValue: Analytics.Type {
        Analytics.self
    }

    // MARK: AnalyticsConsumerWithWriteOnlyUserID

    public func set(userID: String?) {
        if let userID = userID {
            Analytics.shared().identify(userID)
        }
    }
}
