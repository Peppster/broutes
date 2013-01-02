require 'fit'

module Broutes::Formats
  class FitFile

    def load(file, route)
      fit_file = Fit::File.read(file)
      Broutes.logger.info {"Started fit processing"}
      i = 0
      fit_file.records.select {|r| r.content && r.content.record_type == :record }.each do |r|
        begin
          pr = r.content
          route.add_point(convert_position(pr.position_lat), convert_position(pr.position_long), {
              elevation: pr.altitude, 
              time: record_time(r), 
              distance: pr.distance, 
              heart_rate: pr.heart_rate, 
              power: pr.power,
              speed: pr.speed,
              cadence: pr.cadence
              })
          i += 1
        rescue => e
          Broutes.logger.debug {"#{e.message} for #{r}"}
        end
      end
      Broutes.logger.info {"Loaded #{i} data points"}
    end

    def convert_position(value)
      (8.381903171539307e-08 * value).round(5)
    end

    def record_time(record)
      utc_seconds = record.content.timestamp
      utc_seconds += record.header.time_offset if record.header.compressed_timestamp? 
      Time.new(1989, 12, 31) + utc_seconds
    end

  end
end