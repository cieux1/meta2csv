# -*- encoding: utf-8 -*-
require 'rubygems'
require 'bundler/setup'
require 'sinatra'
require 'anemone'
require './page_inspector'

def collected_pages(site_url)
  
  opts = {
  :user_agent => "TestRobot/0.00",
  :discard_page_bodies => true,
  :depth_limit => 3,
  :redirect_limit => 3,
  :read_timeout => 3
  }

  arr = []
  Anemone.crawl(site_url, options = opts) do |anemone|
    count = 0
    anemone.on_every_page do |page|
      arr << page.url.to_s
      count += 1
      anemone.stop_crawl if count == 300
    end
  end
  arr.uniq
end

def get_meta(pages)
  puts "fetching...\n\n"
  fetch_meta_from_all(pages)
end

def check_url(u)
  if u == "http://" || u.empty?
    raise "invalid url"
  else
    begin
      bname = File.basename(u)
      u = u.gsub(bname, "") if /html|shtml|php|jsp/ =~ bname
      u = u.gsub(/^(http\:\/\/){2}/, "http://")
      u = u.gsub(/\/+$/, "")
    rescue => e
      "Invalid URL(#{u}): #{e}"
    end
  end
end


get "/" do
  @title = "metaExport2csv (beta)"
  erb :index
end

get '/crawl' do
  begin
    @domain = check_url(params[:site_url])
    @site = @domain.to_s + "/"
    csv_name = "#{@domain}-#{Time.now.strftime("%Y-%m-%d-%H-%M-%S")}.csv"
    content_type 'text/csv'
    attachment csv_name
    @site_data = get_meta(collected_pages(@site))
  rescue => @e
    erb :crawl_error
  end
end