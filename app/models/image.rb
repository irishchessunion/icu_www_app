require "cgi"

class Image < ApplicationRecord
  include Journalable
  include Pageable

  journalize %w[data_file_name data_content_type data_file_size caption credit year], "/images/%d"

  serialize :dimensions, coder: YAML, type: Hash

  TYPES = "jpe?g|gif|png"
  MAX_PIXELS = 10000
  MIN_PIXELS = 30
  THUMB_SIZE = 100
  # Smallest first, so #style_for can pick the smallest that's big enough. ">" only ever shrinks.
  STYLES = {
    thumbnail: "#{THUMB_SIZE}x#{THUMB_SIZE}>",
    small:     "300x300>",
    medium:    "600x600>",
    large:     "1200x1200>",
  }

  has_attached_file :data, styles: STYLES, keep_old_files: true

  belongs_to :user
  has_many :news, dependent: :nullify

  before_validation :normalize_attributes, :check_dimensions

  validates_attachment :data, content_type: { content_type: /\Aimage\/(#{TYPES})\z/, file_name: /\.(#{TYPES})\z/i }
  validates :data, presence: true
  validates :caption, presence: true
  validates :credit, presence: true, allow_nil: true
  validates :source, inclusion: { in: Global::SOURCES }
  validates :year, numericality: { integer_only: true, greater_than_or_equal_to: Global::MIN_YEAR }
  validates :user_id, numericality: { integer_only: true, greater_than: 0 }

  validate :year_is_not_in_future

  scope :include_player, -> { includes(user: :player) }

  def self.search(params, path)
    matches = include_player
    matches = case params[:order]
    when "id"
      matches.order(id: :asc)
    when "updated_at"
      matches.order(updated_at: :desc)
    else
      matches.order(year: :desc, id: :desc)
    end
    matches = matches.where("caption LIKE ?", "%#{params[:caption]}%") if params[:caption].present?
    matches = matches.where(year: params[:year].to_i) if params[:year].to_i > 0
    paginate(matches, params, path)
  end

  def width(style=:original)
    dimensions[style][0]
  rescue
    THUMB_SIZE
  end

  def height(style=:original)
    dimensions[style][1]
  rescue
    THUMB_SIZE
  end

  def dimensions_description
    s = []
    if dimensions.is_a?(Hash)
      styles_generated.unshift(:original).each do |style|
        if dimensions[style].is_a?(Array)
          info = "#{dimensions[style][0]}×#{dimensions[style][1]}"
        else
          info = "error (not an Array)"
        end
        s.push I18n.t("image.#{style}") + ": " + info
      end
    else
      s.push "Error (not a Hash)"
    end
    s.join(", ")
  end

  def styles_generated
    STYLES.keys.select { |style| dimensions.is_a?(Hash) && dimensions[style].is_a?(Array) }
  end

  # The smallest style at least width x height, else the biggest there is. Images uploaded before a
  # style was added don't have it until "bin/rake images:styles" runs, so fall back to the original.
  def style_for(width, height = 0)
    styles = styles_generated
    return :original if styles.empty?
    styles.find { |style| self.width(style) >= width && self.height(style) >= height } || styles.last
  end

  # Make every style from the original and record their dimensions, without changing updated_at.
  def generate_styles
    updated = updated_at
    data.reprocess!
    sizes = STYLES.keys.push(:original).each_with_object({}) do |style, hash|
      geometry = Paperclip::Geometry.from_file(data.path(style))
      hash[style] = [geometry.width.to_i, geometry.height.to_i]
    end
    update_columns(dimensions: sizes, updated_at: updated)
  end

  def short_type
    data_content_type.to_s.split("/").last.to_s.upcase
  end

  def expand(opt)
    lnk = "a"
    lnk_atrs = %Q{ href="/images/#{id}"}
    if opt[:type] == "IML"
      "<#{lnk}#{lnk_atrs}>#{CGI.escapeHTML(opt[:text] || 'image')}</#{lnk}>"
    elsif opt[:type] == "IMG"
      width, height = resize(opt)
      alt = CGI.escapeHTML(opt[:alt] || caption)
      margin = opt[:margin] || "yes"
      img_atrs = []
      wrp_atrs = []
      style = style_for(width, height)
      retina = style_for(2 * width, 2 * height)
      img_atrs.push %Q/src="#{data.url(style)}"/
      img_atrs.push %Q/srcset="#{data.url(style)} 1x, #{data.url(retina)} 2x"/ if self.width(retina) > self.width(style)
      img_atrs.push 'class="img-responsive"'
      unless opt[:align] == "center" && opt[:responsive] == "true"
        img_atrs.push %Q/width="#{width}"/
        img_atrs.push %Q/height="#{height}"/
      end
      if opt[:align] == "left" || opt[:align].blank?
        wrp = "div"
        wrp_atrs.push 'class="float-left%s"' % (margin == "yes" ? " right-margin" : "")
      elsif opt[:align] == "right"
        wrp = "div"
        wrp_atrs.push 'class="float-right%s"' % (margin == "yes" ? " left-margin" : "")
      else
        wrp = "center"
      end
      img_atrs.push %Q/alt="#{alt}"/
      img_atrs = (img_atrs.any?? " " : "") + img_atrs.join(" ")
      wrp_atrs = (wrp_atrs.any?? " " : "") + wrp_atrs.join(" ")
      "<#{wrp}#{wrp_atrs}><#{lnk}#{lnk_atrs}><img#{img_atrs}></#{lnk}><\/#{wrp}>"
    else
      raise "invalid expandable type (#{opt[:type]}) for Image"
    end
  end

  private

  def normalize_attributes
    %w[caption credit].each do |atr|
      if self.send(atr).present?
        self.send(atr).markoff!.trim!
      else
        self.send("#{atr}=", nil)
      end
    end
  end

  def check_dimensions
    dimensions = {}
    STYLES.keys.push(:original).each do |style|
      tempfile = data.queued_for_write[style]
      unless tempfile.nil?
        geometry = Paperclip::Geometry.from_file(tempfile)
        width = geometry.width.to_i
        height = geometry.height.to_i
        dimensions[style] = [width, height]
        if style == :original && source != "www1"
          if width > MAX_PIXELS || height > MAX_PIXELS
            errors.add(:base, "Width and height should not exceed #{MAX_PIXELS}")
          end
          if width < MIN_PIXELS || height < MIN_PIXELS
            errors.add(:base, "Width and height should be at least #{MIN_PIXELS}")
          end
        end
      end
    end
  rescue => e
    Failure.log("CheckImageDimensions", exception: e, id: id)
    errors.add(:base, "Problem checking image dimensions")
  ensure
    self.dimensions = dimensions unless dimensions.empty?
  end

  def year_is_not_in_future
    if year.to_i > Date.today.year
      errors.add(:year, "cannot be in the future")
    end
  end

  def resize(opt)
    width = opt[:width].to_i
    height = opt[:height].to_i
    if width <= 0 && height <= 0
      width = self.width
      height = self.height
    elsif width <= 0
      width = ((height.to_f / self.height) * self.width).ceil
    elsif height <= 0
      height = ((width.to_f / self.width) * self.height).ceil
    end
    [width, height]
  end
end
