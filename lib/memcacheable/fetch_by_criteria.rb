module Memcacheable
  class FetchByCriteria < Fetcher
    attr_accessor :klass, :criteria

    def criteria_cacheable?
      klass.cached_indexes.include? criteria.keys.map(&:to_sym).sort
    end

    def initialize(klass, *args)
      self.klass = klass
      self.criteria = args.extract_options!
      raise "Only hash-style args accepted! Illegal args: #{args.inspect}" if args.any?
      raise "No cache_index found in #{klass.name} matching fields #{criteria.keys.inspect}!" unless criteria_cacheable? 
    end
  end
end
