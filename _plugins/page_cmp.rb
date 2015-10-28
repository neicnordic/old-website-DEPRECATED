module Jekyll

  class Page
    def <=>(other)
      @data['menu'] = 100 if not @data.key?("menu")
      other.data['menu'] = 100 if not other.data.key?("menu")
      if @data['menu'] == other.data['menu']
		return (@data['title'] || @url) <=> (other.data['title'] || other.url)
	  end
      return @data['menu'] <=> other.data['menu']
    end
  end

end

