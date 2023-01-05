# Paperclip.options[:command_path] = `which convert`.sub(/\/[^\/]+$/, "/") # Unix operating systems
# Paperclip.options[:command_path] = `(gcm convert).Path`.sub(/\/[^\/]+$/, "/") # Windows
# Paperclip.options[:command_path] = `where convert`.sub(/\/[^\/]+$/, "/") # Windows
# Paperclip.options[:command_path] = `C:\\PROGRA~1\\ImageMagick-7.1.0-Q16-HDRI`.sub(/\/[^\/]+$/, "/") # image magick installation directory
# Paperclip.options[:content_type_mappings] = { pgn: "text/plain" } # Use on production server
Paperclip.options[:log] = true
Paperclip.options[:log_command] = true
Paperclip.options[:content_type_mappings] = { pgn: "text/plain", csv: "text/plain" } # Windows workaround for mimemagic issues