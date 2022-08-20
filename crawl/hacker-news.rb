#!/usr/bin/env ruby
require 'json'
require 'open-uri'

def fetch_hacker_news_json(resource)
  JSON.parse URI("https://hacker-news.firebaseio.com/v0/#{resource}").open.read
end

today = Time.now.getlocal('-03:00')
page_header = <<~HTML
  <!DOCTYPE html>
  <html>
    <head>
      <title>Dejá de hueve.ar - Hacker News</title>
      <meta content="width=device-width, initial-scale=1" name="viewport">
      <meta charset="utf-8">
      <style>
        body {
          background-color: #222;
          font: 14px sans-serif;
          color: #f6f4ea;
        }
        .articles {
          line-height: 2;
          margin: 2em;
        }
        .articles, .articles a {
          color: #aaa;
        }
        .articles a.link-to-story {
          color: #f6f4ea;
        }
      </style>
    </head>
    <body>
      <h1>Hacker News</h1>
      <h2>Snapshot del #{today.strftime('%d/%m')}</h2>
      <div class="articles">
HTML

page_footer = <<~HTML
      </div>
      <em>Snapshot generado el #{today}. Todos los horarios son locales de Argentina (GMT-3)</em>
    </body>
  </html>
HTML

frontpage = fetch_hacker_news_json('topstories.json').take(30).map { |story_id| fetch_hacker_news_json("item/#{story_id}.json") }

this_year = today.year
File.open('hacker-news.html', 'w') { |page|
  page.write(page_header)
  frontpage.each { |story|
    discussion_url = "https://news.ycombinator.com/item?id=#{story['id']}"
    story_url = story['url'] || discussion_url
    story_time = Time.at(story['time']).getlocal('-03:00')
    story_relative_time = story_time.strftime(story_time.year == this_year ? '%d/%m %H:%M' : '%d/%m/%Y %H:%M')
    article = <<~ARTICLE
      <div class="article">
        <a class="link-to-story" href="#{story_url}">#{story['title']}</a>
        | #{story_relative_time} | #{story['score']} points |
        <a class="link-to-discussion" href="#{discussion_url}">#{story['descendants']} comments</a>
      </div>
    ARTICLE
    page.write(article)
  }
  page.write(page_footer)
}
