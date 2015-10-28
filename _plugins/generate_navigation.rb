# Requires page_cmp.rb plugin

module Jekyll
  
  class IncludeListingTag < Liquid::Tag
    def initialize(tag_name, markup, tokens)
      super
    end
    
    def add_item(baseurl, page)
      return "<li><a href=\"#{baseurl}#{page.dir}\">#{page.data['title']||page.dir}</a></li>"
    end
    
    def render(context)
      site = context.registers[:site]
      page = context.environments.first["page"]
      page_dir = page['url'].split("/")[0..-2].join("/")
      if page_dir == "" then
        page_dir="/"
      end
      
      html = ''
      
      # Filter out pages that do not appear in the menu
      filtered_pages = []
      site.pages.each do |p|
        next if not p.index?
        next if p.data['hidden']
        
        if p.url == "/index.html"
          p_grandparent = ""
        else
          p_grandparent = "/" + p.url.split("/")[0..-3].join("/")
          p_grandparent = p_grandparent.gsub("//","/")
        end
        
        if p_grandparent == page_dir
          filtered_pages << p
        end
      end
      
      sorted_pages = filtered_pages.sort
      
      sorted_pages.each do |page|                
        html += self.add_item(site.baseurl, page)
      end
      
      html
    end
  end
end

Liquid::Template.register_tag('generate_navigation', Jekyll::IncludeListingTag)
