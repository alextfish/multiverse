// Place your application-specific JavaScript functions and classes here
// This file is automatically included by javascript_include_tag :defaults

function update_card_rarity(new_rarity) {
  cell = document.getElementById("raritycell");
  cell.className = "cardrarity " + new_rarity.toLowerCase();
}

function update_comment_forms(commentid, action) {
  addressform     = document.getElementById("address_comment_" + commentid);
  unaddressform   = document.getElementById("unaddress_comment_" + commentid);
  highlightform   = document.getElementById("highlight_comment_" + commentid);
  unhighlightform = document.getElementById("unhighlight_comment_" + commentid);
  switch (action) {
    case "address":
    case "unhighlight":
      addressform.style.display = "none";
      unhighlightform.style.display = "none";
      unaddressform.style.display = "inline";
      highlightform.style.display = "inline";
      break;
    case "unaddress":
      unaddressform.style.display = "none";
      addressform.style.display = "inline";
      break;
    case "highlight":
      highlightform.style.display = "none";
      unhighlightform.style.display = "inline";
      break;
  }
}
