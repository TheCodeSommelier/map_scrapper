class ScraperWorker
  include Sidekiq::Worker

  def perform
    puts "!!!Scraping scraping!!!"
  end

  private

  # !!! Antique e-shop "S" !!!
  # Scrapes the original pages
  def map_scrapping_s(map_maker)
    s_page = @virtual_browser.get("#{ENV.fetch('BASE_URL_S')}#{map_maker}",
                                  { headers: { "User-Agent" => user_agent_picker } })
    pages_urls = pagification_s(Nokogiri::HTML(s_page.body))
    crawling_pages(pages_urls)
  end

  # Gets pages from the S website
  def pagification_s(html_document)
    array_of_pages = []
    html_document.css("li a").each do |list_item|
      array_of_pages << list_item['href'] if list_item.text.match(/\d{1}/) && list_item.attr("class") != "cart"
    end
    array_of_pages.uniq
  end

  # Method that takes the urls and switches between pages of maps if more than 1
  # TODO: Refactor this method
  def crawling_pages(pages_urls)
    array_of_maps = []
    if pages_urls.length > 1
      pages_urls.each do |page_url|
        maps_index_page_html = @virtual_browser.get(page_url, { headers: { "User-Agent" => user_agent_picker } })
        array_of_maps += s_map_hash_builder(Nokogiri::HTML(maps_index_page_html.body))
      end
    else
      maps_index_page_html = @virtual_browser.get(pages_urls[0], { headers: { "User-Agent" => user_agent_picker } })
      array_of_maps += s_map_hash_builder(Nokogiri::HTML(maps_index_page_html.body))
    end
    array_of_maps
  end

  # Builds the hash for the map from S maps with the attributes of antique maps
  def s_map_instance_builder(html_document)
    html_document.css('.proditem').map do |map|
      Map.create(
        title: map.css('.blue.breakup').text,
        price: map.css('.euro').text,
        map_show_page_link: map['href'],
        image_url: map.css('.img').children[1].children[1].values[-1]
      )
    end
  end
end
