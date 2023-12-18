class MapsController < ApplicationController
  def index
    return unless params[:query].present?

    map_maker = params[:query]
    @virtual_browser = Mechanize.new
    s_maps = map_scrapping_s(map_maker)
    r_maps = map_scrapping_r(map_maker)
    l_maps = map_scrapping_l(map_maker)
    @all_scrapped_maps = r_maps + s_maps + l_maps
  end

  private

  # !!! Antique e-shop "S" !!!
  # Makes opens the S website
  def map_scrapping_s(map_maker)
    array_of_maps = []
    s_page = @virtual_browser.get("#{ENV.fetch('BASE_URL_S')}#{URI.encode_www_form_component(map_maker)}",
                                  { headers: { "User-Agent" => user_agent_picker } })
    pages_urls = pagification_sanderus(Nokogiri::HTML(s_page.body))
    pages_urls.each do |page_url|
      maps_index_page_html = @virtual_browser.get(page_url,
                                                  { headers: { "User-Agent" => user_agent_picker } })
      array_of_maps += s_map_hash_builder(Nokogiri::HTML(maps_index_page_html.body))
    end
    array_of_maps
  end

  # Gets pages from the S website
  def pagification_sanderus(html_document)
    array_of_pages = []
    html_document.css("li a").each do |list_item|
      array_of_pages << list_item['href'] if list_item.text.match(/\d{1}/) && list_item.attr("class") != "cart"
    end
    array_of_pages.uniq
  end

  # Builds the hash for the map from S maps with the attributes of antique maps
  def s_map_hash_builder(html_document)
    html_document.css('.proditem').map do |map|
      {
        map_show_page_link: map['href'],
        map_image_url: map.css('.img').children[1].children[1].values[-1],
        map_title: map.css('.blue.breakup').text,
        map_price: map.css('.euro').text
      }
    end
  end

  # !!! Antique e-shop "R" !!!
  # Opens the R website
  def map_scrapping_r(map_maker)
    r_page = @virtual_browser.get("#{ENV.fetch('BASE_URL_R')}#{URI.encode_www_form_component(map_maker)}",
                                  { headers: { "User-Agent" => user_agent_picker } })
    r_map_hash_builder(Nokogiri::HTML(r_page.body))
  end

  #
  def r_map_hash_builder(html_document)
    html_document.css('.item.card').map do |map|
      {
        map_show_page_link: "#{ENV.fetch('BASE_URL_R_MAP_SHOW_PAGE')}#{map.css('.image').children[1]['href']}",
        map_image_url: map.css('.image').children[1].children[1]['src'],
        map_title: map.css('.info').children[1].css('.title').text.strip,
        map_price: map.css('aside').children[1].text.strip.tr(" ", "")
      }
    end
  end

  # !!! antique e-shop "L" !!!
  def map_scrapping_l(map_maker)
    l_page = @virtual_browser.get("#{ENV.fetch('BASE_URL_L')}#{URI.encode_www_form_component(map_maker)}",
                                  { headers: { "User-Agent" => user_agent_picker } })
    l_map_hash_builder(Nokogiri::HTML(l_page.body))
  end

  def l_map_hash_builder(html_document)
    html_document.css('.product').map do |map|
      {
        map_show_page_link: "#{ENV.fetch('BASE_URL_L_MAP_SHOW_PAGE_AND_PIC')}#{map.css('.c309 a').attr('href').value}",
        map_image_url: "#{ENV.fetch('BASE_URL_L_MAP_SHOW_PAGE_AND_PIC')}#{map.css('.c309 a img').attr('src').value}",
        map_title: map.css('.c309 a').attr('title').value,
        map_price: "KČ#{map.attr('data-price')}"
      }
    end
  end

  # This method picks a random user agent to use in the scraping methods
  def user_agent_picker
    user_agents = File.readlines("user_agents.txt", chomp: true)
    user_agents.sample
  end
end
