Paperclip.options[:command_path] = `which convert`.sub(/\/[^\/]+$/, "/") # Unix operating systems
# Paperclip.options[:command_path] = 'C:\\Program Files (x86)\\GnuWin32\\bin' # Windows only (default location of downloaded file.exe)
Paperclip.options[:content_type_mappings] = { pgn: "text/plain", csv: "text/plain", rtf: %w(text/rtf) } # adding additional mime types for paperclip validation

# Keep files uploaded in specs apart from development ones: ":system_dir" is "system" in every
# environment except test, where it's "system/test". The default url is otherwise Paperclip's own.
Paperclip.interpolates(:system_dir) { |_attachment, _style| Rails.env.test? ? "system/test" : "system" }
Paperclip::Attachment.default_options[:url] = "/:system_dir/:class/:attachment/:id_partition/:style/:filename"
