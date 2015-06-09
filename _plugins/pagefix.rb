module Jekyll

  class Page

     alias orig_render render
     def render(layouts,site_payload)
       res = orig_render(layouts,site_payload)
       self.output = fix_html(self.output)
       res
     end

     def fix_html(data)
        data.gsub!('<table>','<table class="table table-striped">')
        data
     end

   end
end
