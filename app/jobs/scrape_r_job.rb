class ScrapeRJob < ApplicationJob
  include Sidekiq::Status

  queue_as :scrapers

  def perform
    @virtual_browser = Mechanize.new
    @map_columns = %i[title price map_show_page_link image_url map_maker]
    @user_agent = user_agent_picker
    Author.all.each do |author|
      map_scrapping_r(author.name)
    end
  end

  private

  # Scrapes and retrieves map results from Antique e-shop "R" website
  def map_scrapping_r(map_maker)
    r_page = @virtual_browser.get("#{ENV.fetch('BASE_URL_R')}#{map_maker}",
                                  { headers: { "User-Agent" => @user_agent } })
    r_html_document = Nokogiri::HTML(r_page.body)
    crawler_r(r_html_document, map_maker)
  end

  # Crawls through pages and collects maps from Antique e-shop "R"
  def crawler_r(r_html_document, map_maker)
    url_endpoints = r_html_document.css("ul.pager li a").map do |a_tag|
      a_tag.attr('href').slice(/&order_by=([^&]+)&relevance=([^&]+)&page=([^&]+)/)
    end

    array_of_maps = url_endpoints.uniq.flat_map do |url_enpoint|
      page = @virtual_browser.get("#{ENV.fetch('BASE_URL_R')}#{map_maker}#{url_enpoint}",
                                  { headers: { "User-Agent" => @user_agent } })
      r_map_instance_builder(Nokogiri::HTML(page.body), map_maker)
    end
    array_of_maps.compact!
    Map.import(@map_columns, array_of_maps, batch_size: 20)
  end

  # Builds instances of maps from Antique e-shop "R" with attributes of antique maps
  def r_map_instance_builder(r_html_document, map_maker)
    r_html_document.css('.item.card').map do |map|
      Map.new(
        title: map.css('.info').children[1].css('.title').text.strip,
        price: map.css('aside').children[1].text.strip.tr(" ", ""),
        map_show_page_link: "#{ENV.fetch('BASE_URL_R_MAP_SHOW_PAGE')}#{map.css('.image').children[1]['href']}",
        image_url: map.css('.image').children[1].children[1]['src'],
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
