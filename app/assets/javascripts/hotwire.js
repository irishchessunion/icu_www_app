//= require stimulus
//= require image_upload_controller
//= require section_fee_warning_controller
// turbo is included as its own module script (see layout)

Turbo.session.drive = false;

window.Stimulus = Application.start();
window.Stimulus.register("image-upload", ImageUploadController);
window.Stimulus.register("section-fee-warning", SectionFeeWarningController);
