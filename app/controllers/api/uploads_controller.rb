class Api::UploadsController < ApplicationController
  # List uploaded files
  def list_files
    begin
      files = []
      uploads_dir = Rails.root.join("storage", "uploads")
      
      if Dir.exist?(uploads_dir)
        Dir.entries(uploads_dir).each do |entry|
          next if entry.start_with?('.') || entry.end_with?('.info')
          
          file_path = uploads_dir.join(entry)
          info_path = uploads_dir.join("#{entry}.info")
          
          if File.file?(file_path)
            file_info = {
              id: entry,
              size: File.size(file_path),
              created_at: File.mtime(file_path)
            }
            
            # Read metadata from .info file
            if File.exist?(info_path)
              begin
                info_content = File.read(info_path)
                metadata = JSON.parse(info_content)
                
                if metadata['Upload-Metadata']
                  # Extract filename from metadata
                  metadata_parts = metadata['Upload-Metadata'].split(',')
                  filename_part = metadata_parts.find { |part| part.strip.start_with?('filename ') }
                  if filename_part
                    encoded_filename = filename_part.split(' ').last
                    file_info[:filename] = Base64.decode64(encoded_filename)
                  end
                end
                
                file_info[:upload_length] = metadata['Upload-Length']
                file_info[:upload_offset] = metadata['Upload-Offset']
              rescue => e
                file_info[:filename] = "Unknown"
              end
            end
            
            files << file_info
          end
        end
        
        # Sort by creation time (newest first)
        files.sort_by! { |f| f[:created_at] }.reverse!
      end
      
      render json: {
        success: true,
        files: files,
        count: files.length
      }
      
    rescue => e
      Rails.logger.error "List files error: #{e.message}"
      render json: { error: 'Failed to list files' }, status: :internal_server_error
    end
  end
end 