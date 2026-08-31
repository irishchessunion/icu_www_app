$('#image_ids_results').on('click', 'a.image_ids_callback', function(e) {
  e.preventDefault();
  var id = $(this).data('id');
  var caption = $(this).data('caption');
  image_ids_callback(id, caption);
});
