class Settings < Sequel::Model(:settings)
	plugin :instance_hooks
	plugin :validation_helpers
	one_to_one :campaign

	def validate
		super
		validates_presence [:outbound_call_id],:message=>'outbound_call_id is mandatory !'
		validates_includes (1..10), :dial_aggression,:message =>'Must be between 1 and 10' if !dial_aggression.blank?
		validates_includes (1..255), :max_attempts,:message =>'Must be between 1 and 255' if !max_attempts.blank?
		validates_includes [true,false], :dial_from_self,:message =>'Must be true or false'  if !dial_from_self.blank?
		end

end
