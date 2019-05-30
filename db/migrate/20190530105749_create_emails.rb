class CreateEmails < ActiveRecord::Migration[5.2]
  def change
    create_table :emails do |t|
      t.string :message_id
      t.string :subject
      t.text :body
      t.string :from
      t.datetime :date

      t.timestamps
    end
    add_index :emails, :message_id
  end
end
