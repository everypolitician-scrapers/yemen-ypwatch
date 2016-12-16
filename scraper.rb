#!/bin/env ruby
# encoding: utf-8

require 'scraperwiki'
require 'nokogiri'
require 'pry'

require 'open-uri/cached'
OpenURI::Cache.cache_path = '.cache'

class String
  def tidy
    self.gsub(/[[:space:]]+/, ' ').strip
  end
end

def gender_from(str)
  return 'male' if str == 'ذكر'
  return 'female' if str == 'أنثى'
  binding.pry
end

def noko_for(url)
  Nokogiri::HTML(open(url).read)
end

def scrape_list(url)
  noko = noko_for(url)
  noko.css('.members_page_div a[href*="go=member"]/@href').map(&:text).uniq.each do |href|
    link = URI.join url, href
    scrape_person(link)
  end

  unless (next_page = noko.xpath('//div[@class="pagination"]//a[b[contains(.,"التالي")]]/@href')).empty?
    scrape_list(URI.join url, next_page.text)
  end
end

def scrape_person(url)
  noko = noko_for(url)
  box = noko.css('.reports_page_left')

# Members
  data = { 
    id: url.to_s[/id=(\d+)/, 1],
    term: 2003,
    image: box.css('a img/@src').text,
    source: url.to_s,
  }

  map = { 
    name: 'إسم العضو:',
    gender: 'الجنس:',
    faction: 'الكتلة السياسية:',
    area_id: 'الدائرة الإنتخابية:',
    area: 'المديرية:',
  }

  map.each do |en, ar|
    data[en] = box.xpath('.//td[text() = "%s"]/following-sibling::td' % ar).text.tidy
  end
  # data[:image] = URI.join(url, data[:image]).to_s unless data[:image].to_s.empty?

  data[:gender] = gender_from(data[:gender])
  puts data[:id]
  ScraperWiki.save_sqlite([:id, :term], data)
end

scrape_list('http://www.ypwatch.org/members.php')
