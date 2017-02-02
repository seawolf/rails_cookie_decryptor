VERSION = '1.0.0'

require 'base64'
require 'json'

module Decryptor
  def self.rails_3(cookie_str)
    default_msg = 'Unable to decrypt.'

    cookie_str = URI.unescape(cookie_str)
    data, _digest = cookie_str.split('--')
    return default_msg unless data.to_s.length

    decoded_data = ::Base64.decode64(data.to_s)
    begin
      result = Marshal.load(decoded_data)
    rescue; end
    return result || default_msg
  end
end

Shoes.app(height: 750) do
  stack(margin: 10) do
    para("Rails Cookie Decryptor v#{VERSION}", size: 24)
    para('Currently supporting Rails 3 cookies only.')

    stack(margin_top: 10) do
      para('Enter your cookie data here:')
      @cookie = edit_box('', width: 575, height: 150)
    end
    stack(margin_top: 10) do
      para('... and it will decrypt here:')
      @output = edit_box('', width: 575, height: 250, state: 'readonly')
    end

    @cookie.change do |_editbox|
      data = Decryptor.rails_3(@cookie.text)
      pretty_output = begin
        JSON.pretty_generate(data)
      rescue JSON::GeneratorError
        data
      end

      @output.text = pretty_output
    end
  end
end
