require 'erb'
require 'holidays'
require 'icalendar'
require 'pathname'
require 'progress'

PARENT_LOOKUP = Holidays::PARENT_REGION_LOOKUP.dup
REGION_NAMES = Hash.new{ |h, region| h[region] = Holidays.region_name(region) }

PARENT_LOOKUP.select{ |region, parent| region != parent && parent !~ /\A[a-z]{2}(\z|_)/ }.tap do |wrong_parents|
  abort 'remove the wrong parents fix' if wrong_parents.empty?
  wrong_parents.each{ |region, parent| PARENT_LOOKUP[region] = region }
end

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
    text = "#{flag_emoji region} #{h region.to_s.tr('_', '-')}".strip
    %Q{<a data-path="#{h region.to_s}.ics" title="#{h REGION_NAMES[region]}">#{text}</a>}
  end

  def flag_emoji(region)
    return unless region.length == 2
    return if region == :ru # https://war.ukraine.ua/

    region.to_s.upcase.chars.map{ |char| 0x1f1a5 + char.ord }.pack('U*')
  end
end

desc 'build'
task :build do
  include Helpers

  regions = Holidays.available_regions
  abort if regions.any?{ _1 =~ /[^a-z_]/ }

  country_regions, other_regions = regions.sort.partition{ |region| region =~ /\A[a-z]{2}(\z|_)/ }

  src = Pathname(__dir__)
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

        cal.append_custom_property('X-WR-CALNAME', "Holidays: #{region.to_s.tr('_', '-')}")
        cal.append_custom_property('X-PUBLISHED-TTL', 'P1W')
        cal.append_custom_property('X-APPLE-CALENDAR-COLOR', '#aa0112')

        Holidays.between(first, last, region, *filters).each do |holiday|
          cal.event do |e|
            e.dtstart = Icalendar::Values::Date.new(holiday[:date])
            e.summary = holiday[:name]

            # filter out regions from other countries
            parent = PARENT_LOOKUP[region]
            holiday_regions = holiday[:regions].select{ |r| PARENT_LOOKUP[r] == parent }

            unless holiday_regions == [region]
              e.description = case
              when holiday_regions == [parent]
                "in whole #{REGION_NAMES[parent]}"
              when holiday_regions.include?(region)
                "also in #{REGION_NAMES.values_at(*holiday_regions - [region]).join(', ')}"
              else
                "in #{REGION_NAMES.values_at(*holiday_regions).join(', ')}"
              end
            end
          end
        end

        dst.join(*filters.map(&:to_s), "#{region}.ics").write!(cal.to_ical)
      end
    end
  end

  dst.join('index.html').write!(
    ERB.new(src.join('index.html.erb').read).result(binding)
  )

  %w[favicon.svg robots.txt].each do |basename|
    dst.join(basename).write!(src.join(basename).read)
  end
end

task default: :build
