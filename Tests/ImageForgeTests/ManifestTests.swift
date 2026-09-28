import Foundation
import Testing
@testable import ImageForge

@Test func decodesManifest() throws {
    let json = #"{"schemaVersion":1,"project":"Test","outputDirectory":"~/Pictures/Test","jobs":[{"id":"one","filename":"one.png","prompt":"hello","provider":"apple","status":"pending"}]}"#
    let manifest = try JSONDecoder().decode(BatchManifest.self, from: Data(json.utf8))
    #expect(manifest.project == "Test")
    #expect(manifest.jobs.count == 1)
    #expect(manifest.jobs[0].provider == .apple)
}
