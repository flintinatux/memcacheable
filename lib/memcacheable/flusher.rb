module Memcacheable
  class Flusher
    attr_accessor :object

    OLD_VAL = 0
    NEW_VAL = 1

    def initialize(object)
      self.object = object
    end

    def changed_criteria_for(which, fields)
      fields.inject({}) do |hash, field|
        value = object.previous_changes[field][which] rescue object.send(field)
        hash.merge! field => value
      end
    end

    def flush
      FetchOne.new(object.class, object.id).flush
      object.cached_indexes.each do |fields|
        [OLD_VAL,NEW_VAL].each do |which|
          criteria = changed_criteria_for which, fields
          FetchBy.new(object.class, criteria).flush
          FetchWhere.new(object.class, criteria).flush
        end
      end
    end
  end
end
