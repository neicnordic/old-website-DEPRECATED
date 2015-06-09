require 'rbconfig'

LANG = "en_EN.UTF-8"

if RbConfig::CONFIG["host_os"] =~ /mswin|mingw/
    SET = "set"
else
    SET = "export"
end

task :build do
    system "#{SET} LANG=#{LANG} && jekyll build"
end

