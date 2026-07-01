import Foundation

public struct SitePresentation: Identifiable, Equatable, Sendable {
    public let site: LocalhostSite
    public let title: String
    public let emoji: String?
    public let urlText: String
    public let statusText: String
    public let processName: String?
    public let pidText: String?
    public let isHidden: Bool
    public let isVisibleInDefaultView: Bool
    public let menuTitle: String

    public var id: LocalhostSite.ID {
        site.id
    }

    public init(site: LocalhostSite, override: SiteOverride? = nil) {
        self.site = site

        let title = Self.resolvedTitle(for: site, override: override)
        let emoji = Self.resolvedEmoji(for: site, override: override)
        let isHidden = override?.isHidden ?? false
        let statusSuffix = site.isOK ? "" : " HTTP \(site.httpStatusCode)"

        self.title = title
        self.emoji = emoji
        self.urlText = site.displayURLString
        self.statusText = "HTTP \(site.httpStatusCode)"
        self.processName = site.processName?.trimmedForPresentation.nilIfEmpty
        self.pidText = site.pid.map { "PID \($0)" }
        self.isHidden = isHidden
        self.isVisibleInDefaultView = site.isOK && !isHidden

        if let emoji, !emoji.isEmpty {
            self.menuTitle = "\(emoji) \(title) :\(site.port)\(statusSuffix)"
        } else {
            self.menuTitle = "\(title) :\(site.port)\(statusSuffix)"
        }
    }

    public static func presentations(
        for sites: [LocalhostSite],
        overrides: [String: SiteOverride]
    ) -> [SitePresentation] {
        sites.map { site in
            SitePresentation(site: site, override: overrides[site.preferenceKey])
        }
    }

    public static func titleOverrideValue(for site: LocalhostSite, rawTitle: String) -> String? {
        let trimmedTitle = rawTitle.trimmedForPresentation
        let inferredTitle = site.inferredTitle?.trimmedForPresentation ?? ""

        if trimmedTitle.isEmpty
            || trimmedTitle == inferredTitle
            || trimmedTitle == site.fallbackTitle {
            return nil
        }

        return trimmedTitle
    }

    public static func emojiPreference(for rawValue: String) -> EmojiPreference {
        let trimmedValue = rawValue.trimmedForPresentation

        guard let emoji = trimmedValue.last else {
            return .cleared
        }

        return .custom(String(emoji))
    }

    private static func resolvedTitle(for site: LocalhostSite, override: SiteOverride?) -> String {
        if let override = override?.title?.trimmedForPresentation,
           !override.isEmpty {
            return override
        }

        if let inferredTitle = site.inferredTitle?.trimmedForPresentation,
           !inferredTitle.isEmpty {
            return inferredTitle
        }

        return site.fallbackTitle
    }

    private static func resolvedEmoji(for site: LocalhostSite, override: SiteOverride?) -> String? {
        switch override?.emoji ?? .automatic {
        case .automatic:
            return EmojiAssigner.emoji(for: site.preferenceKey)
        case .cleared:
            return nil
        case .custom(let value):
            let trimmedValue = value.trimmedForPresentation
            return trimmedValue.first.map { String($0) }
        }
    }
}

public struct DefaultViewFilter: Equatable, Sendable {
    public var includesHiddenSites: Bool
    public var includesNonOKSites: Bool

    public init(
        includesHiddenSites: Bool = false,
        includesNonOKSites: Bool = false
    ) {
        self.includesHiddenSites = includesHiddenSites
        self.includesNonOKSites = includesNonOKSites
    }

    public func includes(_ presentation: SitePresentation) -> Bool {
        let passesHiddenFilter = includesHiddenSites || !presentation.isHidden
        let passesStatusFilter = includesNonOKSites || presentation.site.isOK

        return passesHiddenFilter && passesStatusFilter
    }
}

public struct DefaultViewSummary: Equatable, Sendable {
    public let shownCount: Int
    public let totalCount: Int

    public init(shownCount: Int, totalCount: Int) {
        self.shownCount = shownCount
        self.totalCount = totalCount
    }

    public var countText: String {
        if totalCount == 0 {
            return "0 shown"
        }

        if shownCount == totalCount {
            return "\(totalCount) shown"
        }

        return "\(shownCount) of \(totalCount) shown"
    }
}

public extension SitePresentation {
    static func visiblePresentations(
        for sites: [LocalhostSite],
        overrides: [String: SiteOverride],
        filter: DefaultViewFilter
    ) -> [SitePresentation] {
        presentations(for: sites, overrides: overrides)
            .filter { filter.includes($0) }
    }
}

private extension String {
    var trimmedForPresentation: String {
        trimmingCharacters(in: .whitespacesAndNewlines)
    }

    var nilIfEmpty: String? {
        isEmpty ? nil : self
    }
}
