class FakeModel
  include ActiveModel::Dirty
  extend  ActiveModel::Callbacks

  define_model_callbacks :commit

  def self.define_attribute(*attrs)
    attrs.each do |attr_name|
      define_attribute_method attr_name
      attr_reader attr_name
      define_method "#{attr_name}=" do |value|
        send "#{attr_name}_will_change!" unless value == send(attr_name)
        instance_variable_set "@#{attr_name}", value
      end
    end
  end

  define_attribute :id, :updated_at

  def initialize(new_attributes={})
    assign_attributes new_attributes
    self.updated_at = 0
    save # to clear all "changes"
  end

  def cache_key
    "#{self.class.name.tableize}/#{id}-#{updated_at.to_i}"
  end

  def commit
    run_callbacks :commit
  end

  def save
    if changes.any?
      @previously_changed = changes
      @changed_attributes.clear
      commit
      return true
    end
    false
  end

  def touch
    self.updated_at += 1
  end

  def update_attributes(new_attributes={})
    assign_attributes new_attributes
    save 
  end

  private

    def assign_attributes(new_attributes={})
      new_attributes.each do |field, value|
        send "#{field}=", value
      end
    end
end
