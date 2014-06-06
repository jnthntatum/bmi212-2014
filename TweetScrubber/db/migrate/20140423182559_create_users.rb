class CreateUsers < ActiveRecord::Migration
  def change
    create_table :users do |t|
      t.timestamp
    end
  end
end
