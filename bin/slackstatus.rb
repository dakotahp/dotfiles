#! /usr/bin/env ruby

require 'bundler/inline'

gemfile do
  source 'https://rubygems.org'
  gem 'httparty'
end

class Slack
  include HTTParty
  base_uri "https://slack.com/api"

  DEFAULT_TOKEN = "xoxp-2277908518-602797513381-683499467682-08299c354f4752b6e30569dc482a505e"  # <----- https://api.slack.com/custom-integrations/legacy-tokens
  WORKING_EMOJI = :construction_worker
  VERBOSE = false
  attr_accessor :token

  def initialize(token: DEFAULT_TOKEN)
    @token = token
  end

  def work_time!
    set_status text: "Workin'", emoji: WORKING_EMOJI
    set_presence! :auto
    puts "Back to work!"
  end

  def done!
    set_status text: ""
    set_presence! :away
    puts "Done."
  end

  def lunch_time!(minutes:)
    if minutes.nil?
      expiration = nil
      exp_time   = ""
    else
      expiration = Time.now.to_i + (minutes.to_i * 60)
      exp_time   = Time.at(expiration).strftime "%I:%M %p"
    end

    set_status text: "Out to lunch", emoji: :burrito, expiration: expiration
    set_presence! :away
    puts "Lunching till #{exp_time}"
  end

  def auth_test
    response = self.class.get "/auth.test", headers: base_headers, verbose: VERBOSE

    if VERBOSE
      p response
    end
  end


private

  def set_status(text:, emoji: nil, expiration: nil)
    status_emoji = emoji ? ":#{emoji}:" : nil

    body = {
      profile:  {
        status_text: text,
        status_emoji: status_emoji
      }
    }
    body[:profile][:status_expiration] = expiration if expiration
    response = self.class.post "/users.profile.set", body: body.to_json, headers: base_headers, verbose: VERBOSE

    if VERBOSE
      p response
    end
  end

  def set_presence!(presence)
    body = {presence: presence}
    response = self.class.post "/users.setPresence", body: body.to_json, headers: base_headers, verbose: VERBOSE

    if VERBOSE
      p response
    end
  end

  def base_headers
    {
      "content-type"  => "application/json",
      "Authorization" => "Bearer #{token}"
    }
  end
end

case ARGV[0].to_s
  when "lunch" then Slack.new.lunch_time!(minutes: ARGV[1])
  when "work"  then Slack.new.work_time!
  when "done"  then Slack.new.done!
  when "test"  then Slack.new.auth_test
  else              puts "Specify lunch, work, done, or test."
end
