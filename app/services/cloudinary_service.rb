class CloudinaryService
  def self.upload_image(file)
    raise HttpError.new("No file provided for upload.", status: HttpStatus::BAD_REQUEST) unless file.present?

    begin
      result = Cloudinary::Uploader.upload(
        file.tempfile.path,
        folder: "complaints",
        public_id: "complaint_#{SecureRandom.uuid}",
        overwrite: true,
        resource_type: "image"
      )
      result['secure_url']
    rescue => e
      Rails.logger.error "Cloudinary upload failed: #{e.message}"
      raise HttpError.new("Failed to upload image to Cloudinary.", status: HttpStatus::BAD_REQUEST)
    end
  end

  def self.delete_image(url)
    return unless url.present?

    public_id = extract_public_id(url)
    raise HttpError.new("Invalid Cloudinary URL.", status: HttpStatus::BAD_REQUEST) unless public_id

    begin
      Cloudinary::Uploader.destroy(public_id)
    rescue => e
      Rails.logger.error "Cloudinary deletion failed: #{e.message}"
      raise HttpError.new("Failed to delete image from Cloudinary.", status: HttpStatus::INTERNAL_SERVER_ERROR)
    end
  end

  private

  def self.extract_public_id(url)
    match = url.match(/\/complaints\/(.+)\./)
    match[1] if match
  end
end

