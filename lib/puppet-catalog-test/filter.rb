module PuppetCatalogTest
  class Filter
    attr_accessor :include_pattern, :exclude_pattern

    def initialize(include_pattern = DEFAULT_FILTER, exclude_pattern = nil)
      @include_pattern = include_pattern
      @exclude_pattern = exclude_pattern
    end
  end
end
