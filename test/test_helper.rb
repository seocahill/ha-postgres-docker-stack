ENV['RACK_ENV'] = 'test'
require 'minitest/autorun'
require 'net/http'
require 'json'
require 'logger'
require 'pg'

module TestHelper
  logfile = File.new(File.join(__dir__, "logs", "test.log"), 'w')
  @@log = Logger.new(logfile)

  # Query postgres

  # each test within a test file, is run on a new instance of the test class so need class variables for shared behaviour
  #  pg args: host port options tty dbname user password
  @@master_conn ||= PG::Connection.open("haproxy", 5000, '', '', "pagila", "postgres", "postgres")
  @@repl_conn ||= PG::Connection.open("haproxy", 5001, '', '', "pagila", "postgres", "postgres")

  def query(connection, query)
    db = (connection == "master") ? @@master_conn : @@repl_conn
    db.exec(query)&.getvalue(0,0) rescue nil
  end

  # Stack state

  def lookup_master
    query("master", "SHOW data_directory;")&.split('/')&.last
  end

  def lookup_replicas
    config = get_request("http://haproxy:8008/replica")
    config["replication"]&.map { |db| db["application_name"] }
  end

  def node_in_recovery?(node)
    conn = PG::Connection.open(node, 5432, '', '', "pagila", "postgres", "postgres")
    conn.exec("SELECT pg_is_in_recovery();").getvalue(0,0) == "t"
  end

  # HTTP

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

  def post_request(url, params)
    uri = URI(url)
    http = Net::HTTP.new(uri.host, uri.port)
    request = Net::HTTP::Post.new(uri.request_uri)
    request["Content-Type"] = "application/json"
    request.body = params.to_json
    request.basic_auth("admin", "admin")
    response = http.request(request)
  end
end