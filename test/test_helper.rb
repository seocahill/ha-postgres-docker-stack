ENV['RACK_ENV'] = 'test'
require 'minitest/autorun'
require 'net/http'
require 'json'
require 'logger'
require 'pg'
require 'timeout'

module TestHelper
  logfile = File.new(File.join(__dir__, "logs", "test.log"), 'w')
  @@log = Logger.new(logfile)

  # Query postgres
  def query(host_name, query)
    begin
      con_args = connection_args(host_name)
      con = PG::Connection.open(*con_args)
      con.exec(query)
    rescue PG::Error => e
      puts e.message 
    ensure
      con.close if con
    end
  end

  def connection_args(host_name)
    host, port = case host_name
      when "master" then ["haproxy", 5000]
      when "replica" then ["haproxy", 5001]
      else [host_name, 5432]
    end
    #  pg args: host port options tty dbname user password
    [host, port, '', '', "pagila", "postgres", "postgres"]
  end

  # Stack state
  
  def wait_for_replicas(seconds = 16)
    print "\nwaiting on replicas"
    begin
      Timeout::timeout(seconds) {
        until JSON.parse(get_request("http://haproxy:8008/master").body).has_key?("replication")
          print "."
          sleep 3
        end
      }
    rescue TimeoutError
      puts "Timeout waiting for replication to synchonrize"
    end
    puts "\nok"
  end

  def lookup_master
    result = query("master", "SHOW data_directory;")
    result.getvalue(0,0)&.split('/')&.last
  end

  def lookup_replicas
    response = get_request("http://haproxy:8008/replica")
    if response.body
      JSON.parse(response.body)["replication"]&.map { |db| db["application_name"] }
    else
      []
    end
  end

  def node_in_recovery?(host_name)
    query(host_name, "SELECT pg_is_in_recovery();").getvalue(0,0) == "t"
  end

  # HTTP
  PatroniAPIError = Struct.new(:code, :error)

  def get_request(url)
    uri = URI(url)
    filename = File.basename(uri.path)
    http = Net::HTTP.new(uri.host, uri.port)
    request = Net::HTTP::Get.new(uri.request_uri)
    begin
      response = http.request(request)
      payload = JSON.parse(response.body)
      File.open(File.join(__dir__, "logs", "#{filename}.json"), 'w') do |f|
        f.write(JSON.pretty_generate(payload))
      end
      response
    rescue Exception => e
      @@log.error(e)
      PatroniAPIError.new(code: "500", error: e)
    end
  end

  def post_request(url, params)
    uri = URI(url)
    filename = File.basename(uri.path)
    http = Net::HTTP.new(uri.host, uri.port)
    request = Net::HTTP::Post.new(uri.request_uri)
    request["Content-Type"] = "application/json"
    request.body = params.to_json
    request.basic_auth("admin", "admin")
    begin
      response = http.request(request)
      File.open(File.join(__dir__, "logs", "#{filename}.json"), 'w') do |f|
        f.write({ message: response.body }.to_json)
      end
      response
    rescue Exception => e
      @@log.error(e)
      PatroniAPIError.new(code: "500", error: e)
    end
  end
end