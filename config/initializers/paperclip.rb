Paperclip.options[:command_path] = `which convert`.sub(/\/[^\/]+$/, "/") # Unix operating systems
# Paperclip.options[:command_path] = 'C:\\Program Files (x86)\\GnuWin32\\bin' # Windows only (default location of downloaded file.exe)
Paperclip.options[:content_type_mappings] = { pgn: "text/plain", csv: "text/plain", rtf: %w(text/rtf) } # adding additional mime types for paperclip validation