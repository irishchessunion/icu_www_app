//= require stimulus
//= require club_meetings_controller
//= require clubs_directory_controller
//= require image_upload_controller
//= require section_fee_warning_controller
//= require show_more_controller
// turbo is included as its own module script (see layout)

Turbo.session.drive = false;

window.Stimulus = Application.start();
window.Stimulus.register("club-meetings", ClubMeetingsController);
window.Stimulus.register("clubs-directory", ClubsDirectoryController);
window.Stimulus.register("image-upload", ImageUploadController);
window.Stimulus.register("section-fee-warning", SectionFeeWarningController);
window.Stimulus.register("show-more", ShowMoreController);
