var COMMENT_DEBUG = false;
function logger(log) {
  if (COMMENT_DEBUG) {
    console.log(log);
  }
}

localStorage.clear();
logger("Code for Gene Comment is loaded");
var geid = $('#gene_stable_id').attr('data-value');
var isCmtAdm = $('#comment-admin-page-id').length;


$('#cm9012').click(function() {
  logger("Submit button is clicked. Going to make AJAX!!" + geid);
  var species = window.location.pathname.split('/')[1];
  var content = lineBreakFormat($('.content_input').val());
    $.post(window.location.origin + "/Multi/Account/Comment/Add",
    {
        cmt: content,
        geid: geid,
        spec: species
    },
    function(data, status, xhr){
        //alert("Data: " + data + "\nStatus: " + status);
        if (xhr.status==200 && data.saved) {
          alert("Comment added");
        } else {
          alert("There is an error adding your comment");
        }
        $('.content_input').val("");
        fetch_comment();
    });
});


function fetch_comment() {
  $.get(window.location.origin + "/Multi/Account/Comment/Get",
  {
    geid: geid
  },
  function(data, status, xhr){
    if (xhr.status != 200) return;
    $('#cmt_section1').empty();
    for (var i=0; i<data.length; i++) {
      var item = data[i];            
      $('#cmt_section1').append(comment_box(item.user, item.timestamp, item.comment_data, item.uuid, item.isEditable, item.wasEdited));
    }
    updateCount(data.length);
  });
}

function updateCount(count) {
  var text = '\uD83C\uDD95 User Comments (' + count + ')';
  $("#page_nav [title*='User Comment']").text(text);
  $(".nav-heading h1.caption").text(text);
}

function lineBreakFormat(message){
  return message.replace(/\r?\n/g,"<br>");
}

function reFormat(message) {
  var mymessage = message.replace(/<b>/g, 'TAG0001').replace(/<\/b>/g, 'TAGC0001')
                          .replace(/<i>/g, 'TAG0002').replace(/<\/i>/g, 'TAGC0002')
                          .replace(/<br>/g, 'TAG0003')
                          .replace(/(&nbsp;|<([^>]+)>)/ig, "")
                          .replace(/TAG0001/g, '<b>').replace(/TAGC0001/g, '</b>')
                          .replace(/TAG0002/g, '<i>').replace(/TAGC0002/g, '</i>')
                          .replace(/TAG0003/g, '<br>')
                          ;
  logger(mymessage);
  return mymessage;
}

function comment_box(author, timestamp, message, uuid, isManagable, wasEdited) {
  var content = $("<div/>").addClass("contentbox");
  var header = $("<div/>").addClass("header");
  var author = $("<div/>").addClass("author").text(author);
  var date_txt = (wasEdited == 'false') ? "Posted on " + timestamp : "Posted on " + timestamp + " (edited)";
  var date = $("<div/>").addClass("date").text(date_txt);
  var message = $("<p/>").html(reFormat(message));
  var ctr_buttons = $("<div/>").addClass("buttons ctr-buttons").append(
        $("<button/>").addClass("editbtn").attr("data-value", uuid).text("Edit")
      ).append("&nbsp;").append(
        $("<button/>").addClass("delbtn").attr("data-value", uuid).text("Delete")
      );
      // .append('<button data-value="${comment_id}">Edit</button>&nbsp;<button data-value="${comment_id}">Delete</button>');
  var edt_buttons = $("<div/>").addClass("buttons edt-buttons hidebuttons").append(
        $("<button/>").addClass("savebtn").attr("data-value", uuid).text("Save")
      ).append("&nbsp;").append(
        $("<button/>").addClass("cancelbtn").attr("data-value", uuid).text("Cancel")
      );

  $(header).append(author).append(date);
  var result = $(content).append(header).append(message);

  if (isManagable == 'true') {
    result = result.append(ctr_buttons).append(edt_buttons);
  }

  return $(result);
}

if (geid) fetch_comment();

$('#commentbox').on('click', '.editbtn', function(){
    var message_id = $(this).attr('data-value');
    logger("Editing comment: " + $(this).attr('data-value'));
    //localStorage.setItem("prev" + message_id, $(this).parent().siblings('p').text());
    localStorage.setItem("prev" + message_id, $(this).parent().siblings('p').html());
    //Need to show html back to editable box
    $(this).parent().siblings('p').text($(this).parent().siblings('p').html());
    $(this).parent().siblings('p').attr('contenteditable', true).focus();
    $(this).parent().addClass('hidebuttons');
    $(this).parent().siblings('.edt-buttons').removeClass('hidebuttons');
});

$('#commentbox').on('click', '.cancelbtn', function(){
    var message_id = $(this).attr('data-value');
    $(this).parent().siblings('p').attr('contenteditable', false);
    $(this).parent().addClass('hidebuttons');
    $(this).parent().siblings('.ctr-buttons').removeClass('hidebuttons');
    // $(this).parent().siblings('p').text(localStorage.getItem("prev" + message_id));
    $(this).parent().siblings('p').html(localStorage.getItem("prev" + message_id));
});

