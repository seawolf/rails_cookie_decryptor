VERSION = '1.0.0'

require 'base64'
require 'json'

module Decryptor
  DEFAULT_MSG = 'Unable to decrypt.'.freeze

  AVAILABLE_FORMATS = {
    rails_2_or_3: 'Rails 2 or 3',
    rails_4_or_5: 'Rails 4 or 5'
  }

  def self.from(format, cookie_str)
    if format == AVAILABLE_FORMATS[:rails_2_or_3]
      return rails_3(cookie_str)
    else
      return rails_4(cookie_str)
    end
  end

  private

  def self.rails_3(cookie_str)

    cookie_str = URI.unescape(cookie_str)
    data, _digest = cookie_str.split('--')
    return DEFAULT_MSG unless data.to_s.length

    decoded_data = ::Base64.decode64(data.to_s)
    begin
      result = Marshal.load(decoded_data)
    rescue; end
    return result || DEFAULT_MSG
  end

  def self.rails_4(cookie_str)
    cookie_str.reverse
  end
end

Shoes.app(height: 750) do
  stack(margin: 10) do
    para("Rails Cookie Decryptor v#{VERSION}", size: 24)
    para('Currently supporting Rails 2 through 5.')

    stack(margin_top: 10) do
      para('Enter your cookie data here:')
      @cookie = edit_box('', width: 575, height: 150)
    end

    stack(margin_top: 10) do
      para('... and tell me a little bit more:')
			@format = list_box(items: Decryptor::AVAILABLE_FORMATS.values)
    end

    stack(margin_top: 10) do
      para('... and it will decrypt here:')
      @output = edit_box('', width: 575, height: 250, state: 'readonly')
    end

    @cookie.change do |_editbox|
      data = Decryptor.from(@format.text, @cookie.text)
      pretty_output = begin
        JSON.pretty_generate(data)
      rescue JSON::GeneratorError
        data
      end

      @output.text = pretty_output
    end
    @format.change do |_editbox|
      data = Decryptor.from(@format.text, @cookie.text)
      pretty_output = begin
        JSON.pretty_generate(data)
      rescue JSON::GeneratorError
        data
      end

      @output.text = pretty_output
    end
  end
end
