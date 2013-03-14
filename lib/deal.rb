require 'forecast_data'
require 'forecast_data_io'

module HighriseExtension
  Highrise::Deal.class_eval do
    ForecastData.attributes.each do |attr, options|
      delegate attr, :to => :forecast_data
    end

    def forecast_data
      @forecast_data ||= read_forecast_data
    end

    def update_forecast_data(data)
      data.each do |type, array|
        array.each do |key, value|
          value = case type
            when "int" then value.to_i
            when "date" then Date.parse(value)
          end
          forecast_data.send("#{key}=", value)
        end
      end
      write_forecast_data
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