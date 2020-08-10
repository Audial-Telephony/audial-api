Sequel.migration do
	change do
		add_column :cdr, :end_code, Integer
	end
end