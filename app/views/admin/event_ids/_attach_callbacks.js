$('#event_ids_results').on('click', 'a.event_ids_callback', function(e) {
  e.preventDefault();
  var id = $(this).data('id');
  var name = $(this).data('name');
  event_ids_callback(id, name);
});
