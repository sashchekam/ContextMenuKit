@testable import ContextMenuKit
import Testing
import UIKit

@Suite("ContextMenuImage")
struct ContextMenuImageTests {
    @Test("Every system image is an existing SF Symbol", arguments: ContextMenuSystemImage.allCases)
    func systemImage(_ systemImage: ContextMenuSystemImage) {
        #expect(ContextMenuImage.system(systemImage).image != nil)
    }

    @Test("A custom image is used as is")
    func customImage() {
        let image = UIImage()

        #expect(ContextMenuImage.custom(image).image === image)
    }
}
