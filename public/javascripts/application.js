// Place your application-specific JavaScript functions and classes here
// This file is automatically included by javascript_include_tag :defaults

function update_card_rarity(new_rarity) {
  cell = document.getElementById("raritycell");
  cell.className = "cardrarity " + new_rarity.toLowerCase();
}

function update_details_pages(new_text) {
  $( "details_pages" ).update(new_text);
}

function update_comment_status(commentid, action) {
  // Find the whole row to set the style
  commentdiv = document.getElementById("comment_" + commentid);
  // Find the buttons to show the right ones
  addressform     = document.getElementById("address_comment_" + commentid);
  unaddressform   = document.getElementById("unaddress_comment_" + commentid);
  highlightform   = document.getElementById("highlight_comment_" + commentid);
  unhighlightform = document.getElementById("unhighlight_comment_" + commentid);
  switch (action) {
    case 0:  //  "address":   case "unhighlight":
      commentdiv.className = "comment normal";
      addressform.style.display = "none";
      unhighlightform.style.display = "none";
      unaddressform.style.display = "inline";
      highlightform.style.display = "inline";
      break;
    case 1: // "unaddress":
      commentdiv.className = "comment unaddressed";
      unaddressform.style.display = "none";
      addressform.style.display = "inline";
      highlightform.style.display = "none";
      unhighlightform.style.display = "none";
      break;
    case 2: //  "highlight":
      commentdiv.className = "comment highlighted";
      highlightform.style.display = "none";
      unhighlightform.style.display = "inline";
      addressform.style.display = "none";
      unaddressform.style.display = "none";
      break;
  }
}
