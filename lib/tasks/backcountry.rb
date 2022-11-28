require 'nokogiri'
require 'open-uri'
require 'csv'
require 'uri'

class Backcountry
  def initialize(
    bc_product_code,
    store,
    brand,
    name,
    price,
    sale_price,
    best_use,
    profile,
    dimensions,
    turn_radius,
    tail_profile,
    model_year,
    warranty,
    size_one,
    size_two,
    size_three,
    size_four,
    size_five,
    size_six,
    product_url,
    gender,
    image,
    description)

    @bc_product_code = bc_product_code
    @store = store
    @brand = brand
    @name = name
    @price = price
    @sale_price = sale_price
    @best_use = best_use
    @profile = profile
    @dimensions = dimensions
    @turn_radius = turn_radius
    @tail_profile = tail_profile
    @model_year = model_year
    @warranty = warranty
    @size_one = size_one
    @size_two = size_two
    @size_three = size_three
    @size_four = size_four
    @size_five = size_five
    @size_six = size_six
    @product_url = product_url
    @gender = gender
    @image = image
    @description = description
  end

  attr_reader :bc_product_code
  attr_reader :store
  attr_reader :brand
  attr_reader :name
  attr_reader :price
  attr_reader :sale_price
  attr_reader :best_use
  attr_reader :primary_use
  attr_reader :secondary_use
  attr_reader :third_use
  attr_reader :profile
  attr_reader :dimensions
  attr_reader :turn_radius
  attr_reader :tail_profile
  attr_reader :model_year
  attr_reader :warranty
  attr_reader :size_one
  attr_reader :size_two
  attr_reader :size_three
  attr_reader :size_four
  attr_reader :size_five
  attr_reader :size_six
  attr_reader :product_url
  attr_reader :gender
  attr_reader :image
  attr_reader :description

  ############################### DATA SCRAPE ####################################
  def self.scrape
    puts('*** Scraping data from Backcountry.com ***')

    test_url = ["https://www.backcountry.com/alpine-skis?p=brand%3ANordica&nf=1"]
    
    source_urls = test_url

    # source_urls = ["https://www.backcountry.com/alpine-skis?p=gender%3Amale&nf=1",
    #               "https://www.backcountry.com/alpine-touring-skis?p=gender%3Amale&nf=1",
    #               "https://www.backcountry.com/alpine-skis?p=gender%3Aunisex&nf=1",
    #               "https://www.backcountry.com/alpine-touring-skis?p=gender%3Aunisex&nf=1",
    #               "https://www.backcountry.com/alpine-skis?p=gender%3Afemale&nf=1",
    #               "https://www.backcountry.com/alpine-touring-skis?p=gender%3Afemale&nf=1"]

   
    pause_in_secs = 10

    @backcountry_skis = []
    source_urls.each do |url|
      doc = Nokogiri::HTML(URI.open(url))
      gender =
        if url.match(/gender%3Amale/)
          'mens'
        elsif url.match(/gender%3Afemale/)
          'womens'
        elsif url.match(/gender%3Aunisex/)
          'unisex'
        else
          ''
        end

      leading_url = "https://www.backcountry.com"

      byebug
    
      page_urls = doc.search("div[data-id='productListingItems']", "css-fmt7bd", "div//a//@href").map do |page_link|
        href = page_link.value
        page_url = leading_url + href
      end
      page_urls.unshift(url)
      byebug
      page_urls.each do |page_url|
        doc = Nokogiri::HTML(URI.open(page_url))
        byebug
        doc.css(".product a").each do |ski|
          href = ski.attr('href')
          product_url = leading_url + href

          begin
            sleep pause_in_secs
            product_html = Nokogiri::HTML(URI.open(product_url))
          rescue OpenURI::HTTPError => e
            if e.message == '404 Not Found'
              # "" # handle 404 error
              puts "404 #{product_url}"
              next
            else
              raise e
            end
          end

          product_url = product_url.gsub("//","%2F%2F")
          product_url = product_url.gsub(/https:/,"http://www.avantlink.com/click.php?tt=cl&merchant_id=b5770911-39dc-46ac-ba0f-b49dbb30c5c7&website_id=de60b61b-34ab-4a40-80b1-33015d6a3491&url=https%3A")

          bc_product_code = (product_html.at_css(".product-details-accordion .product-details-accordion__item-number").text)
          bc_product_code = bc_product_code.gsub(/Item / ,"") if bc_product_code.present?

          store = 'backcountry.com'

          ##Checks to see if product_url is valid
          is_available = href[0,1] == "/"
          puts "Product url unavailable #{product_url}" unless is_available
          if is_available
            brand_full = product_html.at_css(".qa-brand-name").text
            brand = brand_full.gsub(/Skis/ ,"") if brand_full.present?
            brand = brand.gsub(/USA/ ,"") if brand.present?
            brand = brand.gsub(/technologies/ ,"tech") if brand.present?
            brand = brand.downcase.strip

            name = (product_html.at_css(".product-name").text)
            name = name.gsub(/- Women's/ ,"") if name.present?
            name = name.gsub(/- Men's/ ,"") if name.present?
            name = name.gsub(brand_full ,"") if name.present?
            name = name.downcase.strip
            name = name.gsub("  ", " ") if name.present?

            price = product_html.at_css(".product-pricing__retail")
            price =
              if price.present?
                price.text.squish
              else
                product_html.at_css(".product-pricing__inactive")
              end

            sale_price = product_html.at_css(".product-pricing__sale")
            sale_price = sale_price.text.squish if sale_price.present?

            best_use = product_html.at_xpath('//div[text()="Recommended Use"]/following-sibling::div')
            best_use = best_use.text.squish if best_use.present?

            if best_use
              primary_use =
                if best_use.count(',') > 0
                  primary_use = best_use.split(",").to_a[0]
                else
                  best_use
                end
              secondary_use = best_use.split(",").to_a[1]
              third_use = best_use.split(",").to_a[2]
            else
              ""
            end

            profile = product_html.at_xpath('//div[text()="Profile"]/following-sibling::div')
            profile = profile.text.squish if profile.present?

            dimensions = product_html.at_xpath('//div[text()="Dimensions"]/following-sibling::div')
            dimensions = dimensions.text.squish if dimensions.present?

            if dimensions.present?
              if dimensions.count('/') > 0
                dimensions_array = dimensions.split(",").to_a[0].gsub(/\[.*\]/, "").gsub(/\s+/, "").split("/").to_a
              elsif dimensions.count('-') > 0
                dimensions_array = dimensions.gsub(/-/ ,"/").gsub(/\s+/, "").split("/").to_a
              else
                dimensions_array = dimensions.gsub(/,/ ,"/").gsub(/\s+/, "").split("/").to_a
              end
            end


            turn_radius = product_html.at_xpath('//div[text()="Turn Radius"]/following-sibling::div')
            turn_radius = turn_radius.text.squish if turn_radius.present?

            tail_profile = product_html.at_xpath('//div[text()="Tail"]/following-sibling::div')
            tail_profile = tail_profile.text.squish if tail_profile.present?


            model_year = product_html.at_xpath('//th[contains(., "Model Year")]/following-sibling::td')
            model_year = model_year.text.squish if model_year.present?


            warranty = product_html.at_xpath('//th[contains(., "Warranty")]/following-sibling::td')
            warranty = warranty.text.squish if warranty.present?

            size_one =
              if product_html.at_css(".qa-size-item-0").present?
                 product_html.at_css(".qa-size-item-0")
              else
                product_html.at_css(".qa-variant-item-0 .buybox-dropdown__option-section .buybox-dropdown__option-value")
              end
            size_one = size_one.text.squish if size_one.present?
            size_one = size_one.split(',', 2).last.gsub(/\s+/, "").delete('cm') if size_one.present?

            size_two =
              if product_html.at_css(".qa-size-item-1").present?
                 product_html.at_css(".qa-size-item-1")
              else
                product_html.at_css(".qa-variant-item-1 .buybox-dropdown__option-section .buybox-dropdown__option-value")
              end
            size_two = size_two.text.squish if size_two.present?
            size_two = size_two.split(',', 2).last.gsub(/\s+/, "").delete('cm') if size_two.present?

            size_three =
              if product_html.at_css(".qa-size-item-2").present?
                 product_html.at_css(".qa-size-item-2")
              else
                product_html.at_css(".qa-variant-item-2 .buybox-dropdown__option-section .buybox-dropdown__option-value")
              end
            size_three = size_three.text.squish if size_three.present?
            size_three = size_three.split(',', 2).last.gsub(/\s+/, "").delete('cm') if size_three.present?

            size_four =
              if product_html.at_css(".qa-size-item-3").present?
                 product_html.at_css(".qa-size-item-3")
              else
                product_html.at_css(".qa-variant-item-3 .buybox-dropdown__option-section .buybox-dropdown__option-value")
              end
            size_four = size_four.text.squish if size_four.present?
            size_four = size_four.split(',', 2).last.gsub(/\s+/, "").delete('cm') if size_four.present?

            size_five =
              if product_html.at_css(".qa-size-item-4").present?
                 product_html.at_css(".qa-size-item-4")
              else
                product_html.at_css(".qa-variant-item-4 .buybox-dropdown__option-section .buybox-dropdown__option-value")
              end
            size_five = size_five.text.squish if size_five.present?
            size_five = size_five.split(',', 2).last.gsub(/\s+/, "").delete('cm') if size_five.present?

            size_six =
              if product_html.at_css(".qa-size-item-5").present?
                 product_html.at_css(".qa-size-item-5")
              else
                product_html.at_css(".qa-variant-item-5 .buybox-dropdown__option-section .buybox-dropdown__option-value")
              end
            size_six = size_six.text.squish if size_six.present?
            size_six = size_six.split(',', 2).last.gsub(/\s+/, "").delete('cm')  if size_six.present?

            image_path = product_html.at_xpath('//div[contains(@class, "ui-flexzoom js-flexzoom")]/img/@data-src')
            image = "https:" + image_path

            description = product_html.at_css(".js-product-info .p")
            description = description.text.squish if description.present?

            @backcountry_skis << Backcountry.new(
              bc_product_code,
              store,
              brand,
              name,
              price,
              sale_price,
              best_use,
              profile,
              dimensions,
              turn_radius,
              tail_profile,
              model_year,
              warranty,
              size_one,
              size_two,
              size_three,
              size_four,
              size_five,
              size_six,
              product_url,
              gender,
              image,
              description)
            print('.')
          end
        end
      end
    end

    CSV.open("backcountry_scrape.csv", 'w') do |csv|
      csv << ['bc_product_code',
              'store',
              'brand',
              'name',
              'price',
              'sale_price',
              'best_use',
              'profile',
              'dimensions',
              'turn_radius',
              'tail_profile',
              'model_year',
              'warranty',
              'size_one',
              'size_two',
              'size_three',
              'size_four',
              'size_five',
              'size_six',
              'product_url',
              'gender',
              'image',
              'description']  #column head of csv file

      csv = @backcountry_skis.each do |backcountry_ski|
        csv << [backcountry_ski.bc_product_code,
                backcountry_ski.store,
                backcountry_ski.brand,
                backcountry_ski.name,
                backcountry_ski.price,
                backcountry_ski.sale_price,
                backcountry_ski.best_use,
                backcountry_ski.profile,
                backcountry_ski.dimensions,
                backcountry_ski.turn_radius,
                backcountry_ski.tail_profile,
                backcountry_ski.model_year,
                backcountry_ski.warranty,
                backcountry_ski.size_one,
                backcountry_ski.size_two,
                backcountry_ski.size_three,
                backcountry_ski.size_four,
                backcountry_ski.size_five,
                backcountry_ski.size_six,
                backcountry_ski.product_url,
                backcountry_ski.gender,
                backcountry_ski.image,
                backcountry_ski.description] #fields name
      end
    end

    puts('Finished Creating Backcountry.com Ski List')
    if Rails.env.production?
      MessageMailer.backcountry_scrape(self).deliver_now
    end
  end


  ############################### DATA IMPORT ####################################
  def self.import

    retailer = Retailer.find_by!(name: "Backcountry")
    retailer.stock_items.delete_all

    CSV.foreach("backcountry_scrape.csv", headers: true) do |row|
      cents = row['price'].gsub(/\$|\,/, '').to_d * 100
      sale_price_cents = if row['sale_price']
        row['sale_price'].gsub(/\$|\,/, '').to_d * 100
      end


      ski = Ski.find_or_initialize_by(bc_product_code: row['bc_product_code'])

      if ski.new_record?
        new_ski = Ski.create!(
          brand: row['brand'],
          name: row['name'],
          gender: row['gender'],
          bc_product_code: row['bc_product_code'],
          bc_best_use: row['best_use'],
          bc_profile: row['profile'],
          bc_dimensions: row['dimensions'],
          bc_turn_radius: row['turn_radius'],
          bc_tail_profile: row['tail_profile'],
          bc_warranty: row['warranty'],
          bc_gender: row['gender'],
          bc_image_link: row['image'],
          new_ski: true,
          active: false)

        ['one', 'two', 'three', 'four', 'five', 'six'].each do |index|
          size = row["size_#{index}"]
          if size.present?
            new_ski_length = SkiLength.find_or_create_by!(value: size)
            new_variant = Variant.create!(ski: new_ski, ski_length: new_ski_length)
            StockItem.create!(variant: new_variant, retailer: retailer, sale_price: sale_price_cents, price: cents, product_url: row['product_url'], store: row['store'])
            p "New ski"
          end
        end
        new_ski.product_image = new_ski.bc_image_link
        new_ski.save!
      end

      [row['size_one'], row['size_two'], row['size_three'], row['size_four'], row['size_five'], row['size_six']].compact.each do |size|
        ski_length = SkiLength.find_by(value: size)
        variant = Variant.find_by(ski: ski, ski_length: ski_length)

        if variant.present?
          ski.update(
            bc_best_use: row['best_use'],
            bc_profile: row['profile'],
            bc_dimensions: row['dimensions'],
            bc_turn_radius: row['turn_radius'],
            bc_tail_profile: row['tail_profile'],
            bc_warranty: row['warranty'],
            bc_gender: row['gender'],
            bc_image_link: row['image'])
          StockItem.create!(variant: variant, retailer: retailer, sale_price: sale_price_cents, price: cents, product_url: row['product_url'], store: row['store'])
          print('.')
        end
        if !variant.present? && !new_ski.present?
          ski.update(
            bc_best_use: row['best_use'],
            bc_profile: row['profile'],
            bc_dimensions: row['dimensions'],
            bc_turn_radius: row['turn_radius'],
            bc_tail_profile: row['tail_profile'],
            bc_warranty: row['warranty'],
            bc_gender: row['gender'],
            bc_image_link: row['image'])
          add_ski_length = SkiLength.find_or_create_by!(value: size)
          add_variant = Variant.create!(ski: ski, ski_length: add_ski_length)
          StockItem.create!(variant: add_variant, retailer: retailer, sale_price: sale_price_cents, price: cents, product_url: row['product_url'], store: row['store'])
          p "Create stock item"
        end
      end
    end
    puts('Backcountry data import complete')
    if Rails.env.production?
      MessageMailer.backcountry_data_import(self).deliver_now
    end
  end


  ############################### DATAFEED ####################################
  def self.datafeed
    url =  "https://datafeed.avantlink.com/download_feed.php?id=259809&auth=8d5dea9017bfdb33c6cee2cb9df4ab3b"

    download = open(url, ssl_verify_mode: OpenSSL::SSL::VERIFY_PEER)
    FileUtils.rm_f 'backcountry_datafeed.csv'
    IO.copy_stream(download, 'backcountry_datafeed.csv')

    retailer = Retailer.find_by(name: 'Backcountry')

    CSV.foreach('backcountry_datafeed.csv', headers: true) do |row|

      ski = Ski.find_by(:bc_product_code => "##{row['SKU']}")
      if ski.present?
        ski.stock_items.where(retailer_id: retailer.id).update_all(product_url: row['Buy Link'])
        ski.update(bc_description: row['Long Description'])
        print('.')
      end
    end

    puts('Backcountry datafeed complete')
    if Rails.env.production?
      MessageMailer.backcountry_datafeed(self).deliver_now
    end
  end

end