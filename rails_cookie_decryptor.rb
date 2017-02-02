VERSION = '1.0.0'

require 'base64'

module Decryptor
  def self.rails_3(cookie_str)
    cookie_str = URI.unescape(cookie_str)
    data, _digest = cookie_str.split('--')
    decoded_data = ::Base64.decode64(data)
    begin
      result = Marshal.load(decoded_data)
    rescue; end
    return result || 'Unable to decrypt.'
  end
end

Shoes.app do
  stack do
    para("Rails Cookie Decryptor v#{VERSION}", size: 24)
    para('Currently supporting Rails 3 cookies only.')

    para('Enter your cookie data here:')
    @cookie = edit_box('', width: 500, height: 155)
    para('... and it will decrypt here:')
    @output = edit_box('', width: 500, height: 200, state: 'readonly', background: '#DDDDDD')

    @cookie.change do |_editbox|
      @output.text = Decryptor.rails_3(@cookie.text)
    end
  end
end
