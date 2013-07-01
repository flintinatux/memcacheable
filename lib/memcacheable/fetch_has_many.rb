module Memcacheable
  class FetchHasMany < FetchAssociation
    def fetchable?
      klass.respond_to?(:fetch_where) && klass.cached_indexes.include?(["#{class_name}_id".to_sym])
    end

    def find_on_cache_miss
      criteria = { "#{class_name}_id" => object.id }
      fetchable? ? klass.fetch_where(criteria) : object.send(association).to_a
    end

    def klass
      @klass ||= association.to_s.classify.constantize
    end
  end
end
