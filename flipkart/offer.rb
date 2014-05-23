# myapp.rb
require "active_support/core_ext"
require 'rubygems'
require 'agent_xmpp'
require 'net/http'
require 'json'

chat do
  out = Net::HTTP.get('www.peoplefied.com','/railways/pnr?q=' + params[:body])
#  print out
  res = []
  res = JSON.parse(out) unless out.empty?
  out_status = ""
  if res.empty?
    out_status = "Sorry, problem in getting status"
  else
    res.each do |x| 
      out_status += x["status"] if x.has_key?("status") and !x["status"].nil?
      out_status += ", Berth: " + x["berth"] + "\n" if x.has_key?("berth") and !x["berth"].nil?
    end
  end
  out_status
#  res.body
#  params[:body].reverse
end
#command 'helo' do
# 'Hello World' 
#end
