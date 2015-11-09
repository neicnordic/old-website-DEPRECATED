module Jekyll
  module KeySortFilter
    def key_sort(input, *keys)
      if input.is_a?(Hash)
        return input.sort_by {|_,h| keys.map {|k| h[k]}}
      end
      return input.sort {|h| keys.map {|k| h[k]}}
    end
  end
end

Liquid::Template.register_filter(Jekyll::KeySortFilter)
