# Auto-generates navigation
# {% generate_navigation %}
#

require 'pathname'

module Jekyll
    class Page
        def source_path
            File.join(@dir, @name).sub(%r{^/*},'')
        end
        def parent
            @dir.sub(%r{^/*},'')
        end

        def <=>(other)
            content1 = File.read(path)
            content2 = File.read(other.path)

            if content1 =~ /^(---\s*\n.*?\n?)^(---\s*$\n?)/m
                content1 = $POSTMATCH
                begin
                    data1 = YAML.load($1)
                rescue => e
                    puts "YAML Exception reading #{name}: #{e.message}"
                end
            end

            if content2 =~ /^(---\s*\n.*?\n?)^(---\s*$\n?)/m
                content2 = $POSTMATCH
                begin
                    data2 = YAML.load($1)
                rescue => e
                    puts "YAML Exception reading #{name}: #{e.message}"
                end
            end

            data1['menu'] = 100 if not data1.key?("menu")
            data2['menu'] = 100 if not data2.key?("menu")
            #puts @dir+": "+data1['menu'].to_s + " <=> " +other.dir+" "+data2['menu'].to_s
            if data1['menu'] == data2['menu']
				return data1['title'] <=> data2['title']
			end
            return data1['menu'] <=> data2['menu']
        end
    end

    class IncludeListingTag < Liquid::Tag
        def initialize(tag_name, markup, tokens)
            super
        end

        def add_item(page,page_url)
            if page.index?
                title = page.parent
            else
                title = page.basename
            end
            # Try to read title from source file
            source_file = File.join(@source,page.source_path)
            if File.exists?(source_file)
                content = File.read(source_file)

                if content =~ /^(---\s*\n.*?\n?)^(---\s*$\n?)/m
                    content = $POSTMATCH
                    begin
                        data = YAML.load($1)
                    rescue => e
                        puts "YAML Exception reading #{name}: #{e.message}"
                    end
                end

                if data['title']
                    title = data['title']
                end
                if data['description']
                    description = data['description']
                end
            else
                puts "File not found: #{source_file}"
            end
            ##s = "<li><a href=\"/#{page.parent}#{page.url}\">#{title}</a></li>"
            ##if page_url == "/index.html"
            ##    return "<div class=\"col-md-6\"><h3><a href=\"/#{page.parent}\">#{title}</a></h3><p>#{description}</p></div>"
            ##else
            ##    return "<div class=\"col-md-4\"><h3><a href=\"/#{page.parent}\">#{title}</a></h3><p>#{description}</p></div>"
            ##end
			return "<li class=\"navTreeItem visualNoMarker navTreeFolderish\"><a href=\"/#{page.parent}\" class=\"state-published navTreeFolderish contenttype-folder\" title=\"#{description}\"><span>#{title}</span></a></li>"
        end

        def render(context)
            site = context.registers[:site]
            @source = site.source
            site_pages = context.environments.first['site']['pages']

            page_url = context.environments.first["page"]["url"]
            page_base = page_url.split("/")[0..-2].join("/")
            if page_base == "" then
                page_base="/"
            end

            #html = '<hr>'
            html = ''
            list = Hash.new {|h,k| h[k] = [] }

            # Filter out pages that do not appear in the menu
            filtered_pages = []
            site_pages.each do |page|
                next if not page.index?
				source_file = File.join(@source,page.source_path)
				next if not File.exists?(source_file)

                if page.url == "/index.html"
                    link_root = ""
                else
                    link_root = "/" + page.url.split("/")[0..-3].join("/")
                    link_root = link_root.gsub("//","/")
                end

                if link_root == page_base
                    filtered_pages << page
                end
            end

            sorted_pages = filtered_pages.sort

            sorted_pages.each do |page|                
                html += self.add_item(page,page_url)
            end

            html
        end
    end
end

Liquid::Template.register_tag('generate_navigation', Jekyll::IncludeListingTag)
