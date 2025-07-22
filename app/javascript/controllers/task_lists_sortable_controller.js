import Sortable from "@stimulus-components/sortable"
import { patch } from "@rails/request.js"

export default class extends Sortable {
  async onUpdate({ item, newIndex }) {
    if (!item.dataset.taskListsSortableUpdateUrl) return

    const param = this.resourceNameValue ? `${this.resourceNameValue}[${this.paramNameValue}]` : this.paramNameValue
    const data = new FormData()

    let allTaskLists = this.element.querySelectorAll('.task_list_container'),
        allTaskListsCount = allTaskLists.length,
        before = null,
        after = null

    console.log(allTaskLists, allTaskListsCount, newIndex)
    if (newIndex + 1 >= allTaskListsCount) {
      after = allTaskLists[newIndex - 1].dataset.taskListId
      data.append(`${param}[after]`, after)
    } else {
      before = allTaskLists[newIndex + 1].dataset.taskListId
      data.append(`${param}[before]`, before)
    }

    return await patch(item.dataset.taskListsSortableUpdateUrl, { body: data, responseKind: this.responseKindValue })
  }
}
