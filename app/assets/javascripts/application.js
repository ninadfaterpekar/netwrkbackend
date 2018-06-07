// This is a manifest file that'll be compiled into application.js, which will include all the files
// listed below.
//
// Any JavaScript/Coffee file within this directory, lib/assets/javascripts, vendor/assets/javascripts,
// or any plugin's vendor/assets/javascripts directory can be referenced here using a relative path.
//
// It's not advisable to add code directly here, but if you do, it'll appear at the bottom of the
// compiled file. JavaScript code in this file should be added after the last require_* statement.
//
// Read Sprockets README (https://github.com/rails/sprockets#sprockets-directives) for details
// about supported directives.
//
//= require jquery
//= require jquery_ujs
//= require twitter/bootstrap
//= require ckeditor/init
//= require_tree .

function toggleContainer(container) {
  if (container) {
    if (container.is(':visible')) container.stop().fadeOut('fast');
    else container.stop().fadeIn('fast');
  } else console.error('No container provided to toggle');
}

$(document).ready(function() {
  var storiesEl = $('#stories');
  $('button[name="stories"]').on('click', function(){
    toggleContainer(storiesEl);
  });
  $('.run_contactModal').on('click', function(ev){
    ev.preventDefault();
    setTimeout(function() {
      $('#modal-contact').modal();
    }, 1);

  });
  $('.run_download').on('click', function(ev){
    ev.preventDefault();
    setTimeout(function() {
      $('#modal-download').modal();
    }, 1);

  });
});
