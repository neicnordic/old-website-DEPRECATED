module Jekyll
  module ContactInfoFilter
    def contact_info(site, group_id = "".freeze)
      dir = site['group_dir'] || 'about/team'
      group = {}
      site['data']['people'].each_pair do |person_id, person|
        next if not group_id == 'all' and not person.fetch('groups', []).include? group_id
        p = person.clone
        p['groups'] = p['groups'].map { |gid|
          { 'id' => gid,
            'name' => site['data']['groups'][gid]['name'] || gid,
            'url' => File.join(site['baseurl'], dir, gid)}
        }
        group[person_id] = p
      end
      return group
    end
  end
end

Liquid::Template.register_filter(Jekyll::ContactInfoFilter)
