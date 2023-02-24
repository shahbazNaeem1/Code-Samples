class ZipBulkUploadJob < ApplicationJob
  queue_as :bulk_upload

  attr_accessor :file_name

  def perform(file_name)
    @file_name = file_name

    Dir.foreach(file_name) do |auction_folder| next if extra_files(auction_folder)
      handle_auctions_folder(auction_folder)
    end

    FileUtils.rm_rf(file_name)
  end

  private
    def extra_files(item)
      item == '.' || item == '..' || item == '.DS_Store' || item.include?('__')
    end

    def handle_auctions_folder(auction_folder)
      auction_id = auction_folder
      auction = Auction.friendly.find(auction_id) rescue return

      auction_folder_path = [file_name, auction_folder].join('/')

      Dir.foreach(auction_folder_path) do |lot_folder| next if extra_files(lot_folder)
        handle_lot_folder(auction, auction_folder, lot_folder)
      end
    end

    def handle_lot_folder(auction, auction_folder, lot_folder)
      lot_id = lot_folder
      lot = auction.lots.find_by(lot_number: lot_id)
      return if lot.blank?

      lot_folder_path = [file_name, auction_folder, lot_folder].join('/')

      Dir.foreach(lot_folder_path) do |image_file_path| next if extra_files(image_file_path)
        handle_images(lot, lot_folder_path, image_file_path)
      end
    end

    def handle_images(lot, lot_folder_path, image_file_path)
      nested_image_file_path = [lot_folder_path, image_file_path].join('/')

      image_file = File.open(nested_image_file_path)
      lot.attachments.create(photo: image_file)
      image_file.close
    end
end
