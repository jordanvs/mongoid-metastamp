# encoding: utf-8

module Mongoid #:nodoc:
  module Metastamp
    class Time < ::Time

      def mongoize
        Time.mongoize(self)
      end

      class << self
        
        # Get the object as it was stored in the database, and instantiate
        # this custom class from it.
        def demongoize(object)
          return nil if object.blank?
          return super(object) if object.instance_of?(::Time)
          time = object['time'].getlocal unless Mongoid::Config.use_utc?
          zone = ActiveSupport::TimeZone[object['zone']]
          zone = ActiveSupport::TimeZone[object['offset']] if zone.nil?
          time.in_time_zone(zone)
        end
        
        # Takes any possible object and converts it to how it would be
        # stored in the database.
        def mongoize(object)
          return nil if object.blank?
          time = super(object)
          local_time = time.in_time_zone(::Time.zone)
          { 
            time:         time,
            normalized:   normalized_time(local_time),
            year:         local_time.year,
            month:        local_time.month,
            day:          local_time.day,
            wday:         local_time.wday,
            hour:         local_time.hour,
            min:          local_time.min,
            sec:          local_time.sec,
            zone:         ::Time.zone.name,
            offset:       local_time.utc_offset
          }.stringify_keys
        end
        
        # Converts the object that was supplied to a criteria and converts it
        # into a database friendly form.
        def evolve(object)
          case object
          when Time then object.mongoize
          else object
          end
        end
      
      protected
      
        def parse_datetime(value)
          case value
            when ::String
              ::DateTime.parse(value)
            when ::Time
              offset = ActiveSupport::TimeZone.seconds_to_utc_offset(value.utc_offset)
              ::DateTime.new(value.year, value.month, value.day, value.hour, value.min, value.sec, offset)
            when ::Date
              ::DateTime.new(value.year, value.month, value.day)
            when ::Array
              ::DateTime.new(*value)
            else
              value
          end
        end
  
        def normalized_time(time)
          ::Time.parse("#{ time.strftime("%F %T") } -0000").utc
        end
      end
    end
  end
end