class ScrapeSJob < ApplicationJob
  include Sidekiq::Status

  queue_as :scrapers

  def perform
    @virtual_browser = Mechanize.new
    @map_columns = %i[title price map_show_page_link image_url map_maker]
    @user_agent = user_agent_picker
    Author.all.each do |author|
      map_scrapping_s(author.name)
    end
  end

  private

  # Scrapes and retrieves map results from Antique e-shop "S" website
  def map_scrapping_s(map_maker)
    s_page = @virtual_browser.get("#{ENV.fetch('BASE_URL_S')}#{map_maker}",
                                  { headers: { "User-Agent" => @user_agent } })
    pages_urls = pagification_s(Nokogiri::HTML(s_page.body))
    crawling_pages(pages_urls, map_maker)
  end

  # Gets pages of results from the S website
  def pagification_s(html_document)
    array_of_pages = []
    html_document.css("li a").each do |list_item|
      array_of_pages << list_item['href'] if list_item.text.match(/\d{1}/) && list_item.attr("class") != "cart"
    end
    array_of_pages.uniq
  end

  # Iterates through pages and collects maps from Antique e-shop "S"
  def crawling_pages(pages_urls, map_maker)
    array_of_maps = pages_urls.flat_map do |page_url|
      maps_index_page_html = @virtual_browser.get(page_url, { headers: { "User-Agent" => @user_agent } })
      s_map_instance_builder(Nokogiri::HTML(maps_index_page_html.body), map_maker)
    end
    Map.import(@map_columns, array_of_maps, batch_size: 20)
  end

  # Builds instances of maps from Antique e-shop "S" with attributes of antique maps
  def s_map_instance_builder(html_document, map_maker)
    html_document.css('.proditem').map do |map|
      Map.new(
        title: map.css('.blue.breakup').text,
        price: map.css('.euro').text,
        map_show_page_link: map['href'],
        image_url: map.css('.img').children[1].children[1].values[-1],
        map_maker:
      )
    end
  end

  # Selects a random user agent for use in scraping methods
  def user_agent_picker
    user_agents = File.readlines("user_agents.txt", chomp: true)
    user_agents.sample
  end
end
