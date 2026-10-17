namespace :images do
  # Safe to stop and rerun: it only does images that are missing a style. Pass a number to do a batch,
  # e.g. "bin/rake images:styles[100]", and run it under nice to go easy on the server.
  desc "Generate missing image styles (after adding one to Image::STYLES)"
  task :styles, [:limit] => :environment do |task, args|
    missing = Image.order(:id).select { |image| image.styles_generated.size < Image::STYLES.size }
    batch = args[:limit].present? ? missing.first(args[:limit].to_i) : missing
    puts "#{missing.size} images are missing styles, doing #{batch.size}"
    batch.each do |image|
      image.generate_styles
      print "."
    rescue => e
      puts "\nImage #{image.id}: #{e.message}"
    end
    puts "\ndone"
  end
end
