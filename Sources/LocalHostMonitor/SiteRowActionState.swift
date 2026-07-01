struct SiteRowActionState: Equatable {
    let isKilling: Bool
    let hasTitleOverride: Bool

    var canOpenWebsite: Bool {
        !isKilling
    }

    var canEditTitle: Bool {
        !isKilling
    }

    var canResetTitle: Bool {
        !isKilling && hasTitleOverride
    }

    var canCopyURL: Bool {
        !isKilling
    }

    var canToggleDefaultViewVisibility: Bool {
        !isKilling
    }

    var canKillProcess: Bool {
        !isKilling
    }

    var showsKillingProgress: Bool {
        isKilling
    }
}
