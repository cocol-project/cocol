require "http/client"
require "json"
require "digest/sha1"

puts "GO"
(1..1000).each do |_i|
  timestamp = Time.utc.to_unix
  from = Random::Secure.urlsafe_base64
  to = Random::Secure.urlsafe_base64
  hash = Digest::SHA1.hexdigest("#{timestamp}#{from}#{to}")
  nodes = %w(3002 3003 3004 3005 3006 3007 4001 4002 4003)
  url = "http://localhost:#{nodes.sample(1)[0]}/transactions"

  begin
    HTTP::Client.post(
      url,
      headers: HTTP::Headers{
        "Content-Type" => "application/json",
        "X-Node-Id"    => "E2E-Node",
      },
      body: {
        from:      from,
        to:        to,
        amount:    Random.rand(100),
        timestamp: timestamp,
        hash:      hash,
      }.to_json
    )
  rescue
    puts "TIMEOUT: #{url}"
  end

  puts "txn-#{timestamp}-#{hash}"
  sleep Random.new.rand(0.1..3.2)
end
