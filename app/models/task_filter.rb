class TaskFilter
  include SearchObject.module(:model)

  option(:name) do |scope, value|
    scope.where("LOWER(tasks.name) LIKE ?", "%#{value.downcase}%")
  end

  option(:assigned_to) do |scope, value|
    case value
    when "all"
      scope
    when "mine"
      scope.assigned_to(Current.user)
    when "unassigned"
      scope.where(assigned_id: nil)
    else
      scope.assigned_to(User.find(value))
    end
  end

  option(:due_date) do |scope, value|
    case value
    when "all"
      scope
    when "overdue"
      scope.overdue
    when "unassigned_date"
      scope.where(due_on: nil)
    when "due_today"
      scope.due_today
    when "due_tomorrow"
      scope.due_tomorrow
    when "due_week"
      scope.due_week
    when "due_next_week"
      scope.due_next_week
    when "due_2weeks"
      scope.due_in(2.weeks)
    when "due_3weeks"
      scope.due_in(3.weeks)
    when "due_month"
      scope.due_in(1.month)
    else
      scope
    end
  end
end
