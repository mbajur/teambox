import Sortable from "@stimulus-components/sortable"
import { patch } from "@rails/request.js"

export default class extends Sortable {
  async onUpdate({ item, newIndex }) {
    if (!item.dataset.tasksSortableUpdateUrl) return

    const param = this.resourceNameValue ? `${this.resourceNameValue}[${this.paramNameValue}]` : this.paramNameValue
    const data = new FormData()

    let allTasks = this.element.querySelectorAll('.task'),
        allTasksCount = allTasks.length,
        before = null,
        after = null

    if (newIndex + 1 >= allTasksCount) {
      after = allTasks[newIndex - 1].dataset.taskId
      data.append(`${param}[after]`, after)
    } else {
      before = allTasks[newIndex + 1].dataset.taskId
      data.append(`${param}[before]`, before)
    }

    return await patch(item.dataset.tasksSortableUpdateUrl, { body: data, responseKind: this.responseKindValue })
  }

  async onEnd({ to, item, newIndex }) {
    if (!item.dataset.tasksSortableUpdateUrl) return

    const param = this.resourceNameValue ? `${this.resourceNameValue}[${this.paramNameValue}]` : this.paramNameValue
    const data = new FormData()

    data.append(`${this.resourceNameValue}[task_list_id]`, to.dataset.taskListId)

    let allTasks = to.querySelectorAll('.task'),
        allTasksCount = allTasks.length,
        before = null,
        after = null

    if (allTasksCount === 1) {
      data.append(param, 0)
    } else if (newIndex + 1 >= allTasksCount) {
      after = allTasks[newIndex - 1].dataset.taskId
      data.append(`${param}[after]`, after)
    } else {
      before = allTasks[newIndex + 1].dataset.taskId
      data.append(`${param}[before]`, before)
    }

    return await patch(item.dataset.tasksSortableUpdateUrl, { body: data, responseKind: this.responseKindValue })
  }

  get defaultOptions() {
    return {
      group: 'tasks',
      onEnd: this.onEnd.bind(this)
    }
  }
}
