module Memcacheable
  class FetchWhere < Fetcher
    attr_accessor :klass, :criteria

    def initialize(klass, *args)
      self.klass = klass
      self.criteria = args.extract_options!
      raise "Only hash-style args accepted in fetch_where(). Illegal args: #{args.inspect}" if args.any?
      raise "No cache_index found in #{klass.name} matching fields #{criteria.keys.inspect}!" unless criteria.empty? or klass.cached_indexes.include? criteria.keys.map(&:to_sym).sort  
    end

    def cache_key
      {what: klass.name.tableize}.merge criteria
    end

    def description
      "#{klass.name.tableize} with #{criteria.inspect}"
    end

    def find_on_cache_miss
      klass.where(criteria).to_a
    end
  end
end
