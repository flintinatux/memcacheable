module Memcacheable
  class FetchBelongsTo < FetchAssociation

    def find_on_cache_miss
      klass = association.to_s.camelize.constantize
      id = object.send "#{association}_id"
      klass.respond_to?(:fetch) ? klass.fetch(id) : klass.find(id) rescue nil
    end
    
  end
end
