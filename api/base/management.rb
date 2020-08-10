module Dialer
  class Management < Grape::API

    helpers do
      def logger
        Management.logger
      end
    end

    get 'core/restart' do
      ret = `sudo /etc/init.d/dialer restart`
      logger.info "Dialer restart requested: #{ret}"
    end

    get 'core/stop' do
      ret = `sudo /etc/init.d/dialer stop`
      logger.info "Dialer stop requested: #{ret}"
    end

    get 'core/start' do
      ret = `sudo /etc/init.d/dialer start`
      logger.info "Dialer start requested: #{ret}"
    end
    
  end
end
