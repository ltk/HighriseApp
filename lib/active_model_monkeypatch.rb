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