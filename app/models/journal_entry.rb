class JournalEntry < ApplicationRecord
  include Pageable

  belongs_to :journalable, polymorphic: true

  default_scope { order(created_at: :desc) }
  %w[Article Champion Club Download Event Fee Game Image News Officer Pgn Player Series Tournament Translation User UserInput].each do |klass|
    scope klass.tableize.to_sym, -> { where(journalable_type: klass) }
  end

  ACTIONS = %w[create update destroy]

  validates :action, inclusion: { in: ACTIONS }
  validates :journalable_type, :journalable_id, :by, presence: true
  validates :column, presence: true, if: Proc.new { |e| e.action == "update" }
  validates :ip, presence: true, unless: Proc.new { |e| e.source == "www1" }
  validates :source, inclusion: { in: Global::SOURCES }

  def journalable_type_id
    "#{journalable_type} #{journalable_id}"
  end

  def journalable_path
    journalable_type.constantize.journalable_path % journalable_id
  end

  def journalable_exists?
    journalable_type.constantize.where(id: journalable_id).count == 1
  end

  def self.search(params, path, opts={})
    matches = all
    matches = matches.where(journalable_type: params[:type]) if params[:type].present?
    matches = matches.where(journalable_id: params[:id].to_i) if params[:id].to_i > 0
    matches = matches.where(action: params[:je_action]) if ACTIONS.include?(params[:je_action])
    matches = matches.where("journal_entries.column LIKE ?", "%#{params[:column]}%") if params[:column].present?
    matches = matches.where("journal_entries.from LIKE ?", "%#{params[:from]}%") if params[:from].present?
    matches = matches.where("journal_entries.to LIKE ?", "%#{params[:to]}%") if params[:to].present?
    matches = matches.where("journal_entries.by LIKE ?", "%#{params[:by]}%") if params[:by].present?
    matches = matches.where("journal_entries.ip LIKE ?", "%#{params[:ip]}%") if params[:ip].present?
    paginate(matches, params, path, opts)
  end
end
