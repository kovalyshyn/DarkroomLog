// Migration history (for reference only):
// v1.0–1.1: Session, Print, Equipment
// v1.2:     + FilmRoll, Print.filmRoll
// v1.3:     + Print.rating, Print.aperture
// v1.6:     + ChemBatch (Chemistry Tracker tab)
// v1.7:     + FilmDevStep (Film dev timer steps), TimerView progress bar
// v1.8:     + FilmRoll.statusRaw, loadedAt, exposedAt, developingAt, developedAt, doneAt
//           + FilmDevStep.agitationEnabled, agitationInitialSeconds, agitationIntervalSeconds, agitationDurationSeconds
//
// SwiftData handles all lightweight migrations automatically
// (adding tables/columns with defaults) without an explicit plan.

import Foundation
import SwiftData

/// Runs on every launch. Any FilmRoll with loadedAt == nil was created before v1.8
/// (or restored from a pre-v1.8 backup) and should default to Done.
func migrateLegacyRollsToDone(context: ModelContext) {
    let descriptor = FetchDescriptor<FilmRoll>()
    guard let rolls = try? context.fetch(descriptor) else { return }
    var changed = false
    for roll in rolls where roll.loadedAt == nil {
        roll.statusRaw = FilmRollStatus.done.rawValue
        roll.doneAt = roll.date
        changed = true
    }
    if changed { try? context.save() }
}
