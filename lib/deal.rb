require 'yaml'

module HighriseExtension
  class ForecastDataIO
    FORECAST_DATA_START = "##Highrise Forecast Data##"
    FORECAST_DATA_END = "#####################"

    def self.read(text)
      if forecast_data_string(text)
        YAML::load(forecast_data_string(text)) || {}
      else
        {}
      end
    end

    def self.write(obj, data, save_to)
      text = obj.send(save_to)
      data = obj.send(data)
      obj.send("#{save_to}=", strip_forecast_data_string(text) + updated_forecast_data_string(data) )
    end

    private

    def self.forecast_data_string(text)
      text =~ /#{FORECAST_DATA_START}(.*)#{FORECAST_DATA_END}/m
      $1
    end

    def self.strip_forecast_data_string(text)
      text.gsub(/#{FORECAST_DATA_START}(.*)#{FORECAST_DATA_END}/m, "")
    end

    def self.yamlize(data)
      data.to_yaml
    end

    def self.updated_forecast_data_string(data)
      %Q(\n\n#{FORECAST_DATA_START}\n#{yamlize(data)}#{FORECAST_DATA_END})
    end
  end

  class ForecastData
    FORECAST_DATA_FIELDS = [:expected_start_date, :expected_close_date, :probability]
    attr_accessor :expected_start_date, :expected_close_date, :probability

    def initialize(deal, args)
      @expected_start_date = args[:expected_start_date] || defaults(deal)[:expected_start_date]
      @expected_close_date = args[:expected_close_date] || defaults(deal)[:expected_close_date]
      @probability = args[:probability] || defaults(deal)[:probability]
    end

    private

    def defaults(deal)
      {
        :expected_start_date => deal.created_at + (60 * 60 * 24 * 75),
        :expected_close_date => deal.created_at + (60 * 60 * 24 * 90),
        :probability => 10
      }
    end
  end


  Highrise::Deal.class_eval do
    delegate :expected_start_date, :expected_close_date, :probability, :to => :forecast_data

    def forecast_data
      @forecast_data ||= read_forecast_data
    end

    def write_forecast_data
      # How can I get this into a callback on save? before_save isn't working even after including ActiveResource::Callbacks.
      self.background = ForecastDataIO.write(self, :forecast_data, :background)
    end

    private

    def read_forecast_data
      data = ForecastDataIO.read(background)
      data.is_a?(ForecastData) ? data : ForecastData.new(self, data)
    end
  end
end