class ApplicationRecord < ActiveRecord::Base
  primary_abstract_class

  class << self
    def _set_composite_primary_key_values(primary_keys, values)
      primary_key_value = []
      primary_key.each do |col|
        value = values[col]

        if value&.value.nil? && prefetch_primary_key?
          value = ActiveModel::Attribute.from_database col, next_sequence_value, ActiveModel::Type::BigInteger.new
          values[col] = value
        end
        if value.is_a? ActiveModel::Attribute
          value = value.value
        end
        primary_key_value.append value
      end
      primary_key_value
    end
  end
end
