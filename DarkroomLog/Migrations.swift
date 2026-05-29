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

/// One-time migration: any FilmRoll with loadedAt == nil was created before v1.8
/// (or restored from a pre-v1.8 backup) and should default to Done.
///
/// Gated behind a UserDefaults flag so it runs exactly once. Running it on every
/// launch would corrupt rolls created later with a non-`.loaded` status (their
/// loadedAt is intentionally nil) by force-resetting them to Done.
func migrateLegacyRollsToDone(context: ModelContext) {
    let migratedKey = "didMigrateRollStatusV18"
    guard !UserDefaults.standard.bool(forKey: migratedKey) else { return }

    let descriptor = FetchDescriptor<FilmRoll>()
    guard let rolls = try? context.fetch(descriptor) else { return }
    var changed = false
    for roll in rolls where roll.loadedAt == nil {
        roll.statusRaw = FilmRollStatus.done.rawValue
        roll.doneAt = roll.date
        changed = true
    }
    if changed { try? context.save() }
    UserDefaults.standard.set(true, forKey: migratedKey)
}
