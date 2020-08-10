Sequel.migration do
	change do
		add_column :settings, :amd, TrueClass, default: true

	end
end