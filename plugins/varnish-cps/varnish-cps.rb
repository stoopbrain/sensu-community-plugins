#!/usr/bin/env ruby
#
# DESCRIPTION:
#   Collect Varnish backend health stats from graphite.
#
# OUTPUT:
#   array per varnish backend


require 'httparty'

# time_period = '6hours'
time_period = '5minutes'

graphite_function = "summarize(exclude(*.varnish.VBE.*.happy,',*dummy'),'1minute','min')"
graphite_url = "http://graphite.sit.cps.awseuwest1.itvcloud.zone/render?target=#{graphite_function}&format=json&from=-#{time_period}"

class VarnishHealthCheck

  def microservice_name(name)
    name.match(/VBE.(\w*?)_\d/)[1]
  end

  # we need this to differentiate between our multiple FETDs
  def traffic_director_instance(name)
    name.match(/^summarize\(([^\.]+)./)[1] # regex is tightly coupled to the graphite function
  end

  def unhealthy_period(datapoints)
    most_recent_datapoint_time = datapoints.last[1]
    datapoints.reverse_each do |(datapoint, timestamp)|
      # puts "[timestamp: #{timestamp}, datapoint: #{datapoint}]"
      if healthy? datapoint
        return unhealthy_period_in_minutes(most_recent_datapoint_time, timestamp)
      end
    end
    unhealthy_period_in_minutes(most_recent_datapoint_time, datapoints.first[1])
  end

  def healthy?(datapoint)
    !(datapoint == 0) # null as healthy
  end

  def unhealthy_period_in_minutes(most_recent_datapoint_time, timestamp)
    (most_recent_datapoint_time - timestamp) / 60.0
  end

  def health_responses(response)
    response.inject([]) do |result, node|
      graphite_series_name = node['target']
      # puts "graphite_series_name: #{graphite_series_name}"

      microservice     = microservice_name graphite_series_name
      traffic_director = traffic_director_instance graphite_series_name

      datapoints                    = node['datapoints']
      microservice_unhealthy_period = unhealthy_period datapoints

      # puts "microservice_unhealthy_period: #{microservice_unhealthy_period}"
      # puts '------------------------------'
      result << [microservice, traffic_director, microservice_unhealthy_period]
    end
  end

end

# puts "Calling graphite JSON API: #{graphite_url}"
# graphite_response = HTTParty.get graphite_url
# puts graphite_response.body

# varnish_health = VarnishHealthCheck.new
# responses = varnish_health.health_responses(graphite_response)
# puts responses[0] == ["dawkins_query", "betd-id87a2a9a", 0.0]