$('#commentbox').on('click', '.delbtn', function(){
  var contentParent = $(this).parents('.contentbox').addClass('highlight');
  var message_id = $(this).attr('data-value');
  //To avoid instant confirm box rendering
  setTimeout(function() {
      logger("Delete" + message_id);
      var result = confirm("Do you want to delete this comment?");
      if (!result) {
        contentParent.removeClass('highlight');
        return;
      }
      delete_comment(message_id);
    }, 30);
});

$('#commentbox').on('click', '.savebtn', function(){
  var message_id = $(this).attr('data-value');
  var message = $(this).parent().siblings('p').text();
  logger(message);
  update_comment(message_id, message);

});

function delete_comment(message_id){
  $.post(window.location.origin + "/Multi/Account/Comment/Delete",
  {
    uuid: message_id
  },
  function(data, status, xhr){
    logger(data);
    if (xhr.status==200 && data.deleted) {
      logger("Successfully deleted");
      reload();
    } else {
      alert("Error deleting the comment" + message_id);
    }
  })
}

function update_comment(message_id, message){
  $.post(window.location.origin + "/Multi/Account/Comment/Update",
  {
    uuid: message_id,
    cmt: message
  },
  function(data, status, xhr){
    logger(data);
    if (xhr.status==200 && data.updated) {
      alert("Successfully updated");
      reload();
    } else {
      alert("Error updating the comment" + message_id);
    }
  })
}

//Comment Admin Page
if (isCmtAdm) { 
  logger("Admin comment page");
  loadAdminComments();
}

function reload() {
  if (!isCmtAdm) {
    fetch_comment()
  } else {
    //Checking current selection!
    if ($('.adm_active_btn').length > 0) {
      $('.adm_active_btn').click();
    } else {
      loadAdminComments()
    }
  }
}
function loadAdminComments(from, limit) {
  var endpoint = window.location.origin + "/Multi/Account/Comment/Admin";
  if (from)  {
    endpoint += "?from=" + from;
  } else if (limit) {
    endpoint += "?limit=" + limit;
  } else {
    //Default query
     endpoint += "?limit=200";
  }
  
  $.ajax({
    url: endpoint,
    success: function(data){
      logger(data);
      processCommentArray(data);
      var dynatable = $('#comment_table_id').dynatable({
        dataset: {
          records: data
        }
      }).data("dynatable");
      dynatable.settings.dataset.originalRecords = data;
      dynatable.process(); 
    }
  });
}

$('#comment_table_id').on('click', '.admin_delbtn', function(){
  var uuid = $(this).attr('data-value');
  logger("Admin delete button click for uuid" + uuid);
  delete_comment(uuid);
})

//Event listener for buttons on Comment Admin page
function commentAdminButtons() {
  $('.time_query_btn').on('click', function(){
    var period = $(this).attr('id').split('_')[0];
    var from = Math.floor((new Date).getTime()/1000) - period*60*60;
    $('button').removeClass('adm_active_btn');
    $(this).addClass('adm_active_btn').blur();
    loadAdminComments(from);       
  })

  $('.count_query_btn').on('click', function(){
    var count = $(this).attr('id').split('_')[0];
    $('button').removeClass('adm_active_btn');
    $(this).addClass('adm_active_btn').blur();
    loadAdminComments(null, count);        
  })

  $('#comment_admincp_id').on('click', '.admin_editbtn', function(){
    var uuid = $(this).attr('data-value');
    var message = $(this).parent().siblings('td').eq(2).text();
    $(this).parent().siblings('td').eq(2).attr("contenteditable", true).focus();
    $(this).parent().empty().append(
      '<button class="admin_savebtn" data-value="' + uuid + '">✔</button>&nbsp;<button class="admin_cancelbtn" data-value="' + uuid + '">✘</button>'
      );
    localStorage.setItem("adm_prev" + uuid, message);
  })

  $('#comment_admincp_id').on('click', '.admin_savebtn', function(){
    var message_id = $(this).attr('data-value');
    var message = $(this).parent().siblings('td').eq(2).text();
    logger(message);
    update_comment(message_id, message);
  })

  $('#comment_admincp_id').on('click', '.admin_cancelbtn', function(){
    var uuid = $(this).attr('data-value');
    $(this).parent().siblings('td').eq(2).removeAttr("contenteditable");
    $(this).parent().siblings('td').eq(2).text(localStorage.getItem("adm_prev" + uuid));
    $(this).parent().empty().append(
      '<button class="admin_editbtn" data-value="' + uuid + '">Edit</button>')
  })
}

commentAdminButtons();


function processCommentArray(jsonarray) {
  for (i in jsonarray) {
    var uuid = jsonarray[i].uuid;
    jsonarray[i].comment_data = jsonarray[i].comment_data.replace(/&/g,'&amp;').replace(/</g,'&lt;').replace(/>/g,'&gt;');
    jsonarray[i].geneid = '<a href ="/' + jsonarray[i].species + '/Gene/Comment?g=' + jsonarray[i].geneid + '" target="_blank">' + jsonarray[i].geneid + '</a>';
    jsonarray[i].edit_btn = '<button class="admin_editbtn" data-value="' + uuid + '">Edit</button>';
    if (jsonarray[i].wasDeleted == 'false') {
      jsonarray[i].del_btn = '<button class="admin_delbtn" data-value="' + uuid + '">Delete</button>';    
    } else {
      jsonarray[i].del_btn = '<div data-value="' + uuid + '"> N/A </div>';
    }
    
  }
}
