# A key that lets a third party use the API (see Api::BaseController).
class ApiKey < ApplicationRecord
  include Pageable # for journal items, not keys
  include Journalable
  journalize %w[active name permissions], "/admin/api_keys/%d"

  # What a key can be allowed to do. Each has a name in the locale file (api_key.permission.*).
  PERMISSIONS = %w[events]

  # The key itself. Only its digest is stored, so this is only set on the object that generated it.
  attr_reader :key

  scope :active, -> { where(active: true) }
  scope :ordered, -> { order(:name) }

  before_validation :normalize_name
  before_validation :generate_key, on: :create

  validates :name, presence: true, length: { maximum: 100 }, uniqueness: true

  # @param key [String, nil] the key a client sent
  # @return [ApiKey, nil] the active key it matches, if any
  def self.authenticate(key)
    return nil if key.blank?
    active.find_by(key_digest: digest(key))
  end

  def self.digest(key)
    Digest::SHA256.hexdigest(key.to_s)
  end

  # Permissions are stored like a user's roles: a space separated string, or nil if there are none.
  # @param value [Array<String>, String, nil]
  def permissions=(value)
    names = value.is_a?(Array) ? value.map(&:to_s) : value.to_s.scan(/\w+/)
    names = PERMISSIONS.select { |p| names.include?(p) }
    super(names.empty? ? nil : names.join(" "))
  end

  # @return [Array<String>]
  def permission_names
    permissions.to_s.split(" ")
  end

  def permits?(permission)
    permission_names.include?(permission.to_s)
  end

  def human_permissions
    permission_names.map { |p| I18n.t("api_key.permission.#{p}") }.join(", ")
  end

  private

  def normalize_name
    self.name = name.to_s.squish.presence
  end

  def generate_key
    @key = SecureRandom.hex(32)
    self.key_digest = self.class.digest(@key)
    self.key_prefix = @key.first(8)
  end
end
