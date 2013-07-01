module Memcacheable
  class FetchBelongsTo < FetchAssociation
    def fetchable?
      klass.respond_to?(:fetch)
    end

    def find_on_cache_miss
      id = object.send "#{association}_id"
      fetchable? ? klass.fetch(id) : object.send(association) rescue nil
    end

    def klass
      @klass ||= association.to_s.camelize.constantize
    end
  end
end
