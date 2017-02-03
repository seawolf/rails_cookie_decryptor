VERSION = '1.0.0'

Shoes.setup do
  gem 'activesupport', '~> 5.0.0'
end

require 'base64'
require 'json'
require 'active_support'

module Decryptor
  DEFAULT_MSG = 'Unable to decrypt.'.freeze

  AVAILABLE_FORMATS = {
    rails_2_or_3: 'Rails 2 or 3',
    rails_4_or_5: 'Rails 4 or 5'
  }

  # Default values for Rails 4 apps
  DEFAULT_KEY_ITER_NUM = 1000
  DEFAULT_SALT         = "encrypted cookie"
  DEFAULT_SIGNED_SALT  = "signed encrypted cookie"

  def self.from(format, cookie_str, key, salt, salt_signed, key_iter_num)
    if format == AVAILABLE_FORMATS[:rails_2_or_3]
      return rails_3(cookie_str)
    else
      return rails_4(cookie_str, key, salt, salt_signed, key_iter_num)
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

  def self.rails_4(cookie_str, key, salt, salt_signed, key_iter_num)
    return DEFAULT_MSG unless (cookie_str.to_s.length && key.to_s.length && salt.to_s.length && salt_signed.to_s.length && key_iter_num.to_i > 0)

    key_generator = ::ActiveSupport::KeyGenerator.new(key, iterations: key_iter_num)
    secret = key_generator.generate_key(salt)
    sign_secret = key_generator.generate_key(salt_signed)

    encryptor = ::ActiveSupport::MessageEncryptor.new(secret, sign_secret)
  end
end

Shoes.app(height: 775) do
  stack(margin: 10) do
    para("Rails Cookie Decryptor v#{VERSION}", size: 24, align: "center")
    para('Currently supporting Rails 2 through 5.', align: "center")

    stack(margin_top: 10) do
      para('Enter your cookie data here:')
      @cookie = edit_box('', width: 575, height: 150)
    end

    stack(margin_top: 10) do
      para('... and tell me a little bit more:')
      @format = list_box(items: Decryptor::AVAILABLE_FORMATS.values)
      @options = stack(hidden: true) do
        flow do
          para('Secret Key Base:', width: 200)
          @key = edit_line('', width: 350, right: 0)
        end

        flow do
          para('Salt:', width: 200)
          @salt = edit_line(Decryptor::DEFAULT_SALT, width: 350, right: 0)
        end

        flow() do
          para('Signed Salt:', width: 200)
          @salt_signed = edit_line(Decryptor::DEFAULT_SIGNED_SALT, width: 350, right: 0)
        end

        flow do
          para('Key Iteration Number:', width: 200)
          @key_iter_num = edit_line(Decryptor::DEFAULT_KEY_ITER_NUM, width: 350, right: 0)
        end
      end
    end

    stack(margin_top: 10) do
      para('... and it will decrypt here:')
      @output = edit_box('', width: 575, height: 350, state: 'readonly')
    end

    @cookie.change do |_editbox|
      data = Decryptor.from(@format.text, @cookie.text, @key.text, @salt.text, @salt_signed.text, @key_iter_num.text.to_s.to_i)
      pretty_output = begin
        JSON.pretty_generate(data)
      rescue JSON::GeneratorError
        data
      end

      @output.text = pretty_output
    end

    @format.change do |_editbox|
      if @format.text == Decryptor::AVAILABLE_FORMATS[:rails_2_or_3]
        @options.hide
      else
        @options.show
      end

      data = Decryptor.from(@format.text, @cookie.text, @key.text, @salt.text, @salt_signed.text, @key_iter_num.text.to_s.to_i)
      pretty_output = begin
        JSON.pretty_generate(data)
      rescue JSON::GeneratorError
        data
      end

      @output.text = pretty_output
    end
  end
end
