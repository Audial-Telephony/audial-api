module Dialer
  class App < Rack::Cascade
    def initialize
      # super [ Dailer::V2, Dialer::V1 ]
      super [Dialer::V1]
      
      StatusNotificationWorker.perform_async

    end
  end
end
