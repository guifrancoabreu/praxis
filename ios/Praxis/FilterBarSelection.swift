/// Keeps a filter bar's selection and its horizontal scroll position in sync.
///
/// A tap on a chip the user can already see must not move the bar; a
/// selection made from elsewhere on the screen must bring its chip into view
/// without resetting the bar to its leading edge.
public struct FilterBarSelection<Item: Hashable> {
    public private(set) var selected: Item
    private var pendingReveal: Item?

    public init(_ selected: Item) {
        self.selected = selected
    }

    /// Selects a chip that the user tapped in the bar. The bar keeps its offset.
    public mutating func selectFromBar(_ item: Item) {
        selected = item
        pendingReveal = nil
    }

    /// Selects a filter from outside the bar, asking the bar to reveal its chip.
    public mutating func selectProgrammatically(_ item: Item) {
        selected = item
        pendingReveal = item
    }

    /// Returns `true` once for a pending programmatic selection of `item`.
    public mutating func consumeRevealRequest(for item: Item) -> Bool {
        guard pendingReveal == item else { return false }
        pendingReveal = nil
        return true
    }
}
