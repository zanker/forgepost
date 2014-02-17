class Ability
  include MongoMapper::EmbeddedDocument
  plugin MongoMapper::SkipIdField

  ACTIVATED, CONTINUOUS, TRIGGERED = 0, 1, 2

  key :type, Integer

  key :source, String

  key :triggers, String

  key :desc, String

  key :target, String
  key :num_targets, String

  key :prompt, String

  key :condition, String
  key :cond_target, String

  key :effect, String

  key :effect_values, Array

  key :beneficial, Boolean

  key :tests, Array
  key :cond_tests, Array

  embedded_in :card
end