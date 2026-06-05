module NotesHelper
  def note_fields(f)
    render "notes/fields", f: f
  end
end
