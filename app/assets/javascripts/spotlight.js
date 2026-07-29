$(function() {
  var $countdown = $(".spotlight .countdown[data-spotlight-start]");
  if (!$countdown.length) return;

  var startAt = new Date($countdown.attr("data-spotlight-start")).getTime();
  if (isNaN(startAt)) return;

  var $actions = $(".spotlight .actions.pending");
  var $units = $countdown.find(".units");

  function makeGroup(label, width) {
    var $group = $("<div>", { "class": "group" }).appendTo($units);
    var $digits = $("<div>", { "class": "digits" }).appendTo($group);
    var boxes = [];
    for (var i = 0; i < width; i++) {
      boxes.push($("<span>", { "class": "digit" }).appendTo($digits));
    }
    $("<span>", { "class": "name", text: label }).appendTo($group);
    return boxes;
  }

  function setValue(boxes, value) {
    var str = String(value);
    while (str.length < boxes.length) str = "0" + str;
    $.each(boxes, function(i, box) { box.text(str.charAt(i)); });
  }

  var totalHours = Math.floor((startAt - Date.now()) / 3600000);
  var hours = makeGroup("Hrs", Math.max(2, String(totalHours).length));
  $("<span>", { "class": "sep", text: ":" }).appendTo($units);
  var mins = makeGroup("Mins", 2);

  function tick() {
    var diff = startAt - Date.now();
    if (diff <= 0) {
      $countdown.hide();
      $actions.removeClass("pending");
      return;
    }
    var s = Math.floor(diff / 1000);
    setValue(hours, Math.floor(s / 3600));
    setValue(mins, Math.floor((s % 3600) / 60));
    setTimeout(tick, 1000);
  }

  tick();
});
