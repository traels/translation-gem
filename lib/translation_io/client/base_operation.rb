require 'translation_io/client/base_operation/save_new_po_files_step'
require 'translation_io/client/base_operation/create_new_mo_files_step'
require 'translation_io/client/base_operation/save_new_yaml_files_step'
require 'translation_io/client/base_operation/save_special_yaml_files_step'
require 'translation_io/client/base_operation/dump_haml_gettext_keys_step'
require 'translation_io/client/base_operation/dump_slim_gettext_keys_step'

module TranslationIO
  class Client
    class BaseOperation
      attr_accessor :client, :params

      def initialize(client)
        @client = client
        @params = {}
      end

      private

      def self.perform_request(uri, params)
        begin
          params.merge!({
            'gem_version'        => TranslationIO.version,
            'source_language'    => TranslationIO.config.source_locale.to_s,
            'target_languages[]' => TranslationIO.config.target_locales.map(&:to_s)
          })

          http = Net::HTTP.new(uri.host, uri.port)
          http.use_ssl = uri.scheme == 'https'
          http.read_timeout = 500

          request = Net::HTTP::Post.new(uri.request_uri)
          request.set_form_data(params)

          response        = http.request(request)
          parsed_response = JSON.parse(response.body)

          if response.code.to_i == 200
            return parsed_response
          elsif response.code.to_i == 400 && parsed_response.has_key?('error')
            $stderr.puts "[Error] #{parsed_response['error']}"
          else
            $stderr.puts "[Error] Unknown error."
          end
        rescue Errno::ECONNREFUSED
          $stderr.puts "[Error] Server not responding."
        end
      end

      def cleanup
        FileUtils.rm_rf(File.join('tmp', 'translation'))
      end
    end
  end
end
