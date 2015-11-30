module Jekyll

  class GroupPage < Page
    def initialize(site, base, dir, title, menu, id)
      @site = site
      @base = base
      @dir = dir
      @name = 'index.html'

      self.process(@name)
      self.read_yaml(File.join(base, '_layouts'), 'group.html')
      self.data['title'] = title
      self.data['menu'] = menu
      self.data['id'] = id
    end
  end
  
  class JsonGroupPage < Page
    def initialize(site, base, dir, id)
      @site = site
      @base = base
      @dir = dir
      @name = 'index.html'

      self.process(@name)
      self.read_yaml(File.join(base, '_layouts'), 'group.json')
      self.data['id'] = id
    end
  end

  class GroupPageGenerator < Generator
    safe true

    def generate(site)
      if site.layouts.key? 'group'
        dir = site.config['group_dir'] || 'about/team'
        api_dir = site.config['contact_api_dir'] || 'int/api/contact'
        existing = []
        site.pages.each do |page|
          if match = page.url.match(%r{^/#{dir}/([^/]+)/[^/]*$})
            existing << match.captures[0]
          end
        end
        site.data['people'].each_value do |person|
          (person['groups'] || []).each do |group_id|
            next if existing.include? group_id
            title = site.data['groups'][group_id]['name'] || group_id
            menu = site.data['groups'][group_id]['menu'] || 100
            site.pages << GroupPage.new(site, site.source, File.join(dir, group_id), title, menu, group_id)
            site.pages << JsonGroupPage.new(site, site.source, File.join(api_dir, group_id), group_id)
            existing << group_id
          end
        end
      end
    end
  end

end
