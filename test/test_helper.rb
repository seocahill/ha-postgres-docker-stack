ENV['RACK_ENV'] = 'test'
require 'minitest/autorun'
require 'net/http'
require 'json'
require 'logger'

module TestHelper
  logfile = File.new(File.join(__dir__, "logs", "test.log"), 'w')
  @@log = Logger.new(logfile)

  # each test within a test file, is run on a new instance of the test class so need class variables for shared behaviour
  #  pg args: host port options tty dbname user password
  @@master_conn ||= PG::Connection.open("haproxy", 5000, '', '', "pagila", "postgres", "postgres")
  @@repl_conn ||= PG::Connection.open("haproxy", 5001, '', '', "pagila", "postgres", "postgres")

  def query(connection, query)
    db = (connection == "master") ? @@master_conn : @@repl_conn
    db.exec(query)&.getvalue(0,0) rescue nil
  end

  def get_request(url = "http://haproxy:8008")
    uri = URI(url)
    filename = File.basename(uri.path)
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