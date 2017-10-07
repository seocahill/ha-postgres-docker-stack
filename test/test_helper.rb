ENV['RACK_ENV'] = 'test'
require 'minitest/autorun'
require 'net/http'
require 'json'
require 'logger'

module TestHelper
  logfile = File.new(File.join(__dir__, "logs", "test.log"), 'w')
  @@log = Logger.new(logfile)

  def get_request(url = "http://haproxy:8008", filename = "response")
    uri = URI(url)
    begin
      response = Net::HTTP.get(uri)
      payload = JSON.parse(response)
      File.open(File.join(__dir__, "logs", "#{filename}.json"), 'w') do |f|
        f.write(JSON.pretty_generate(payload))
      end
      payload
    rescue Exception => e
      @@log.error(e)
      {}
    end
  end
end