import Foundation

public enum EmojiAssigner {
    public static let choices = [
        "🌐", "🚀", "🧭", "🧪", "🛠️", "✨", "⚡️", "📡",
        "🪄", "🔭", "🧩", "🗺️", "📍", "💻", "🖥️", "🧱",
        "🫧", "🎛️", "📦", "🔌", "🧰", "🪩", "🏗️", "🕹️",
        "🟢", "🔵", "🟣", "🟠", "⭐️", "🔥", "💎", "🍋"
    ]

    public static func emoji(for key: String) -> String {
        let hash = fnv1a64(key)
        return choices[Int(hash % UInt64(choices.count))]
    }

    private static func fnv1a64(_ value: String) -> UInt64 {
        var hash: UInt64 = 0xcbf29ce484222325
        let prime: UInt64 = 0x100000001b3

        for byte in value.utf8 {
            hash ^= UInt64(byte)
            hash = hash &* prime
        }

        return hash
    }
}
