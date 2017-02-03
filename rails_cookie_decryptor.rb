APP_TITLE = 'Rails Cookie Decryptor'
VERSION = '1.0.0'

Shoes.setup do
  gem 'activesupport', '~> 5.0.0'
end

require 'base64'
require 'json'
require 'cgi'
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
    data, _digest = cookie_str.to_s.split('--')
    return DEFAULT_MSG unless data.present?

    decoded_data = ::Base64.decode64(data.to_s)
    begin
      result = Marshal.load(decoded_data)
    rescue; end
    return result || DEFAULT_MSG
  end

  def self.rails_4(cookie_str, key, salt, salt_signed, key_iter_num)
    return DEFAULT_MSG unless cookie_str.present? && key.present?

    begin
      key_generator = ::ActiveSupport::KeyGenerator.new(key, iterations: key_iter_num.to_s.to_i)
      secret = key_generator.generate_key(salt)
      sign_secret = key_generator.generate_key(salt_signed)
      encryptor = ::ActiveSupport::MessageEncryptor.new(secret, sign_secret)
    rescue; end
    return DEFAULT_MSG unless encryptor.present?

    begin
      cookie = CGI.unescape(cookie_str)
      result = encryptor.decrypt_and_verify(cookie)
    rescue; end
    return result || DEFAULT_MSG
  end
end

class AppLogic
  def initialize(shoes_app)
    %i{ cookie format output options key salt salt_signed key_iter_num }.each do |ivar|
      ivar = "@#{ivar}"
      instance_variable_set(ivar, shoes_app.instance_variable_get(ivar))
    end
  end

  def toggle_options
    if @format.text == Decryptor::AVAILABLE_FORMATS[:rails_2_or_3]
      @options.hide
    else
      @options.show
    end
  end

  def decrypt_cookie
    data = Decryptor.from(@format.text, @cookie.text, @key.text, @salt.text, @salt_signed.text, @key_iter_num.text)
    pretty_output = begin
      JSON.pretty_generate(data)
    rescue JSON::GeneratorError
      data
    end

    @output.text = pretty_output
  end
end

Shoes.app(title: APP_TITLE, height: 775) do
  stack(margin: 10) do
    para("#{APP_TITLE} v#{VERSION}", size: 24, align: "center")
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
          @key = edit_line('', width: 350, height: 50, right: 0, margin_bottom: 10)
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

    app_logic = AppLogic.new(self)

    @cookie.change do |_editbox|
      app_logic.decrypt_cookie
    end

    @format.change do |_editbox|
      app_logic.toggle_options
      app_logic.decrypt_cookie
    end

    @key.change do |_editline|
      app_logic.decrypt_cookie
    end

    @salt.change do |_editline|
      app_logic.decrypt_cookie
    end

    @salt_signed.change do |_editline|
      app_logic.decrypt_cookie
    end

    @key_iter_num.change do |_editline|
      app_logic.decrypt_cookie
    end
  end
end
