class DropPostsTable < ActiveRecord::Migration[7.1]
  def change
    drop_table :posts
  end
end