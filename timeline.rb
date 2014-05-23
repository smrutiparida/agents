require "uri"
require "net/http"
require 'nokogiri'
require 'open-uri'
require 'json'
require 'twitter'
require 'faraday'
require 'faraday/request/multipart'
require 'faraday_middleware'
require 'logger'
require 'simple_oauth'
#require 'rufus/scheduler'
#scheduler = Rufus::Scheduler.new
#scheduler.every '5m' do
consumer_secret = "YbhyKkfgPA8bK1UrWVIKxaUkDcm5nnGk5QLdKue9k"
consumer_key =  "mQbKmq0yNCpDpvEEQvwGrw"
access_token =  "447737360-mwOPhkQ2skhArUgv9fVDW4S7Vu484OF9rTkg8bxG"
access_token_secret = "KKR6stuigeuMEvSvPRdC8Q4Ybi1cSSTDPDUXlmriG9saU"
search_url = ""
x = "{}"

post_url = 'https://api.twitter.com/1.1/beta/timelines/custom/curate.json'
uri = URI.parse(post_url)
credentials = { :consumer_key    => consumer_key, :consumer_secret => consumer_secret, :token => access_token, :token_secret => access_token_secret}
timelines = {"custom-467906368129609729" =>  "", 
             "custom-468683956418654208" =>  "8", 
             "custom-468683856267079680" =>  "7",
             "custom-468683758082592770" =>  "6",
             "custom-468683660896382977" =>  "5",
             "custom-468683561923391488" =>  "4",
             "custom-468683412513882112" =>  "3",
             "custom-468688261779439617" =>  "2",
             "custom-468798912468246532" =>  "us"
           }         
 

while true do
  credentials[:timestamp] = Time.now.to_i.to_s
  auth_key = SimpleOAuth::Header.new(:post, uri, {}, credentials)

  client = Faraday.new('https://api.twitter.com') do |faraday|
    faraday.headers['Authorization'] = auth_key.to_s
    faraday.headers['Accept'] = 'application/json'
    #send application/json in post
    faraday.request :json
    faraday.response :raise_error
    # Parse JSON response bodies
    faraday.response :parse_json
    # Set default HTTP adapter
    faraday.use Faraday::Response::Logger, Logger.new(STDOUT)
    faraday.adapter :net_http
    #faraday.adapter Faraday.default_adapter
  end
  timelines.each do |timeline, topic|
    low = 0
    high = 100
    while high < 1001 do
      request_data = {}
      request_data["id"] = timeline
      request_data["changes"] = []
      search_url = ""
      if topic == "us"
        search_url = "/tweet-store/index.php/api/TweetsUnique/get?&low=" + low.to_s + "&high=" + high.to_s + "&size=50&top=0&q=&uniqueUser=true&country=us&screen_name=&topic=&in_reply_to_status_id="
      else
        search_url = "/tweet-store/index.php/api/TweetsUnique/get?&low=" + low.to_s + "&high=" + high.to_s + "&size=50&top=0&q=&uniqueUser=true&country=in&screen_name=&topic=" + topic + "&in_reply_to_status_id="
      end
#      puts search_url

      begin
        http = Net::HTTP.new("54.254.80.93")
        http.read_timeout = 5
        resp = http.get(search_url)
        x = JSON.parse resp.body
        #  Rails.logger.info(x)
      rescue Exception=>e
        x = '{"found" : "error"}'
      rescue Net::ReadTimeout => e
        x = '{"found" : "error"}'
      end
      x["data"]["tweets"].reverse_each do |tweet|
        if tweet["in_reply_to_status_id"] == ""
          temp = {}
          temp["op"] = "add"
          temp["tweet_id"] = tweet["tweet_id"].to_s
          request_data["changes"].push(temp)
        end
      end
      low = high
      high = low + 100
  
      begin
        response = client.post '/1.1/beta/timelines/custom/curate.json', request_data do |r|
          r.headers['Content-Type'] = 'application/json'
        end
      rescue Twitter::Error::InternalServerError => e
        puts e.message
        puts e.backtrace
        puts "LOG::Twitter Unavailable Error Occured"
      rescue Faraday::Error::ConnectionFailed => e
        puts e.message
        puts e.backtrace
        puts "LOG::Faraday Connection Failed Error"
      rescue Exception =>e
        puts e.message
        puts e.backtrace
        puts "LOG::Error Occured"
      end
      #print response
      sleep(5)
    end
  end
  sleep(300)
end
