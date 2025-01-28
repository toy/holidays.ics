require 'erb'
require 'holidays'
require 'icalendar'
require 'pathname'
require 'progress'

Pathname.class_eval do
  def write!(content)
    dirname.mkpath
    write(content)
  end
end

module Helpers
  def h(text)
    CGI.escapeHTML(text)
  end

  def webcal_link(region)
    text = "#{flag_emoji region} #{h region.tr('_', '-')}".strip
    %Q{<a data-path="#{h region}.ics">#{text}</a>}
  end

  def flag_emoji(region)
    return unless region.length == 2
    return if region == 'ru' # https://war.ukraine.ua/

    region.upcase.chars.map{ |char| 0x1f1a5 + char.ord }.pack('U*')
  end
end

desc 'build'
task :build do
  include Helpers

  regions = Holidays.available_regions.map(&:to_s)
  abort if regions.any?{ _1 =~ /[^a-z_]/ }

  country_regions, other_regions = regions.sort.partition{ |region| region.split('_', 2)[0].length == 2 }

  dst = Pathname('public')
  dst.rmtree

  today = Date.today
  first = today.prev_year
  last = today.next_year(2)
  all_filters = [:informal, :observed]

  (0..all_filters.length).with_progress do |count|
    all_filters.combination(count).with_progress do |filters|
      regions.with_progress do |region|
        cal = Icalendar::Calendar.new

        cal.append_custom_property('X-WR-CALNAME', "Holidays: #{region.tr('_', '-')}")
        cal.append_custom_property('X-PUBLISHED-TTL', 'P1W')
        cal.append_custom_property('X-APPLE-CALENDAR-COLOR', '#aa0112')

        Holidays.between(first, last, region, *filters).each do |holiday|
          cal.event do |e|
            e.dtstart = Icalendar::Values::Date.new(holiday[:date])
            e.summary = holiday[:name]
          end
        end

        dst.join(*filters.map(&:to_s), "#{region}.ics").write!(cal.to_ical)
      end
    end
  end

  dst.join('index.html').write!(
    ERB.new(File.read('index.erb')).result(binding)
  )

  %w[favicon.svg robots.txt].each do |basename|
    dst.join(basename).write!(File.read(basename))
  end
end
