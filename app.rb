require 'sinatra'
def comma_numbers(number, delimiter = ',')
  number.to_s.reverse.gsub(%r{([0-9]{3}(?=([0-9])))}, "\\1#{delimiter}").reverse
end
class HighriseApp < Sinatra::Base
  get "/" do
    secrets = YAML.load_file('config/secrets.yml')

    @highrise_url = secrets.fetch('highrise')['site']
    Highrise::Base.site = @highrise_url
    Highrise::Base.user = secrets.fetch('highrise')['api-token']
    Highrise::Base.format = secrets.fetch('highrise')['format']

    @deals = Highrise::Deal.find(:all)

    last_date = Date.today

    @deals.each do |deal|
      deal.date_range = parse_date(deal.background)
      if deal.date_range.last.to_time > last_date.to_time
        last_date = deal.date_range.last
      end 
      print "#{deal.inspect}\n"
      deal.loe = loe(deal.price, deal.date_range)
    end

    @visualization_array = visualize(@deals, Date.today, last_date)

    erb :index
  end

  def loe(budget, date_range)
    days = date_range.last - date_range.first
    budget.to_f/days
  end

  def parse_date(deal_text)
    deal_text =~ /\[([\d\/]*)\s?to\s?([\d\/]*)\]/
    start_date_string = $1
    end_date_string = $2

    # use Date.strptime instead
    start_date_string =~ /([\d]{1,2})\/((?:[\d]{4}|[\d]{2}))/
    if $2.length == 2
      start_year_string = "20#{$2}"
    else
      start_year_string = $2
    end
    start_date = Date.parse("01/#{$1}/#{start_year_string}")

    # end
    end_date_string =~ /([\d]{1,2})\/((?:[\d]{4}|[\d]{2}))/
    if $2.length == 2
      end_year_string = "20#{$2}"
    else
      end_year_string = $2
    end
    end_date = Date.parse("01/#{$1}/#{end_year_string}")


    (start_date..end_date)
  end

  def visualize(deals, start_date, end_date)
    months = []
    date = start_date
    laterdate = end_date
    (date.year..laterdate.year).each do |y|
       mo_start = (date.year == y) ? date.month : 1
       mo_end = (laterdate.year == y) ? laterdate.month : 12

       (mo_start..mo_end).each do |m|  
           months << "#{m}/#{y}"
       end
    end

    array = []

    header_array = ["Month"]
    deals.each do |deal|
      header_array.push deal.name
    end

    array.push(header_array)

    months.each do |date|
      date_date = Date.parse(date)
      row = [date]
      deals.each do |deal|
        if deal.date_range.include?(date_date)
          row.push(deal.loe)
        else
          row.push(0)
        end
      end
      array.push(row)
    end

    array
  end
end
