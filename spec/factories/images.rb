FactoryBot.define do
  factory :image do
    # Skip Paperclip's thumbnail processing (several ImageMagick calls, ~0.1s per image) unless
    # a spec needs the thumbnail: use the :with_thumbnail trait for those (see issue #238).
    initialize_with { new.tap { |image| image.data.post_processing = false } }

    trait :with_thumbnail do
      initialize_with { new }
    end

    caption { "Fractal" }
    credit  { "Mark Orr" }
    year    { 2014 }
    data    { File.new("#{Rails.root}/spec/files/images/fractal.jpg") }
    user

    factory :image_april do
      caption { "April Cronin, Dubai, UAE" }
      year    { 1986 }
      data    { File.new("#{Rails.root}/spec/files/images/april.jpeg") }
    end

    factory :image_suzanne do
      caption { "Suzanne Connolly" }
      year    { 2000 }
      data    { File.new("#{Rails.root}/spec/files/images/suzanne.gif") }
      credit  { "サナナイチ" }
    end

    factory :image_gearoidin do
      caption { "Gearóidín Uí Laighléis" }
      year    { 2000 }
      data    { File.new("#{Rails.root}/spec/files/images/gearoidin.png") }
      credit  { nil }
    end
  end
end
