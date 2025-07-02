class AddPasswordAndPasswordDigestToUsers < ActiveRecord::Migration[8.0]
  def change
    add_column :users, :password_digest, :string, null: false
  end
end
