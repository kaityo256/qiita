# frozen_string_literal: true
require 'set'
require 'yaml'

data = YAML.safe_load(File.open('qiita.yaml'))
tag_list = YAML.safe_load(File.open('tags.yaml'))

tags = []
data.each do |article|
    article['tags'].split(',').each do |item|
    puts "#{item} #{tag_list[item]}"
end
end
