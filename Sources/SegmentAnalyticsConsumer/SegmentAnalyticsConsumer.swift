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

// The Swift Programming Language
// https://docs.swift.org/swift-book

import Segment
import TAAnalytics
    
/// Sends messages to Segment about analytics events & user properties.
public class SegmentAnalyticsConsumer: AnalyticsConsumer, AnalyticsConsumerWithWriteOnlyUserID {

    public typealias T = SegmentAnalyticsConsumer

    private let enabledInstallTypes: [TAAnalyticsConfig.InstallType]
    private let writeKey: String

    // MARK: AnalyticsConsumer

    /// - Parameters:
    ///   - isRedacted: If parameter & user property values should be redacted.
    ///   - enabledInstallTypes: Install types for which the consumer is enabled.
    init(
        enabledInstallTypes: [TAAnalyticsConfig.InstallType],
        writeKey: String
    ) {
        self.enabledInstallTypes = enabledInstallTypes
        self.writeKey = writeKey
    }

    public func startFor(
        installType: TAAnalyticsConfig.InstallType,
        userDefaults: UserDefaults,
        TAAnalytics: TAAnalytics
    ) async throws {
        if !self.enabledInstallTypes.contains(installType) {
            throw InstallTypeError.invalidInstallType
        }

        Analytics.setup(with: AnalyticsConfiguration(writeKey: writeKey))
    }

    public func track(trimmedEvent: TrimmedEvent, params: [String: AnalyticsBaseParameterValue]?) {
        let event = trimmedEvent.event
        
        var properties = [String: Any]()
        if let params = params {
            for (key, value) in params {
                properties[key] = value
            }
        }
        
        Analytics.shared().track(event.rawValue, properties: properties)
    }

    public func set(trimmedUserProperty: TrimmedUserProperty, to: String?) {
        let userPropertyKey = trimmedUserProperty.userProperty.rawValue

        if let value = to {
            // Setting user traits in Segment
            Analytics.shared().identify(nil, traits: [userPropertyKey: value])
        }
    }

    public func trim(event: AnalyticsEvent) -> TrimmedEvent {
        // Segment doesn't have strict limits, but you can enforce your own limits for consistency
        let trimmedEventName = event.rawValue.ob_trim(type: "event", toLength: 40)
        return TrimmedEvent(trimmedEventName)
    }

    public func trim(userProperty: AnalyticsUserProperty) -> TrimmedUserProperty {
        // Segment doesn't have strict limits on user property keys, but you might want to enforce one.
        let trimmedUserPropertyKey = userProperty.rawValue.ob_trim(type: "user property", toLength: 40)
        return TrimmedUserProperty(trimmedUserPropertyKey)
    }

    public var wrappedValue: Self {
        return self
    }

    // MARK: AnalyticsConsumerWithWriteOnlyUserID

    public func set(userID: String?) {
        if let userID = userID {
            // Set user ID in Segment
            Analytics.shared().identify(userID)
        }
    }
}
