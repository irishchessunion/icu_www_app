//= require stimulus
//= require image_upload_controller
// turbo is included as its own module script (see layout)

Turbo.session.drive = false;

window.Stimulus = Application.start();
window.Stimulus.register("image-upload", ImageUploadController);
