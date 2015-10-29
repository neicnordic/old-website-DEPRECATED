# Requires page_cmp.rb plugin
#

require 'pathname'

module Jekyll
  class IncludeTopMenuTag < Liquid::Tag
    def initialize(tag_name, markup, tokens)
      super
    end
    
    def add_item(page,page_url,section,is_current)
      return "<li id='portaltab-#{section}' class='#{is_current ? 'selected' : 'plain'}'><a href='#{page_url}'>#{page.data['title']||page.dir}</a></li>"
    end
    
    def render(context)
      site = context.registers[:site]
      
      page = context.environments.first["page"]
      current_section = page["url"].split("/")[1]
      
      tabclass = current_section == "index.html" ? 'selected' : 'plain'

      if site.baseurl != ''
        html = '<li id="portaltab-index_html" class="plain"><a href="/">Home</a></li>'              
        html += "<li id='portaltab-index_html' class='#{tabclass}'><a href='#{site.baseurl}/'>#{site.config['name']}</a></li>"
      else
        html = "<li id='portaltab-index_html' class='#{tabclass}'><a href='#{site.baseurl}/'>Home</a></li>"
      end
      
      
      # Get root level directories
      filtered_pages = []
      site.pages.each do |p|
        next if not p.index?
        next if p.data['hidden']
        
        parts = p.url.split("/")
        if parts.length == 3 and parts.last == "index.html" then
          filtered_pages << [p, parts[1], parts[1] == current_section]
        end
      end
      
      baseurl = site.config['baseurl']
      sorted_pages = filtered_pages.sort
      sorted_pages.each do |p,section,is_current|
        html += self.add_item(p, baseurl+p.url.chomp('/index.html'), section, is_current)
      end
      
      html
    end
  end
end
    
Liquid::Template.register_tag("generate_top_menu", Jekyll::IncludeTopMenuTag)
