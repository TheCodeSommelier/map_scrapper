# TODO: Add pagification crawler to all of the sites

class MapsController < ApplicationController
  def index
    return unless params[:query].present?

    @virtual_browser = Mechanize.new
    @map_columns = %i[title price map_show_page_link image_url map_maker]
    @user_agent = user_agent_picker
    if Author.where(name: params[:query]).empty?
      Author.create(name: params[:query])
      map_scrapping_s(params[:query])
      map_scrapping_r(params[:query])
      map_scrapping_l(params[:query])
    end
    @all_scrapped_maps = Map.where(map_maker: params[:query]).order(created_at: :desc).page(params[:page])
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
        map_maker: map_maker
      )
    end
  end

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
        map_maker: map_maker
      )
    end
  end

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
