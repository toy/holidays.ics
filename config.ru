require 'set'
require 'rack'
require 'sinatra'
require 'holidays'
require 'icalendar'

use Rack::Deflater

helpers do
  def h(text)
    Rack::Utils.escape_html(text)
  end

  def webcal_link(region)
    text = "#{flag_emoji region} #{h region.tr('_', '-')}".strip
    %Q{<a href="webcal://#{h request.host}/#{h region}.ics">#{text}</a>}
  end

  def flag_emoji(region)
    return unless region.length == 2
    return if region == 'ru' # https://war.ukraine.ua/

    region.upcase.chars.map{ |char| 0x1f1a5 + char.ord }.pack('U*')
  end
end

REGIONS = Holidays.available_regions.map(&:to_s).to_set
COUNTRY_REGIONS, OTHER_REGIONS = REGIONS.sort.partition{ |region| region.split('_', 2)[0].length == 2 }

get '/' do
  erb :index
end

get '/:region.ics' do
  region = params[:region]
  halt 404 unless REGIONS.include?(region)

  filters = [:informal, :observed].select{ |flag| params[flag] }

  today = Date.today
  first = today.prev_year
  last = today.next_year(2)

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

  content_type 'text/calendar'
  cal.to_ical
end

run Sinatra::Application
