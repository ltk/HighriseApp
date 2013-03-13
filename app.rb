require 'sinatra'
require 'pry'
require 'logger'

ActiveResource::Base.logger = Logger.new(STDOUT)

module ActiveModel
  module Serializers
    module Xml

      class Serializer
        class Attribute

        protected

          def compute_type
            return if value.nil?
            type = ActiveSupport::XmlMini::TYPE_NAMES[value.class.name]
            type ||= :string if value.respond_to?(:to_str)
            type ||= :yaml
            type
          end

        end
      end

    end
  end
end

module WrapperExtension

  Highrise::Deal.class_eval do
   
    FORECAST_DATA_START = "##Highrise Forecast Data##"
    FORECAST_DATA_END = "#####################"
    START_DATE_TEMPLATE = "Expected Start Date: "
    CLOSE_DATE_TEMPLATE = "Expected Close Date: "
    PROBABILITY_TEMPLATE = "Probability: "

    def forecast_data?
      !forecast_data.nil?
    end

    def write_forecast_data
      strip_forecast_string
      self.background = background + forecast_data_string
    end

    def start_date=(int)
      @start_date = int
    end

    def start_date
      if @start_date
        @start_date
      else
        forecast_data =~ /^#{START_DATE_TEMPLATE}(.+)$/
        $1 || created_at + (60 * 60 * 24 * 75)
      end
    end

    def close_date=(int)
      @close_date = int
    end

    def close_date
      if @close_date
        @close_date
      else
        forecast_data =~ /^#{CLOSE_DATE_TEMPLATE}(.+)$/
        $1 || created_at + (60 * 60 * 24 * 75)
      end
    end

    def probability=(int)
      @probability = int
    end

    def probability
      if @probability
        @probability
      else
        forecast_data =~ /^#{PROBABILITY_TEMPLATE}(.+)$/
        $1 || 10
      end
    end

    private

    def strip_forecast_string
      background.gsub!(/##Highrise Forecast Data##(.*)#####################/m, "")
    end

    def forecast_data
      @forecast_data || parse_forecast_data(background)
    end

    def forecast_data_string
      %Q(\n\n#{FORECAST_DATA_START}\n#{START_DATE_TEMPLATE}#{start_date}\n#{CLOSE_DATE_TEMPLATE}#{close_date}\n#{PROBABILITY_TEMPLATE}#{probability}\n#{FORECAST_DATA_END})
    end

    def parse_forecast_data(text)
      text =~ /##Highrise Forecast Data##(.*)#####################/m
      $1
    end

    def reject_party
      self.attributes.reject!{|k,v| k == "party"}
    end

    
  end
end

def comma_numbers(number, delimiter = ',')
  number.to_s.reverse.gsub(%r{([0-9]{3}(?=([0-9])))}, "\\1#{delimiter}").reverse
end

class HighriseApp < Sinatra::Base
  def boot_highrise
    secrets = YAML.load_file('config/secrets.yml')

    @highrise_url = secrets.fetch('highrise')['site']
    Highrise::Base.site = @highrise_url
    Highrise::Base.user = secrets.fetch('highrise')['api-token']
    # Highrise::Base.format = secrets.fetch('highrise')['format']
  end

  get "/deal/:deal_id/edit" do
    boot_highrise

    @deal = Highrise::Deal.find(params[:deal_id])
    erb :edit
  end

  post "/deal/:deal_id" do
    boot_highrise

    deal = Highrise::Deal.find(params[:deal_id])
    if request.POST.has_key?("probability")
      deal.probability = request.POST["probability"]
    end

    if request.POST.has_key?("start_date")
      deal.start_date = Date.parse(request.POST["start_date"])
    end

    if request.POST.has_key?("close_date")
      deal.close_date = Date.parse(request.POST["close_date"])
    end

    deal.write_forecast_data

    deal.attributes.reject!{|k,v| k == "party"}
    deal.save

    redirect to("/")
  end

  get "/" do
    boot_highrise

    @deals = Highrise::Deal.find(:all)

   
    @deals.each do |deal|
      
      deal.attributes.reject!{|k,v| k == "party"}
    
      unless deal.forecast_data?
        deal.write_forecast_data
        deal.save
      end
      print "\n#{deal.start_date}\n"
      
    end

    erb :index
  end
end
