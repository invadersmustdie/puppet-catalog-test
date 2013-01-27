module PuppetCatalogTest
  class TestCase < Struct.new(:name, :facts, :passed, :error, :duration)
  end
end
