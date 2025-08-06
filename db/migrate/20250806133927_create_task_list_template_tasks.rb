class CreateTaskListTemplateTasks < ActiveRecord::Migration[8.0]
  def change
    create_table :task_list_template_tasks do |t|
      t.string :name
      t.text :description
      t.references :task_list_template, null: false, foreign_key: true

      t.timestamps
    end
  end
end
