RSpec.describe VarnishHealthCheck do

  # TODO: Stop using a JSON file to store data

  context 'When checking health_responses' do

    let(:graphite_response) { JSON.parse(File.read("#{File.dirname(__FILE__)}/response.json")) }
    let(:varnish_health) { VarnishHealthCheck.new }
    let(:responses) { varnish_health.health_responses(graphite_response) }

    it 'should get a maximum fail duration if all checks failed' do
      puts "responses: #{responses}"
      expect(responses[0]).to eq(['dawkins_query', 'betd-id87a2a9a', 5.0])
    end

    it 'should get no fail duration when checks failed some of the time, but not most recently' do
      expect(responses[1]).to eq(['minerva', 'betd-id87a2a9a', 0.0])
    end

    it 'should get a fail duration corresponding to the number of concurrent failures when checks failed most recently' do
      expect(responses[2]).to eq(['venus', 'betd-id87a2a9a', 2.0])
    end

    it 'should get no fail duration when all checks passed' do
      expect(responses[3]).to eq(['vogue_query', 'betd-id87a2a9a', 0.0])
    end

    it 'should distinguish between traffic directors for the same service' do
      fnord_tds = responses.map { |element| element[1] if element[0] == 'fnord' }.compact
      expect(fnord_tds).to eq(%w(fetd-i0ac89949 fetd-i9197dd74))
    end

  end

end
