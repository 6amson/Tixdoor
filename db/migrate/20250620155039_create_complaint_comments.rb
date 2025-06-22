class CreateComplaintComments < ActiveRecord::Migration[7.2]
    def change
    create_table :complaint_comments do |t|
      t.references :complaint, null: false, foreign_key: true
      t.string :user_type, null: false
      t.text :comment, null: false
      t.timestamps
    end

    add_index :complaint_comments, :user_type
  end
end
