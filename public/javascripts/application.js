// Place your application-specific JavaScript functions and classes here
// This file is automatically included by javascript_include_tag :defaults

function toggle_frame_letter(letter_elem) {
  if (letter_elem.className.search(/code_shown/) > -1) {
    letter_elem.className = letter_elem.className.replace(/code_shown/, "code_not_shown");
    $$(".code_frame_" + letter_elem.innerHTML).invoke("hide");
    letter_elem.show();
  } else {
    letter_elem.className = letter_elem.className.replace(/code_not_shown/, "code_shown");
    $$(".code_frame_" + letter_elem.innerHTML).invoke("show");
  }
}
function toggle_rarity_letter(letter_elem) {
  if (letter_elem.className.search(/code_shown/) > -1) {
    letter_elem.className = letter_elem.className.replace(/code_shown/, "code_not_shown");
    $$(".code_rarity_" + letter_elem.innerHTML).invoke("hide");
  } else {
    letter_elem.className = letter_elem.className.replace(/code_not_shown/, "code_shown");
    $$(".code_rarity_" + letter_elem.innerHTML).invoke("show");
  }
}
function show_skeleton_row(value) {
  $(value + "_row").show(); 
  $("option_" + value).delete(); 
}

function update_card_supertype(new_value) {
  if (new_value == "Custom") {
    $("card_supertype_select").hide();
    $("card_supertype").show();
  } else {
    $("card_supertype").value = new_value;
  }
}
function getIntValue(id) {
  return parseInt($(id).value, 10);
}
function update_generate_totals() {
  var rarities=["commons", "uncommons", "rares", "mythics"];
  var counts={};
  for (count in rarities) {
    this_rarity = rarities[count];
    counts[this_rarity] = getIntValue("artifact_"+this_rarity) + getIntValue("land_"+this_rarity) +
      5*getIntValue("white_"+this_rarity) + 5*getIntValue("allygold_"+this_rarity) +
      5*getIntValue("enemygold_"+this_rarity) + 5*getIntValue("allyhybrid_"+this_rarity) +
      5*getIntValue("enemyhybrid_"+this_rarity);
  }
  total = commons + uncommons + rares + mythics
  $("generate_total").innerHTML = total
  $("generate_commons").innerHTML = commons
  //etc
}

function update_frame() {
  cardframe = $("card_frame").value;
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
      case 2: inner = (cost.search(/[({][^)}]{2,}[)}]/)>-1 ? "Hybrid" : "Multicolour"); break;
      // this case 2 is buggy for Twinclaws cases, but meh
    }
  }
  if ( num_colours == 2) {
    pinline = " " + colours.join("").toLowerCase();
  } else {
    pinline = "";
  }
  newClass = outer + inner + pinline;

  universalClass = "form card ";
  if ($("card").className.search(/token/) > -1) { universalClass += "token "; }
  $("card").className = universalClass + newClass;
}

function update_card_rarity(rarity_in) {
  new_rarity = rarity_in.toLowerCase();
  $("raritycell").className = "cardrarity " + new_rarity;
  if (new_rarity == "token") {
    if ($("card").className.search(/token/) == -1) {
      $("card").className += " token";
    }
  } else {
    $("card").className = $("card").className.replace(/ token/,"");
  }
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

/*

// H/M * JS to fit the card text to the card.
// Pseudocode:
  // on load: resize_all_cards
  // resize_all_cards: 
    // cards_to_resize = $("#card")
    // remove forms
    // resize_cards
  // resize_cards:
    // for each card in cards_to_resize
      // keep = false
      // check size of text box
      // if it's bigger than it should be:
        // if there are any steps it can go further:
          // shrink it one step
          // keep = true
      // check size of the type line
      // if it's bigger than it should be:
        // if there are any steps it can go further:
          // shrink it one step
          // keep = true
      // if !keep:
        // remove card from cards_to_resize
    // // once all cards resized
    // if any left in cards_to_resize:
      // setTimeout 50, resize_cards
      */
