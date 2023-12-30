class ScrapeLJob < ApplicationJob
  include Sidekiq::Status

  queue_as :scrapers

  def perform
    @virtual_browser = Mechanize.new
    @map_columns = %i[title price map_show_page_link image_url map_maker]
    @user_agent = user_agent_picker
    Author.all.each do |author|
      map_scrapping_l(author.name)
    end
  end

  private

  # Scrapes and retrieves map results from Antique e-shop "L" website
  def map_scrapping_l(map_maker)
    l_page = @virtual_browser.get("#{ENV.fetch('BASE_URL_L')}#{map_maker}",
                                  { headers: { "User-Agent" => @user_agent } })
    array_of_maps = l_map_instance_builder(Nokogiri::HTML(l_page.body), map_maker)
    Map.import(@map_columns, array_of_maps, batch_size: 20)
  end

  # Builds instances of maps from Antique e-shop "L" with attributes of antique maps
  def l_map_instance_builder(html_document, map_maker)
    html_document.css('.product').map do |map|
      Map.new(
        title: map.css('.c309 a').attr('title').value,
        price: "KČ#{map.attr('data-price')}",
        map_show_page_link: "#{ENV.fetch('BASE_URL_L_MAP_SHOW_PAGE_AND_PIC')}#{map.css('.c309 a').attr('href').value}",
        image_url: "#{ENV.fetch('BASE_URL_L_MAP_SHOW_PAGE_AND_PIC')}#{map.css('.c309 a img').attr('src').value}",
        map_maker: map_maker
      )
    end
  end

  # Selects a random user agent for use in scraping methods
  def user_agent_picker
    user_agents = File.readlines("user_agents.txt", chomp: true)
    user_agents.sample
  end
end
