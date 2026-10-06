$(function() {
  function show_section_fee_warning() {
    var section = $('#item_section').val();
    $('.section-fee-warning').each(function() {
      $(this).toggleClass('hidden', $(this).attr('data-section') !== section);
    });
  }
  $('#item_section').on('change', show_section_fee_warning);
  show_section_fee_warning();
});
