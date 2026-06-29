import Foundation

public enum EmojiPreference: Codable, Equatable, Sendable {
    case automatic
    case cleared
    case custom(String)

    private enum CodingKeys: String, CodingKey {
        case type
        case value
    }

    private enum Kind: String, Codable {
        case automatic
        case cleared
        case custom
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let kind = try container.decode(Kind.self, forKey: .type)

        switch kind {
        case .automatic:
            self = .automatic
        case .cleared:
            self = .cleared
        case .custom:
            self = .custom(try container.decode(String.self, forKey: .value))
        }
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)

        switch self {
        case .automatic:
            try container.encode(Kind.automatic, forKey: .type)
        case .cleared:
            try container.encode(Kind.cleared, forKey: .type)
        case .custom(let value):
            try container.encode(Kind.custom, forKey: .type)
            try container.encode(value, forKey: .value)
        }
    }
}

public struct SiteOverride: Codable, Equatable, Sendable {
    public var title: String?
    public var emoji: EmojiPreference
    public var isHidden: Bool

    private enum CodingKeys: String, CodingKey {
        case title
        case emoji
        case isHidden
    }

    public init(
        title: String? = nil,
        emoji: EmojiPreference = .automatic,
        isHidden: Bool = false
    ) {
        self.title = title
        self.emoji = emoji
        self.isHidden = isHidden
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        title = try container.decodeIfPresent(String.self, forKey: .title)
        emoji = try container.decodeIfPresent(EmojiPreference.self, forKey: .emoji) ?? .automatic
        isHidden = try container.decodeIfPresent(Bool.self, forKey: .isHidden) ?? false
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encodeIfPresent(title, forKey: .title)
        try container.encode(emoji, forKey: .emoji)
        try container.encode(isHidden, forKey: .isHidden)
    }

    public var isEmpty: Bool {
        let hasTitle = title?.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty == false
        return !hasTitle && emoji == .automatic && !isHidden
    }
}
