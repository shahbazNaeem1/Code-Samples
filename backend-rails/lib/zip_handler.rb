require 'zip'

class ZipHandler
  attr_accessor :file, :name

  def initialize(zip_file)
    @file = zip_file.tempfile
    @name = zip_file.original_filename.gsub('.zip', '')
  end

  def process!
    unzip_file!
    ZipBulkUploadJob.perform_later(name)
  end

  private
    def unzip_file!
      Zip::ZipFile.open(file) do |zip_file|
        zip_file.each do |file|
          file_path = File.join(name, file.name)
          FileUtils.mkdir_p(File.dirname(file_path))
          zip_file.extract(file, file_path) unless File.exist?(file_path)
        end
      end
    end
end
