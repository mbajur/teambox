module Downloads
  module Downloading
    extend ActiveSupport::Concern

    private

    def download_send_file(upload, options = {})
      send_options = { disposition: "attachment" }.merge(options[:send_file] || {})

      send_data upload.asset.download,
        filename: upload.asset.filename.to_s,
        type: upload.asset.content_type,
        disposition: send_options[:disposition]
    end
  end
end
