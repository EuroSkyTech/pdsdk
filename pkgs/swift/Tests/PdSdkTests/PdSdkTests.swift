import XCTest
@testable import PdSdk

final class PdSdkTests: XCTestCase {
    func testVersion() {
        let version = PdSdk.version()
        
        XCTAssertFalse(version.isEmpty, "Version string should not be empty")

        let versionPattern = #"^\d+\.\d+\.\d+$"#
        let versionRegex = try! NSRegularExpression(pattern: versionPattern)
        let range = NSRange(location: 0, length: version.utf16.count)
        XCTAssertNotNil(versionRegex.firstMatch(in: version, range: range), 
                       "Version should follow semantic versioning format (e.g. '1.2.3')")
    }
} 