// Stimulus controller for the "Insert Image" > "Upload new" tab in the
// article/news WYSIWYG editor's image picker (see
// app/views/admin/image_ids/_upload_form.html.haml). The upload form submits
// inside a <turbo-frame>, so Turbo handles the multipart file upload via
// fetch/FormData - jquery-ujs can't do this (it falls back to a normal
// full-page submit for any remote form with a file input).
//
// On a successful upload, Admin::ImagesController#create re-renders the
// frame with a fresh (blank) form plus this controller attached, carrying
// the new image's id/caption as values. connect() then fires the same
// callback the search tab's results use, to insert the [IMG:id] token and
// close the modal.
class ImageUploadController extends Controller {
  static values = { id: Number, caption: String }

  connect() {
    if (this.hasIdValue) {
      image_ids_callback(this.idValue, this.captionValue);
    }
  }
}
