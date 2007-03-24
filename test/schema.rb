ActiveRecord::Schema.define(:version => 0) do
	create_table :pages, :force => true do |t|
		t.column "parent_id", :int
    t.column "title", :string, :null => false
    t.column "url_slug", :string, :null => false
	end
end