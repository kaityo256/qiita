# frozen_string_literal: true

require 'yaml'
require 'open-uri'
require 'stringio'

def list_articles
  data = YAML.safe_load(File.open('qiita.yaml'))
  dirlist = YAML.safe_load(File.open('dirlist.yaml'))
  ss = StringIO.new
  # 作成日(created_at)でソート
  data.sort! { |a, b| b['created_at'] <=> a['created_at'] }
  data.each do |article|
    title = article['title']
    next unless dirlist[title]

    dir = dirlist[title]
    created = Time.iso8601(article['created_at'])
    updated = Time.iso8601(article['updated_at'])
    url = article['url']
    ss.puts "* [#{title}](#{dir}/README.md)"
    ss.puts "  * [Qiita](#{url})"
    ss.puts "  * 作成：#{created}"
    ss.puts "  * 更新：#{updated}"
  end
  ss.string
end

template = File.read('template.md')
articles = list_articles
template.gsub!('@articles', articles)
File.open('README.md', 'w') do |f|
  f.puts template
end
