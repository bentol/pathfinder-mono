class Source < ApplicationRecord
  # Setup transient attributes for your model (attr_accessor)
  # e.g.
  # attr_accessor :temp
  enum source_types: {
    lxc_image: 'image',
    lxc_migration: 'migration',
    lxc_copy: 'copy',
  }

  enum modes: {
    local: 'local',
    pull: 'pull',
  }

  # Setup validations for your model
  # e.g.
  # validates_presence_of :name
  # validates_uniqueness_of :name, case_sensitive: false
  validates :source_type,
    presence: true,
    inclusion: { in: source_types.values }
  validates :mode,
    inclusion: { in: modes.values, allow_nil: true }

  # Setup relations to other models
  # e.g.
  # has_one :user
  # has_many :users
  # has_and_belongs_to_many :users
  # has_many :employees, through: :users
  belongs_to :remote, required: false

  #
  # Setup scopes
  #

  #
  # Setup for additional gem-related configuration
  #

  #
  # Setup callbacks & state machines
  #
  before_create :set_default_values

  #
  # Setup additional methods
  #
  private
    def set_default_values
      self.mode ||= Source.modes[:local]
    end
end
