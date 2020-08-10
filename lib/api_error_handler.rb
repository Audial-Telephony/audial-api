# trap all exceptions and fail gracefuly with a 500 and a proper message
class ApiErrorHandler < Grape::Middleware::Base

	def call!(env)
		@env = env
		begin
			@app.call(@env)
		rescue Exception => e
			throw :error, :message => e.message || options[:default_message], :status => 500
		end
	end  

end

# rescue_from :all do |e|
#       # Log it
#       Rails.logger.error "#{e.message}\n\n#{e.backtrace.join("\n")}"

#       # Notify external service of the error
#       Airbrake.notify(e)

#       # Send error and backtrace down to the client in the response body (only for internal/testing purposes of course)
#       Rack::Response.new({ message: e.message, backtrace: e.backtrace }, 500, { 'Content-type' => 'application/json' }).finish
#     end