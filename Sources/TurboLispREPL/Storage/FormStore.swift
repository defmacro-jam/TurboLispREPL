import Foundation

/// Represents the location of a parsed form within a source buffer.
public struct FormRange: Codable, Equatable {
    /// The starting byte offset of the form.
    public var start: Int
    /// The byte offset immediately after the end of the form.
    public var end: Int
    /// Time the range was last refreshed.
    public var updatedAt: Date
}

/// Maintains lightweight metadata about previously scanned forms.
///
/// The store is intentionally simple: it keeps an ordered list of ranges and
/// adjusts their locations after text edits so the editor can avoid rescanning
/// unchanged regions.
public final class FormStore {
    private var forms: [FormRange] = []

    public init() {}

    /// Inserts a new range or replaces any existing range that overlaps it.
    @discardableResult
    public func upsert(start: Int, end: Int, updatedAt: Date = Date()) -> FormRange {
        precondition(start <= end, "start must not exceed end")
        let newForm = FormRange(start: start, end: end, updatedAt: updatedAt)

        // Remove overlapping entries and keep the list sorted by start.
        forms.removeAll { $0.end > start && $0.start < end }
        forms.append(newForm)
        forms.sort { $0.start < $1.start }
        return newForm
    }

    /// Adjusts stored ranges in response to an edit.
    ///
    /// - Parameters:
    ///   - location: Offset at which the edit began.
    ///   - oldLength: Length of text replaced by the edit.
    ///   - newLength: Length of the replacement text.
    ///   - date: Timestamp for modified ranges; defaults to now.
    ///
    /// Ranges that intersect the edited region are discarded. Ranges located
    /// after the edit are shifted by the length difference.
    public func applyEdit(at location: Int,
                          oldLength: Int,
                          newLength: Int,
                          date: Date = Date()) {
        let delta = newLength - oldLength
        let editEnd = location + oldLength

        forms = forms.compactMap { form in
            var f = form
            if f.end <= location {
                // The form lies entirely before the edit.
                return f
            } else if f.start >= editEnd {
                // The form is after the edited region; shift it.
                f.start += delta
                f.end += delta
                f.updatedAt = date
                return f
            } else {
                // The form intersects the edit and must be rescanned.
                return nil
            }
        }
    }

    /// Returns all ranges that intersect the given viewport.
    public func intersecting(start: Int, end: Int) -> [FormRange] {
        return forms.filter { $0.end > start && $0.start < end }
    }
}

