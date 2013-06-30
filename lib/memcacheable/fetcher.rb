module Memcacheable
  class Fetcher
    def debug(action)
      Rails.logger.debug "[memcacheable] #{action} #{description}"
    end

    def fetch
      debug :read
      Rails.cache.fetch cache_key do
        find_on_cache_miss.tap { debug :write }
      end
    end

    def flush
      Rails.cache.delete cache_key
    end
  end
end
