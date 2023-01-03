# Paperclip.options[:command_path] = `which convert`.sub(/\/[^\/]+$/, "/") # Unix operating systems
# Paperclip.options[:command_path] = `C:/Windows/system32/convert.exe` # run Get-Command convert in powershell to find the right path
# Paperclip.options[:command_path] = `C:\\PROGRA~1\\ImageMagick-7.1.0-Q16-HDRI` # image magick installation directory
# Paperclip.options[:content_type_mappings] = { pgn: "text/plain" } # Use on production server
Paperclip.options[:log] = true
Paperclip.options[:log_command] = true
Paperclip.options[:content_type_mappings] = { pgn: "text/plain", csv: "text/plain" } # Windows workaround for mimemagic issues