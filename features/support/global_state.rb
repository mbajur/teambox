# Reset in-memory Rails configuration state between scenarios.
#
# DatabaseCleaner only cleans the database. Any Ruby-level globals mutated by
# step definitions persist across scenarios in the same process unless
# explicitly reset here.
#
# Add one Before block per setting that any step definition can change.

Before do
  # community_mode.feature (and related steps) sets this to true.
  # Without a reset it leaks into every subsequent feature, causing the
  # Organization "Can't have more than one organization" validation to fire
  # whenever a factory implicitly creates a second organization.
  Rails.configuration.teambox.community = false
end
