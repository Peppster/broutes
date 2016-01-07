require 'nokogiri'

module Broutes::Formats
  class GpxTrack

    def load(file, route)
      doc = Nokogiri::XML(file)
      Broutes.logger.info {"Loaded #{file} into #{doc.to_s.slice(0, 10)}"}

      name_node = doc.css('trk name').first
      if name_node
        route.name = name_node.text
      end

      i = 0
      doc.css('trkpt').each do |node|
        p = route.add_point(lat: node['lat'].to_f, lon: node['lon'].to_f, elevation: point_elevation(node), time: point_time(node))
        i += 1
      end
      Broutes.logger.info {"Loaded #{i} data points"}
    end

    def point_elevation(node)
      if elevation_node = node.at_css('ele')
        elevation_node.inner_text.to_f
      end
    end

    def point_time(node)
      if time_node = node.at_css('time')
        DateTime.parse(time_node.inner_text).to_time
      end
    end
  end
end
