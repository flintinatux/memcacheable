# Memcacheable [![Build Status](https://travis-ci.org/flintinatux/memcacheable.png)](https://travis-ci.org/flintinatux/memcacheable) [![Dependency Status](https://gemnasium.com/flintinatux/memcacheable.png)](https://gemnasium.com/flintinatux/memcacheable) [![Code Climate](https://codeclimate.com/github/flintinatux/memcacheable.png)](https://codeclimate.com/github/flintinatux/memcacheable)

A Rails concern to make caching ActiveRecord objects as dead-simple as possible. Uses the built-in Rails.cache mechanism, and implements the new finder methods available in Rails 4.0 to ensure maximum future compatibility.

## Installation

Add this line to your application's Gemfile:

    gem 'memcacheable'

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install memcacheable

## Usage

Let's do some caching!

```ruby
class Person < ActiveRecord::Base
  include Memcacheable
end
```

Boom!  Now you can `fetch` a person by their id, like below.  When the person gets updated or touched, it will flush the cache, and the person will be reloaded on the next `fetch`.

```ruby
person = Person.fetch id  # caches the person
person.touch              # flushes the cache
person = Person.fetch id  # the cache misses, and the person is reloaded
```

### Cache by criteria

That's easy-sauce.  Time to step up our caching game!  _"I want to cache queries by criteria, not just id's!"_  No probs:

```ruby
class Person < ActiveRecord::Base
  include Memcacheable
  cache_index :name
  cache_index :height, :weight
end
```

**Mathematical!**  `cache_index` adds these index combinations to the list of cacheable things, so we can fetch single records with `fetch_by`, like this:

```ruby
person = Person.fetch_by name: 'Scott'    # caches an awesome dude
person.update_attributes name: 'Scottie'  # flushes the cache
person = Person.fetch_by name: 'Scott'    # => nil (he's got a new identity!)

# You can also do multiple criteria, and order doesn't matter.
person = Person.fetch_by weight: 175, height: 72
person.update_attributes height: 71               # he shrunk? oh well, cache flushed
person = Person.fetch_by weight: 175, height: 71  # fetched and cached with new height
```

Like noise in your life?  Try `fetch_by!` (hard to say: "fetch-by-bang!").

```ruby
person = Person.fetch_by! name: 'Mork'  # => ActiveRecord::RecordNotFound
```

While `fetch_by` just pulls back just one record, you can fetch a collection with `fetch_where`:

```ruby
people = Person.fetch_where weight: 42, height: 120  # => an array of tall, skinny people
people.first.update_attributes weight: 43            # one guy gained a little weight --> cache flushed
people = Person.fetch_where weight: 42, height: 120  # => an array of everyone but that first guy
```

Trying to `fetch_by` or `fetch_where` by criteria that you didn't specify with `cache_index` will raise an error, because Memcacheable won't know how to bust the cache when things get changed.  For example:

```ruby
Person.fetch_by name: 'Scott'           # good
Person.fetch_by favorite_color: 'red'   # shame on you! this wasn't cache_index'd!
```

**Caveat:** hash-style criteria is currently **required** for `fetch_by` and `fetch_where`.  Something like `person.fetch_where 'height < ?', 71` will raise an error.

Btw, don't do something stupid like trying to call scope methods on the result of a `fetch_where`.  It returns an `Array`, not an `ActiveRecord::Relation`.  That means this will blow up on you:

```ruby
Person.fetch_where(height: 60).limit(5)
```

If you want something very similar to scopes, keep reading to learn about [caching methods](https://github.com/flintinatux/memcacheable#cache-methods).

### Cache associations

If you love Rails, then you know you love ActiveRecord associations.  Memcacheable loves them too.  Check this out:

```ruby
class Person < ActiveRecord::Base
  has_one  :dog
  has_many :kittens
  
  include Memcacheable
  cache_has_one  :dog
  cache_has_many :kittens
end

class Dog < ActiveRecord::Base
  belongs_to :person, touch: true
  
  include Memcacheable
  cache_belongs_to :person
end

class Kitten < ActiveRecord::Base
  belongs_to :person, touch: true
  
  include Memcacheable
  cache_index :person_id
end
```

**Notice** the `touch: true` above.  That's important to bust the parent cache when a child record is updated!

So what do we get with all of this caching magic?  Why a bunch of dynamic association fetch methods of course! Observe:

```ruby
dog = person.fetch_dog              # his name's Bruiser, btw
dog.update_attributes name: 'Fido'  # flushes the cached association on the person
dog = person.fetch_dog              # finds and caches Fido with his new name
dog.fetch_person                    # gets the cached owner
```

For a slight optimization, specify a `cache_index` on the foreign key of the association, like in the `Kitten` example above.  Memcacheable will then do a `fetch_by` or `fetch_where` as appropriate.  **The cost:** two copies in the cache.  **The gain:** when the parent changes but the children don't, the children can be _reloaded from the cache._  Like this:

```ruby
person.fetch_kittens  # caches the kittens both by criteria and as an association
person.touch          # association cache is flushed, but not the fetch_where
person.fetch_kittens  # reloads the kittens from the cache, and caches as an association
```

### Cache methods

Does your model have a method that eats up lots of calculation time, or perhaps a scope-like method that requires a database query?  Cache that bad boy!

```ruby
class Person < ActiveRecord::Base
  has_many :kittens
  
  include Memcacheable
  cache_method :random_kitten
  
  def random_kitten(seed=Random.new_seed)
    kittens.sample(Random.new seed)
  end
end
```

**Voila!** Now you get a nice fetch method to cache the results:

```ruby
person.fetch_random_kitten(12345)   # => gets your random kitty, and then caches it
```

Notice that the fetch method accepts the same args as the original.  **Caveat:** blocks are not accepted, unfortunately.  I love blocks, but they don't have a consistent identifier to include in a cache key.  So feel free to get creative with args, but not blocks.

## Inspiration

None of the caching options out there really satisfied my needs, so I wrote this gem.  But I was not without inspiration.  I learned the basics of Rails caching from the [RailsCasts](http://railscasts.com/) episode on [Model Caching](http://railscasts.com/episodes/115-model-caching-revised), and I borrowed a lot of syntax from the very popular [IdentityCache gem](https://github.com/Shopify/identity_cache) from our friends at [Shopify](http://www.shopify.com/).

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request
