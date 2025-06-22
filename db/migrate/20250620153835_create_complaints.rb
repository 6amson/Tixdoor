
class CreateComplaints < ActiveRecord::Migration[7.2]
  def change
    create_table :complaints do |t|
      t.string :complaint_type, null: false
      t.string :user_id, null: false
      t.text :complain
      t.string :attachment
      t.string :status, null: false, default: 'pending'
      t.timestamps
    end

    add_index :complaints, :user_id
    add_index :complaints, :status
    add_index :complaints, :complaint_type
  end
end
