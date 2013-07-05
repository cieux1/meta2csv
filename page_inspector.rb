require 'nokogiri'
require 'open-uri'
require 'uri'

class Page
  attr_accessor :url

  def initialize(url)
    @doc ||= Nokogiri::HTML(open(url)) rescue nil
    @url = url
  end
  
  def title
    if @doc
      title_txt ||= @doc.css('title').text.gsub(/\t|\n|\r/, '')
      title_txt.empty? ? " " : title_txt
      title_txt.gsub(/\,\t|\n|\r/, ' ')
    else
      title_txt = "404"
    end
  end
  
  def description
    begin
      desc ||= @doc.at('meta[@name="Description"]')['content']
    rescue
      begin
        desc ||= @doc.at('meta[@name="description"]')['content']
      rescue
        desc ||= " "
      end
    end
    desc.gsub(/\,\t|\n|\r/, ' ')
  end
  
  def keywords
    begin
      keywords ||= @doc.at('meta[@name="keywords"]')['content']
    rescue
      begin
        keywords ||= @doc.at('meta[@name="Keywords"]')['content']
      rescue
        keywords ||= " - "
      end
    end
    keywords.gsub(",","-")
  end
  
  def header_one
    h_one ||= @doc.at('h1').inner_html rescue nil
    h_one.gsub(/\t|\n|\r/, '') unless h_one.nil?
  end
  
  def header_two
    h_two = []
    (@doc/"h2").each {|d| h_two << d.inner_html}
    h_two.empty? ? [' '] : h_two
    h_two.join(",").gsub(/\t|\n|\r/, '')   
  end
  
  def redirect_page?
    /http-equiv=\"refresh\"/ =~ @doc.to_s.downcase
  end

  def redirect
    "redirect" if redirect_page?
  end

  def canonical_url
    if /<link rel\=\"canonical\" href\=\"(.*?)\"/ =~ @doc.to_s.downcase
      clean($1)
    else
      " "
    end
  end

  def noindex_page?
    /content=\"\w*(,\s?)?noindex\"/ =~ @doc.to_s.downcase
  end

  def noindex
    "noindex" if noindex_page?
  end

  def nofollow_page?
    /content=\"\w*(,\s?)?nofollow\"/ =~ @doc.to_s.downcase
  end

  def nofollow
    "nofollow" if noindex_page?
  end

  def clean(u)
    u.gsub("index\.html", "").gsub("http\:\/\/", "")
  end

  def print_less
    "#{clean(@url)}, #{redirect}\n\r"
  end

  def print_all
    "#{clean(@url)}, #{redirect}, #{noindex}, #{nofollow}, #{canonical_url}, #{title}, #{description}, #{keywords}, #{header_one}, #{header_two}\n\r"
  end

end

def print_header
  "url, redirect, noindex, nofollow, canonical, title, meta description, keywords, h1, h2\n\r"
end

def fetch_meta_from_all(pages)
  str = print_header
  count = 0
  pages.each do |page|
    begin
      url = Page.new(page)
      if url.redirect_page?
        str << url.print_less
      else
        str << url.print_all
      end
    rescue => e
      str << "#{page},URL not found ? \n\r"
    end
    count += 1
    break if count == 300
  end
  str
end