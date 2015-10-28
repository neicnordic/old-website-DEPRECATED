#
# Yeah I'm monkeypatching Liquid through Jekyll. What of it?????
#
# Features:
# 
# Jokes aside, this is to provide whitespace squashing similar to ERB/Puppet, so you can optionally
# delete all whitespace directly before or after liquid tags by adding a dash to the opening or
# closing brace/percent sign, like: {%- , or: -%}  (or both). This also lets you use multiline 
# {# comments #}, which can help breaking up long lines. 
# This variant also deletes leading whitespace from lines starting with a | character, up to and 
# including the | character. This lets you write output strings indented to match your code logic.
# See comments below for specifics.
#   
# Rationale:
#
# The reason we do this is that we use mediawiki markup in most our pages, which has syntactically 
# significant whitespace (notably: indent and newlines). Template code that generates this 
# (specifically: jekyll includes) often becomes becomes very hard to read and maintain, with code 
# lines in the range of hundreds of characters in length, as they are by necessity broken up where 
# target language syntax rather than logic or readability would otherwise dictate.
#
# Thus: I'm monkeypatching this bugger. You're welcome.
#

def erb_style_whitespace_squash(text)
  text.to_s
    .gsub(/^[ \t]+\|/, '')           # remove spaces/tabs + | if first on line
    .gsub(/\{#.*?#\}/m, '')          # remove single-line & multiline {# comments #}
    .gsub(/[ \t]*\{\%-/, '{%')       # trim spaces/tabs before {%-
    .gsub(/-\%\}[ \t]*\r?\n?/, '%}') # trim spaces/tabs + newline after -%}
    .gsub(/[ \t]*\{\{-/, '{{')       # trim spaces/tabs before {{-
    .gsub(/-\}\}[ \t]*\r?\n?/, '}}') # trim spaces/tabs + newline after -}}
end

module Liquid

  # Extensions to the Liquid Template class.

  class Template

    # Chained version of parse() method. 
    
    alias orig_parse parse
    def parse(text)
        orig_parse(erb_style_whitespace_squash(text))
    end

  end
end
