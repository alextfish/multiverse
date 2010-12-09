// Place your application-specific JavaScript functions and classes here
// This file is automatically included by javascript_include_tag :defaults

function update_frame() {
  cardframe = $("card_frame").value;
    //if( cardframe != "Auto" ) {
    //  newClass = cardframe;
    //} else {
    // else: autocalculate frame
    cost = $("card_cost").value;
    cardtype = $("card_cardtype").value;
    colours = [
      (cost.search(/w/i)>-1 ? "White" : ""),
      (cost.search(/u/i)>-1 ? "Blue" : ""),
      (cost.search(/b/i)>-1 ? "Black" : ""),
      (cost.search(/r/i)>-1 ? "Red" : ""),
      (cost.search(/g/i)>-1 ? "Green" : "")
    ];
    num_colours = 0;
    for( i=0; i<5; i++ ) {
      if ( colours[i] != "") num_colours++;
    }
    outer = cardtype.search(/Artifact/)>-1 ? "Coloured_Artifact " : "";
    if (cardframe != "Auto") {
      inner = cardframe;
    } else {
      // calculate frame
      switch ( num_colours ) {
        case 1: inner = colours.join(""); break;
        case 0: inner = ( cardtype.search(/Land/)>-1 ? "Land" : cardtype.search(/Artifact/)>-1 ? "Artifact" : "Colourless" ); break;
        case 3: case 4: case 5: inner = "Multicolour"; break;
        case 2: inner = (cost.search(/[({].{2,}[)}]/)>-1 ? "Hybrid" : "Multicolour"); break;
        // this case 2 is buggy for Twinclaws cases, but meh
      }
    }
    if ( num_colours == 2) {
      pinline = " " + colours.join("").toLowerCase();
    } else {
      pinline = "";
    }
    newClass = outer + inner + pinline;
  //}
  $("card").className = "card " + newClass;
}

function update_card_rarity(new_rarity) {
  cell = document.getElementById("raritycell");
  //cell.className = "cardrarity " + new_rarity.toLowerCase();
  cell.className = new_rarity.toLowerCase();
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
      highlightform.style.display = "inline";
      unhighlightform.style.display = "none";
      addressform.style.display = "none";
      unaddressform.style.display = "inline";
      break;
    case 1: // "unaddress":
      commentdiv.className = "comment unaddressed";
      highlightform.style.display = "inline";
      unhighlightform.style.display = "none";
      addressform.style.display = "inline";
      unaddressform.style.display = "none";
      break;
    case 2: //  "highlight":
      commentdiv.className = "comment highlighted";
      highlightform.style.display = "none";
      unhighlightform.style.display = "inline";
      addressform.style.display = "none";
      unaddressform.style.display = "inline";
      break;
  }
}
