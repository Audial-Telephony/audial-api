class Callee < Sequel::Model(:callees)
	plugin :instance_hooks
	plugin :validation_helpers
	
	one_to_many :cdr, class: :CDR
	many_to_one :campaign

  def validate
    super
		#validates_unique :ref
		#validates_numeric :number
    # validates_includes ["pending","complete","dnc"], :status , :message=>'Status invalid !'
   end

	def before_destroy
		super
		after_destroy_hook{REDIS.del "#{self.ref}:numbers"}
	end

	def contact_ref=(ref)
    contact = Callee[ref: ref]
    raise CalleeError.new, "Callee Error: Duplicate Contact Ref[#{ref}]" if contact
		self.ref = ref
	end

	def contact_ref
		self.ref
	end

	def numbers=(args)
		numbers_key = "#{self.ref}:numbers"

		REDIS.multi do
			args.each do |number|
				number.symbolize_keys!

				if number[:n] && !number[:n].empty?

					if number[:p].to_i < 0
						REDIS.zrem numbers_key, number[:n]
					else
						REDIS.zadd numbers_key, number[:p], number[:n] 
					end

				end
			end

			REDIS.zrem numbers_key, ""
			# # Remove all the numbers whose priority is -1 (see API spec)
			# REDIS.zremrangebyscore numbers_key, -1, -1
		end	

	end

	def numbers
		numbers_key = "#{self.ref}:numbers"
		REDIS.zrange numbers_key, 0, -1
	end

	def primary_number
		number_at
	end

	def dial_attempts
		count = REDIS.get "#{self.ref}:dial_count"
		unless count
			count = 0
		end
		count.to_i
	end

	def next_number
		number = number_at( dial_attempts % numbers_count ) rescue nil
		REDIS.incr "#{self.ref}:dial_count"
		number
	end

	def numbers_count
		numbers_key = "#{self.ref}:numbers"
		REDIS.zcard numbers_key
	end

	def number_at(idx = 0)
		number = REDIS.zrangebyscore "#{self.ref}:numbers", 0, "+inf", :limit => [idx, 1]
		number.first
	end

	# Add the new callee to the specific campaign
	# TODO: Use Campaign[ref: c_ref] instead of find, see sequel docs
	def campaign_ref=(c_ref)
		parent = Campaign[ref: c_ref]
		raise Sequel::Rollback, "No associated campaign found #{c_ref}" unless parent
		self.campaign_id = parent.id
	end

	def campaign_ref
		Campaign[self.campaign_id].ref
	end

	def self.update_or_create(attrs, set_attrs=nil)
		obj = Callee[attrs] || Callee.new(attrs)
		obj.set(set_attrs).save
		isnew = obj.new?

		return obj, isnew
	end

end
