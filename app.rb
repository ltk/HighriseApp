require 'sinatra'

module WrapperExtension  
  Highrise::Deal.class_eval do
    def date_range
      @date_range ||= parse_date_range(background)
    end

    def loe
      @loe ||= price.to_f/(date_range.last - date_range.first)
    end

    def likelihood
      @likelihood ||= parse_likelihood(background)
    end

    private

    def parse_likelihood(text)
      text =~ /\[([\d]{1,3})%\]/
      $1
    end

    def parse_date_range(text)
      text =~ /\[([\d\/]*)\s?to\s?([\d\/]*)\]/
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
  end
end

class Visualization
  def initialize(data, params)
    @data = data
    @start_date = params[:start_date] || Date.today
    @end_date = params[:end_date] || Date.today + 365
  end

  def data_array
    months = []
    (@start_date.year..@end_date.year).each do |y|
       mo_start = (@start_date.year == y) ? @start_date.month : 1
       mo_end = (@end_date.year == y) ? @end_date.month : 12

       (mo_start..mo_end).each do |m|  
           months << "#{m}/#{y}"
       end
    end

    array = []

    header_array = ["Month"]
    @data.each do |datum|
      header_array.push datum.name
    end

    array.push(header_array)

    months.each do |date|
      date_date = Date.parse(date)
      row = [date]
      @data.each do |datum|
        if datum.date_range.include?(date_date)
          row.push(datum.loe)
        else
          row.push(0)
        end
      end
      array.push(row)
    end

    array
  end
end

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

    # Get last projected end date
    last_date = Date.today
    @deals.each do |deal|
      if deal.date_range.last.to_time > last_date.to_time
        last_date = deal.date_range.last
      end 
    end

    # Make the data array for the google chart
    @viz = Visualization.new(@deals, :start_date => Date.today, :end_date => last_date)

    erb :index
  end
end
