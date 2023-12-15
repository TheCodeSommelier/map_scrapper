class MapsController < ApplicationController

  def index
    @virtual_browser = Mechanize.new
    sanderus_maps = map_scrapping_sanderus
    lazarova_maps = map_scrapping_lazarova
    raremaps_maps = map_scrapping_raremaps
    @all_scrapped_maps = sanderus_maps + raremaps_maps + lazarova_maps
    # @all_scrapped_maps = sanderus_maps
  end

  private

  # Builds out a hash for each map to be displayed on the idex from the sanderusmaps.com web page
  def map_scrapping_sanderus
    # Uncomment once in production
    # url = "https://sanderusmaps.com/search?q_cat=&q_title=&q_keywords=&q_mapmaker=#{map_maker}&q_mapnum=&_gl=1*5yozj9*_up*MQ..*_ga*MTk4OTIxODY3OS4xNzAyNTg3MDU2*_ga_4GV6JSEDD8*MTcwMjU4NzA1NS4xLjEuMTcwMjU4NzMyNC4wLjAuMA.."
    page = @virtual_browser.get("https://sanderusmaps.com/search?q_cat=&q_title=&q_keywords=&q_mapmaker=Sebastian+M%C3%BCnster&q_mapnum=&_gl=1*1v82r1x*_up*MQ..*_ga*Mjk5NTQ4ODYuMTcwMjY0MzUzNg..*_ga_4GV6JSEDD8*MTcwMjY0MzUzNS4xLjEuMTcwMjY0MzUzOS4wLjAuMA..")
    document = Nokogiri::HTML(page.body)

    # Local downloaded page scrapping (for dev purposes)
    html_content = File.read('app/assets/pages_to_scrape/map.html')
    document = Nokogiri::HTML(html_content)

    document.css('.proditem').map do |map|
      {
        map_show_page_link: map['href'],
        map_image_url: map.css('.img').children[1].children[1].values[-1],
        map_title: map.css('.blue.breakup').text,
        map_price: map.css('.euro').text
      }
    end
  end

  def map_scrapping_raremaps
    # Uncomment once in production
    # url = "https://www.raremaps.com/inventory/search?q=#{map_maker}"
    page = @virtual_browser.get("https://www.raremaps.com/inventory/search?q=Sebastien+munster")
    document = Nokogiri::HTML(page.body)

    document.css('.item.card').map do |map|
      {
        map_show_page_link: "https://www.raremaps.com#{map.css('.image').children[1]['href']}",
        map_image_url: map.css('.image').children[1].children[1]['src'],
        map_title: map.css('.info').children[1].css('.title').text.strip,
        map_price: map.css('aside').children[1].text.strip.tr(" ", "")
      }
    end
  end

  def map_scrapping_lazarova
    # Uncomment once in production
    # url = "https://www.raremaps.com/inventory/search?q=#{map_maker}"
    page = @virtual_browser.get("https://www.antikvariat-marketa-lazarova.cz/510446575/e-search?q=Sebastian+M%C3%BCnster")
    document = Nokogiri::HTML(page.body)

    # Dev testing local html
    # html_content = File.read('app/assets/pages_to_scrape/lazarova.html')
    # document = Nokogiri::HTML(html_content)

    document.css('.product').map do |map|
      {
        map_show_page_link: "https://www.antikvariat-marketa-lazarova.cz#{document.css('.product .c309 a').attr('href').value}",
        map_image_url: "https://www.antikvariat-marketa-lazarova.cz#{document.css('.product .c309 a img').attr('src').value}",
        map_title: document.css('.product .c309 a').attr('title').value,
        map_price: "KČ#{document.css('.product').attr('data-price').value}"
      }
    end
  end
end
