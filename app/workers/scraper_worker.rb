class ScraperWorker
  include Sidekiq::Worker

  def perform
    Map.destroy_all
    Author.all.each do |author|
      map_scrapping_s(author.name)
      map_scrapping_r(author.name)
      map_scrapping_l(author.name)
    end
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
        array_of_maps += s_map_instance_builder(Nokogiri::HTML(maps_index_page_html.body))
      end
    else
      maps_index_page_html = @virtual_browser.get(pages_urls[0], { headers: { "User-Agent" => user_agent_picker } })
      array_of_maps += s_map_instance_builder(Nokogiri::HTML(maps_index_page_html.body))
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
        image_url: map.css('.img').children[1].children[1].values[-1],
        map_maker: map_maker,
        user: User.where(email: "masek@masekadvokati.cz")
      )
    end
  end

  # !!! Antique e-shop "R" !!!
  # Opens the R website
  def map_scrapping_r(map_maker)
    r_page = @virtual_browser.get("#{ENV.fetch('BASE_URL_R')}#{map_maker}",
                                  { headers: { "User-Agent" => user_agent_picker } })
    r_html_document = Nokogiri::HTML(r_page.body)
    crawler_r(r_html_document, map_maker)
  end

  def crawler_r(r_html_document, map_maker)
    array_of_r_maps = []
    url_endpoints = r_html_document.css("ul.pager li a").map do |a_tag|
      a_tag.attr('href').slice(/&order_by=([^&]+)&relevance=([^&]+)&page=([^&]+)/)
    end
    url_endpoints.uniq.each do |url_enpoint|
      page = @virtual_browser.get("#{ENV.fetch('BASE_URL_R')}#{map_maker}#{url_enpoint}",
                                  { headers: { "User-Agent" => user_agent_picker } })
      array_of_r_maps += r_map_instance_builder(Nokogiri::HTML(page.body), map_maker)
    end
    array_of_r_maps
  end

  # Saves an instance of maps from "R" website
  def r_map_instance_builder(r_html_document, map_maker)
    r_html_document.css('.item.card').map do |map|
      Map.create(
        title: map.css('.info').children[1].css('.title').text.strip,
        price: map.css('aside').children[1].text.strip.tr(" ", ""),
        map_show_page_link: "#{ENV.fetch('BASE_URL_R_MAP_SHOW_PAGE')}#{map.css('.image').children[1]['href']}",
        image_url: map.css('.image').children[1].children[1]['src'],
        map_maker: map_maker,
        user: current_user
      )
    end
  end

  # !!! antique e-shop "L" !!!
  # Opens the "L" website
  def map_scrapping_l(map_maker)
    l_page = @virtual_browser.get("#{ENV.fetch('BASE_URL_L')}#{map_maker}",
                                  { headers: { "User-Agent" => user_agent_picker } })
    l_map_instance_builder(Nokogiri::HTML(l_page.body), map_maker)
  end

  # Saves an instance of maps from "L" website
  def l_map_instance_builder(html_document, map_maker)
    html_document.css('.product').map do |map|
      Map.create(
        title: map.css('.c309 a').attr('title').value,
        price: "KČ#{map.attr('data-price')}",
        map_show_page_link: "#{ENV.fetch('BASE_URL_L_MAP_SHOW_PAGE_AND_PIC')}#{map.css('.c309 a').attr('href').value}",
        image_url: "#{ENV.fetch('BASE_URL_L_MAP_SHOW_PAGE_AND_PIC')}#{map.css('.c309 a img').attr('src').value}",
        map_maker: map_maker,
        user: current_user
      )
    end
  end

  # This method picks a random user agent to use in the scraping methods
  def user_agent_picker
    user_agents = File.readlines("user_agents.txt", chomp: true)
    user_agents.sample
  end
end
