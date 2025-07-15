require "tus/server"
require "tus/storage/filesystem"

# Configure tus server with local file storage
Tus::Server.opts.merge!(
  storage: Tus::Storage::Filesystem.new(
    Rails.root.join("storage", "uploads").to_s,
    permissions: 0644,
    directory_permissions: 0755
  ),
  max_size: 10 * 1024 * 1024 * 1024, # 10GB max file size
  chunk_size: 5 * 1024 * 1024,       # 5MB chunks
  expiration: {
    expires: 24 * 60 * 60,           # 24 hours
    cleanup_interval: 60 * 60        # Clean up every hour
  }
)

# Add CORS headers for frontend integration
Tus::Server.opts[:cors] = {
  origin: ENV.fetch("FRONTEND_URL", "*"),
  methods: ["GET", "POST", "HEAD", "PATCH", "DELETE", "OPTIONS"],
  headers: ["Authorization", "Content-Type", "Tus-Resumable", "Upload-Length", "Upload-Metadata", "Upload-Offset"],
  credentials: true
}

# ========================================
# VALIDATION EXAMPLES (Uncomment to use)
# ========================================

# 1. File Type Validation
# Tus::Server.opts[:allowed_extensions] = ['.jpg', '.png', '.pdf', '.zip', '.mp4']
# Tus::Server.opts[:allowed_mime_types] = ['image/jpeg', 'image/png', 'application/pdf', 'application/zip', 'video/mp4']

# 2. Pre-upload Validation Hook
# Tus::Server.opts[:before_create] = lambda do |env|
#   request = Rack::Request.new(env)
#   upload_length = request.env['HTTP_UPLOAD_LENGTH'].to_i
#   
#   # File size validation
#   if upload_length > 100 * 1024 * 1024 # 100MB limit
#     return [413, {}, ['File too large. Maximum size is 100MB']]
#   end
#   
#   # File type validation from metadata
#   metadata = request.env['HTTP_UPLOAD_METADATA']
#   if metadata
#     filename = extract_filename_from_metadata(metadata)
#     unless allowed_file_type?(filename)
#       return [415, {}, ['File type not allowed']]
#     end
#   end
#   
#   # Authentication validation
#   auth_header = request.env['HTTP_AUTHORIZATION']
#   unless valid_auth_token?(auth_header)
#     return [401, {}, ['Unauthorized']]
#   end
#   
#   # Rate limiting
#   user_id = extract_user_id(request)
#   if upload_limit_exceeded?(user_id)
#     return [429, {}, ['Too many uploads. Please wait before uploading again']]
#   end
#   
#   # Storage quota validation
#   if storage_quota_exceeded?(user_id, upload_length)
#     return [413, {}, ['Storage quota exceeded']]
#   end
#   
#   nil # Continue with upload
# end

# 3. Post-upload Validation Hook
# Tus::Server.opts[:after_complete] = lambda do |env|
#   upload_id = env['PATH_INFO'].split('/').last
#   file_path = Rails.root.join("storage", "uploads", upload_id)
#   
#   # File content validation
#   unless valid_file_content?(file_path)
#     File.delete(file_path) if File.exist?(file_path)
#     Rails.logger.error "Invalid file content detected: #{upload_id}"
#     return [400, {}, ['Invalid file content']]
#   end
#   
#   # Trigger background processing
#   # ProcessUploadJob.perform_later(upload_id)
#   
#   Rails.logger.info "Upload completed successfully: #{upload_id}"
# end

# ========================================
# HELPER METHODS (Implement as needed)
# ========================================

# def allowed_file_type?(filename)
#   allowed_extensions = ['.jpg', '.png', '.pdf', '.zip', '.mp4']
#   extension = File.extname(filename).downcase
#   allowed_extensions.include?(extension)
# end

# def extract_filename_from_metadata(metadata)
#   metadata_parts = metadata.split(',')
#   filename_part = metadata_parts.find { |part| part.strip.start_with?('filename ') }
#   if filename_part
#     encoded_filename = filename_part.split(' ').last
#     Base64.decode64(encoded_filename)
#   else
#     nil
#   end
# end

# def valid_auth_token?(auth_header)
#   # Implement your authentication logic here
#   # Example: JWT token validation, API key validation, etc.
#   return true if Rails.env.development? # Skip auth in development
#   
#   return false unless auth_header
#   token = auth_header.gsub('Bearer ', '')
#   
#   # Add your token validation logic
#   # JWT.decode(token, Rails.application.secrets.secret_key_base)
#   true
# end

# def extract_user_id(request)
#   # Extract user ID from request
#   # This could be from JWT token, API key, etc.
#   auth_header = request.env['HTTP_AUTHORIZATION']
#   # Parse token and extract user_id
#   'default_user' # Placeholder
# end

# def upload_limit_exceeded?(user_id)
#   # Implement rate limiting logic
#   # Example: Check Redis for upload count in last hour
#   false # Placeholder
# end

# def storage_quota_exceeded?(user_id, upload_size)
#   # Implement storage quota logic
#   # Example: Check current storage usage + new file size
#   false # Placeholder
# end

# def valid_file_content?(file_path)
#   # Implement file content validation
#   # Example: Check magic numbers, scan for viruses, etc.
#   true # Placeholder
# end

# Create uploads directory if it doesn't exist
FileUtils.mkdir_p(Rails.root.join("storage", "uploads")) 