import Foundation

struct ImageJob: Codable, Identifiable, Hashable, Sendable {
    enum Provider: String, Codable, CaseIterable, Sendable {
        case apple
        case local
        case mock
    }

    enum Status: String, Codable, CaseIterable, Sendable {
        case pending
        case ready
        case generating
        case completed
        case failed
        case skipped
    }

    let id: String
    var filename: String
    var prompt: String
    var team: String?
    var assetType: String?
    var variant: String?
    var negativePrompt: String?
    var referenceImage: String?
    var tags: [String]
    var width: Int?
    var height: Int?
    var provider: Provider
    var status: Status
    var errorMessage: String?

    init(
        id: String,
        filename: String,
        prompt: String,
        team: String? = nil,
        assetType: String? = nil,
        variant: String? = nil,
        negativePrompt: String? = nil,
        referenceImage: String? = nil,
        tags: [String] = [],
        width: Int? = nil,
        height: Int? = nil,
        provider: Provider = .apple,
        status: Status = .pending,
        errorMessage: String? = nil
    ) {
        self.id = id
        self.filename = filename
        self.prompt = prompt
        self.team = team
        self.assetType = assetType
        self.variant = variant
        self.negativePrompt = negativePrompt
        self.referenceImage = referenceImage
        self.tags = tags
        self.width = width
        self.height = height
        self.provider = provider
        self.status = status
        self.errorMessage = errorMessage
    }

    var generationPrompt: String {
        let base = prompt.trimmingCharacters(in: .whitespacesAndNewlines)
        guard let negativePrompt,
              !negativePrompt.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            return base
        }
        return "\(base)\n\nAvoid: \(negativePrompt.trimmingCharacters(in: .whitespacesAndNewlines))"
    }

    private enum CodingKeys: String, CodingKey {
        case id
        case filename
        case prompt
        case team
        case assetType
        case variant
        case negativePrompt
        case referenceImage
        case tags
        case width
        case height
        case provider
        case status
        case errorMessage
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        filename = try container.decode(String.self, forKey: .filename)
        prompt = try container.decode(String.self, forKey: .prompt)
        team = try container.decodeIfPresent(String.self, forKey: .team)
        assetType = try container.decodeIfPresent(String.self, forKey: .assetType)
        variant = try container.decodeIfPresent(String.self, forKey: .variant)
        negativePrompt = try container.decodeIfPresent(String.self, forKey: .negativePrompt)
        referenceImage = try container.decodeIfPresent(String.self, forKey: .referenceImage)
        tags = try container.decodeIfPresent([String].self, forKey: .tags) ?? []
        width = try container.decodeIfPresent(Int.self, forKey: .width)
        height = try container.decodeIfPresent(Int.self, forKey: .height)
        provider = try container.decodeIfPresent(Provider.self, forKey: .provider) ?? .apple
        status = try container.decodeIfPresent(Status.self, forKey: .status) ?? .pending
        errorMessage = try container.decodeIfPresent(String.self, forKey: .errorMessage)
    }
}
