module HighriseExtension
  class ForecastData
    @@attributes = {
      :expected_start_date => { :type => "int", :default => lambda { |deal| deal.created_at + (60 * 60 * 24 * 75) } },
      :expected_end_date => { :type => "int", :default => lambda { |deal| deal.created_at + (60 * 60 * 24 * 365) } },
      :probability => { :type => "date", :default => lambda { |deal| 10 } },
      :average_rate => { :type => "int", :default => lambda { |deal| 200 } }
    }

    @@attributes.each { |attr, options| attr_accessor attr }

    def self.attributes
      @@attributes
    end

    def initialize(deal, args)
      @@attributes.each do |attr, options|
        value = args[attr] || options[:default].call(deal)
        instance_variable_set("@#{attr}", value)
      end
    end
  end
end