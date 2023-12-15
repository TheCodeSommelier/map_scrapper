require 'mechanize'

class MapsController < ApplicationController

  def index
    # mechanize = Mechanize.new
    @sanderus_maps = map_scrapping_sanderus
  end

  private

  # Builds out a hash for each map to be displayed on the idex from the sanderusmaps.com web page
  def map_scrapping_sanderus
    # url = "https://sanderusmaps.com/search?q_cat=&q_title=&q_keywords=&q_mapmaker=#{map_maker}&q_mapnum=&_gl=1*5yozj9*_up*MQ..*_ga*MTk4OTIxODY3OS4xNzAyNTg3MDU2*_ga_4GV6JSEDD8*MTcwMjU4NzA1NS4xLjEuMTcwMjU4NzMyNC4wLjAuMA.."
    # page = mechanize.get(url)
    html_content = File.read('../assets/pages_to_scrape/map.html')
    doc = Nokogiri::HTML(html_content) # Is global to be used in building map records
    doc.css('.proditem').map do |map|
      {
        map_show_page_link: map['href'],
        map_image_url: map.css('.img').children[1].children[1].values[-1],
        map_title: map.css('.blue.breakup').text,
        map_price: map.css('.euro').text.tr('€', '').to_i
      }
    end
  end
end
