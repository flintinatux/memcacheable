module Memcacheable
  class Fetcher
    def debug(action)
      Rails.logger.debug "[memcacheable] #{action} #{description}"
    end

    def fetch
      debug :read
      Rails.cache.fetch cache_key do
        debug :write
        find_on_cache_miss
      end
    end

    def flush
      debug :flush
      Rails.cache.delete cache_key
    end
  end
end
