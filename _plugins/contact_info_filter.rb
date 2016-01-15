module Jekyll
  module ContactInfoFilter
    def contact_info(site, group_id = "".freeze)
      dir = site['group_dir'] || 'about/team'
      group = {}
      site['data']['people'].each_pair do |person_id, person|
        next if not group_id == 'all' and not person.fetch('groups', []).include? group_id
        p = person.clone
        p['groups'] = p['groups'].map { |gid|
          title = site['data']['groups'][gid]['title'] || gid
          { 'id' => gid,
            'title' => title,
            'heading' => site['data']['groups'][gid]['heading'] || title,
            'url' => File.join(site['baseurl'], dir, gid)}
        }
        group[person_id] = p
      end
      return group
    end
  end
end

Liquid::Template.register_filter(Jekyll::ContactInfoFilter)
