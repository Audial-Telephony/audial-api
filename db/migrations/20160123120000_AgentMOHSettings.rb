Sequel.migration do
	change do
		add_column :settings, :agent_moh, String, default: 'moh'

	end
end