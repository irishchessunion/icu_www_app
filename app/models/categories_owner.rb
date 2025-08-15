# frozen_string_literal: true

# Included by anything that supports multiple categories using a bitfield.
module CategoriesOwner
  def self.included(clazz)
    clazz.include FlagShihTzu

    clazz.has_flags 1 => :bulletin,
              2 => :tournament,
              3 => :biography,
              4 => :obituary,
              5 => :coaching,
              6 => :juniors,
              7 => :beginners,
              8 => :general,
              9 => :for_parents,
              10 => :primary,
              11 => :secondary,
              12 => :women,
              :column => 'categories',
              :flag_query_mode => :bit_operator,
              :check_for_column => false # Otherwise the migration fails as the Article class gets created before the migration happens.

    # The FlagShihTzu class adds a method selected_categories= that only handles arrays of symbols.
    clazz.alias_method :assign_selected_categories, :selected_categories=

    def clazz.bitset_for_categories(categories)
      bitset = 0
      categories.each do |category|
        bitset |= flag_mapping["categories"][category]
      end
      bitset
    end

  end

  CATEGORIES = %w[bulletin tournament biography obituary coaching juniors beginners general for_parents primary secondary women]
  # Used to convert from string to symbol, without creating extra symbols from user input
  CATEGORY_HASH = Hash[CATEGORIES.map(&:to_s).zip(0...CATEGORIES.size)]

  # @param categories An array of strings containing potentially correct Article categories
  # @return An array of legitimate symbols
  def CategoriesOwner.valid_categories(categories)
    valid = []
    categories.each do |category|
      index = Article::CATEGORY_HASH[category]
      if index
        valid << CATEGORIES[index]
      end
    end
    valid
  end

  # Sets the categories bitset by converting the array of strings to the appropriate set of bits.
  # Accepts an array of strings which should all be the string equivalent of the legal categories.
  # Any invalid strings will be ignored.
  def selected_categories=(categories)
    assign_selected_categories(CategoriesOwner.valid_categories(categories))
  end

  # A temporary helper method before we remove category altogether
  def category
    selected_categories.first || :any
  end
end
