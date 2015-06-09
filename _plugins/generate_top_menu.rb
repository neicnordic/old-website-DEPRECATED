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

    class IncludeTopMenuTag < Liquid::Tag
        def initialize(tag_name, markup, tokens)
            super
        end

        def add_item(page,page_url,section,is_current)
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
                if !!data['hidden']
                    return ''
                end
            else
                puts "File not found: #{source_file}"
            end

			if is_current then
			   return "<li id='portaltab-#{section}' class='selected'><a href='#{page_url}'>#{title}</a></li>"
			end
			return "<li id='portaltab-#{section}' class='plain'><a href='#{page_url}'>#{title}</a></li>"
        end

        def render(context)
            site = context.registers[:site]
            @source = site.source
            site_pages = context.environments.first['site']['pages']

			page = context.environments.first["page"]
			current_section = page["url"].split("/")[1]
			
			if current_section == "index.html" then
				html = '<li id="portaltab-index_html" class="selected"><a href="/">Home</a></li>'
			else
				html = '<li id="portaltab-index_html" class="plain"><a href="/">Home</a></li>'
			end


            # Get root level directories
            filtered_pages = []
            site_pages.each do |p|
                next if not p.index?
				source_file = File.join(@source,p.source_path)
				next if not File.exists?(source_file)
				
				parts = p.url.split("/")
				if parts.length == 3 and parts.last == "index.html" then
                    filtered_pages << [p, parts[1], parts[1] == current_section]
				end
            end

            sorted_pages = filtered_pages.sort
            sorted_pages.each do |p,section,is_current|
                html += self.add_item(p, p.url, section, is_current)
            end

            html
        end
    end
end

Liquid::Template.register_tag("generate_top_menu", Jekyll::IncludeTopMenuTag)
