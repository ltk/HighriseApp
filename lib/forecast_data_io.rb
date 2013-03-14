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
end