require 'spec_helper'

class Person < FakeModel
  define_attribute :color, :number, :dog_id

  include Memcacheable
  cache_index :number
  cache_index :color, :number
  cache_has_one  :dog
  cache_has_many :kittens
end

class Dog < FakeModel
  define_attribute :person_id
  include Memcacheable
end

class Kitten < FakeModel
  define_attribute :person_id
  include Memcacheable
  cache_index :person_id
  cache_belongs_to :person
  cache_method :meow

  def meow(how_many=1)
    how_many.times.map{ 'meow' }.join ' '
  end
end

describe Memcacheable do
  let(:id)     { 123 }
  let(:person) { Person.new id: id, color: 'red', number: 42 }

  before :all do
    unless defined?(Rails)
      class Rails; cattr_accessor :cache, :logger; end
      Rails.cache  = ActiveSupport::Cache::MemoryStore.new
      Rails.logger = ActiveSupport::Logger.new(STDOUT)
      Rails.logger.level = 3
    end
  end

  after { Rails.cache.clear }
  
  describe '::fetch' do
    before do
      Person.stub(:find).with(id).and_return person
    end

    it "finds the correct record" do
      Person.fetch(id).should eq person
    end

    it "only queries once and then caches" do
      Person.should_receive(:find).once
      Person.fetch id
      Person.fetch id
    end
  end

  describe '#touch' do
    before do
      Person.stub(:find).with(id).and_return person
    end

    it "flushes the cache" do
      Person.fetch(id).touch
      Person.should_receive(:find).once
      Person.fetch id
    end
  end

  describe '::fetch_by' do
    let(:good_criteria) {{ number: 42, color: 'red' }}

    before do
      Person.stub(:find_by) do |criteria|
        criteria.all?{ |k,v| person.send(k) == v } ? person : nil
      end
    end

    it "finds the correct record" do
      Person.fetch_by(good_criteria).should eq person
    end

    it "only queries once and then caches" do
      Person.should_receive(:find_by).once
      Person.fetch_by good_criteria
      Person.fetch_by good_criteria
    end

    it "raises on non-hash style args" do
      expect { Person.fetch_by 'color = ?', 'red' }.to raise_error
    end

    it "raises on non-cached indexes" do
      expect { Person.fetch_by color: 'red' }.to raise_error
    end

    it "flushes when model updated" do
      person = Person.fetch_by good_criteria
      person.update_attributes number: 7
      Person.should_receive(:find_by).once
      Person.fetch_by good_criteria
    end
  end

  describe '::fetch_by!' do
    before do
      Person.stub(:find_by).and_return nil
    end

    it "raises error on nil result" do
      expect { Person.fetch_by!(number: 42) }.to raise_error(ActiveRecord::RecordNotFound)
    end
  end

  describe 'flushing cached_indexes' do
    let(:old_num) {{ number: 42 }}
    let(:new_num) {{ number: 21 }}
    let(:old_person) {{ person_id: id }}
    let(:new_person) {{ person_id: 345 }}
    let(:kittens) { 3.times.map { Kitten.new person_id: id} }

    before do
      Person.stub(:find_by) do |criteria|
        criteria.all?{ |k,v| person.send(k) == v } ? person : nil
      end
      Kitten.stub(:where) do |criteria|
        kittens.select do |kitten|
          criteria.all? { |k,v| kitten.send(k) == v }
        end
      end
    end

    it "flushes old and new values for cached_indexes" do
      Person.fetch_by(old_num).should eq person
      Person.fetch_by(new_num).should eq nil
      person.update_attributes new_num
      Person.fetch_by(old_num).should eq nil
      Person.fetch_by(new_num).should eq person

      Kitten.fetch_where(old_person).should eq kittens
      Kitten.fetch_where(new_person).should eq []
      kittens.each { |k| k.update_attributes new_person }
      Kitten.fetch_where(old_person).should eq []
      Kitten.fetch_where(new_person).should eq kittens
    end
  end

  describe '::cache_belongs_to' do
    let(:kitten) { Kitten.new person_id: id }
    before do
      Person.stub(:find).and_return nil
      Person.stub(:find).with(id).and_return person 
    end

    it "defines a new fetch method" do
      kitten.should.respond_to? :fetch_person
    end

    it "fetches the correct object" do
      kitten.fetch_person.should eq person
    end

    it "only queries once and then caches" do
      Person.should_receive(:fetch).once
      kitten.fetch_person
      kitten.fetch_person
    end

    it "flushes when touched by association" do
      kitten.fetch_person
      kitten.touch
      Person.should_receive(:fetch).once
      kitten.fetch_person
    end
  end

  describe '::cache_has_one' do
    let(:dog) { Dog.new person_id: id }
    before do
      person.stub(:dog).and_return dog
      Dog.stub(:find_by) do |criteria|
        criteria.all?{ |k,v| dog.send(k) == v } ? dog : nil
      end  
    end

    it "defines a new fetch method" do
      person.should.respond_to? :fetch_dog
    end

    it "fetches the correct object" do
      person.fetch_dog.should eq dog
    end

    it "only queries once and then caches" do
      person.should_receive(:dog).once
      person.fetch_dog
      person.fetch_dog
    end

    it "flushes when touched by association" do
      person.fetch_dog
      person.touch
      person.should_receive(:dog).once
      person.fetch_dog
    end
  end

  describe '::fetch_where' do
    let(:kittens) { 3.times.map { Kitten.new person_id: id} }
    before do
      Kitten.stub(:where) do |criteria|
        kittens.select do |kitten|
          criteria.all? { |k,v| kitten.send(k) == v }
        end
      end
    end

    it "fetches the correct objects" do
      Kitten.fetch_where(person_id: id).should eq kittens
    end

    it "only queries once and then caches" do
      Kitten.should_receive(:where).once
      Kitten.fetch_where person_id: id
      Kitten.fetch_where person_id: id
    end

    it "raises on non-hash style args" do
      expect { Kitten.fetch_where 'color = ?', 'red' }.to raise_error
    end

    it "raises on non-cached indexes" do
      expect { Kitten.fetch_where id: 123 }.to raise_error
    end

    it "flushes when model updated" do
      kittens = Kitten.fetch_where person_id: id
      kittens.first.update_attributes person_id: 345
      Kitten.should_receive(:where).once
      Kitten.fetch_where person_id: id
    end
  end

  describe '::cache_has_many' do
    let(:kittens) { 3.times.map { Kitten.new person_id: id} }
    before do
      Kitten.stub(:where) do |criteria|
        kittens.select do |kitten|
          criteria.all? { |k,v| kitten.send(k) == v }
        end
      end
    end

    it "defines a new fetch method" do
      person.should.respond_to? :fetch_kittens
    end

    it "fetches the correct collection" do
      person.fetch_kittens.should eq kittens
    end

    it "only queries once and then caches" do
      Kitten.should_receive(:fetch_where).once
      person.fetch_kittens
      person.fetch_kittens
    end

    it "flushes when touched by association" do
      person.fetch_kittens
      person.touch
      Kitten.should_receive(:fetch_where).once
      person.fetch_kittens
    end
  end

  describe '::cache_method' do
    let(:kitten) { Kitten.new }

    it "defines a new fetch method" do
      kitten.should.respond_to?(:fetch_meow)
    end

    it "calls down to the method correctly on cache miss" do
      kitten.fetch_meow(3) { |sound| sound.upcase }.should eq 'meow meow meow'
    end

    it "only queries once and then caches" do
      kitten.should_receive(:meow).once
      kitten.fetch_meow
      kitten.fetch_meow
    end

    it "flushed when touched by an association" do
      kitten.fetch_meow
      kitten.touch
      kitten.should_receive(:meow).once
      kitten.fetch_meow
    end
  end
end
