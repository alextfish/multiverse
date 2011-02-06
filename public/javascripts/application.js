// Place your application-specific JavaScript functions and classes here
// This file is automatically included by javascript_include_tag :defaults

// Skeletons
// - Skeleton View
function toggle_frame_letter(letter_elem) {
  if (letter_elem.className.search(/code_shown/) > -1) {
    letter_elem.removeClassName("code_shown").addClassName("code_not_shown");
    $$(".code_frame_" + letter_elem.innerHTML).invoke("hide");
    letter_elem.show();
  } else {
    letter_elem.removeClassName("code_not_shown").addClassName("code_shown");
    $$(".code_frame_" + letter_elem.innerHTML).invoke("show");
  }
}
function toggle_rarity_letter(letter_elem) {
  if (letter_elem.className.search(/code_shown/) > -1) {
    letter_elem.removeClassName("code_shown").addClassName("code_not_shown");
    $$(".code_rarity_" + letter_elem.innerHTML).invoke("hide");
  } else {
    letter_elem.removeClassName("code_not_shown").addClassName("code_shown");
    $$(".code_rarity_" + letter_elem.innerHTML).invoke("show");
  }
}
function show_skeleton_row(value) {
  $(value + "_row").show(); 
  $("option_" + value).remove(); 
}
// - Skeleton Generate
function getIntValue(id) {
  parsed = parseInt($(id).value, 10);
  return (isNaN(parsed) ? 0 : parsed);
}
function update_generate_totals() {
  var rarities=["rarityC", "rarityU", "rarityR", "rarityM"];
  var frames=["white", "artifact", "land", "allygold", "enemygold", "allyhybrid", "enemyhybrid"];
  var frame_multiplier={"white":5, "artifact":1, "land":1, "allygold":5, "enemygold":5, "allyhybrid":5, "enemyhybrid":5};
  var counts={};
  var total_count=0;
  frames.each(function(this_frame) {
    counts[this_frame] = 0;
  });
  rarities.each(function(this_rarity) {
    counts[this_rarity] = 0;
    frames.each(function(this_frame) {
      this_count = getIntValue("skeletonform_" + this_frame + "_" + this_rarity) * frame_multiplier[this_frame];
      counts[this_rarity] += this_count;
      counts[this_frame] += this_count;
      total_count += this_count;
    })
  });
  $("grand_total").innerHTML = total_count;
  rarities.each(function(this_count) {
    $("total_" + this_count).innerHTML = counts[this_count];
  });
  frames.each(function(this_count) {
    $("total_" + this_count).innerHTML = counts[this_count];
  });
}

////// Card editing //////

function update_card_supertype(new_value) {
  if (new_value == "Custom") {
    $("card_supertype_select").hide();
    $("card_supertype").show();
  } else {
    $("card_supertype").value = new_value;
  }
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
  outer = "";
  outer += cardtype.search(/Artifact/)>-1 ? "Coloured_Artifact " : "";
  outer += cardtype.search(/Planeswalker/)>-1 ? "Planeswalker " : "";
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

////// Comments //////
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



// H/M * JS to fit the card text to the card.
// Pseudocode:
  // on load: resize_all_cards
  // resize_all_cards: 
    // cards_to_resize = $("#card")
    // remove forms
function shrinkName(nameDiv) {
  titleBarDiv = nameDiv.parentNode;
  manaCostDiv = titleBarDiv.select("div.cardmanacost")[0];
  cardDiv = titleBarDiv.up("div.card");
  if (!cardDiv.hasClassName("token")) {
    // Non-token algorithm:
    defaultNameFontSize = 9; // points, as defined in Card.scss
    nameSizeOK = 0;
    fontSize = defaultNameFontSize;
    // .cardtitlebar, .cardtypebar { font: bold 9pt serif; }
    for(var i=0; !nameSizeOK && i>-3; i-=0.25) { 
      nameDiv.style.letterSpacing = i + "px"; 
      nameSizeOK = (manaCostDiv.offsetTop == nameDiv.offsetTop) && titleBarDiv.clientHeight < 20;
      if (!nameSizeOK) {
        nameDiv.style.fontSize = (defaultNameFontSize + i) + "pt";
        nameSizeOK = (manaCostDiv.offsetTop == nameDiv.offsetTop) && titleBarDiv.clientHeight < 20;
      }
    }
  } else {
    // Token algorithm
    alert('Todo!')
  }
}
function shrinkType(typeDiv) {
  typeSpan = typeDiv.childElements()[0];
  typeBarDiv = typeDiv.parentNode;
  rarityDiv = typeBarDiv.select("div.cardrarity")[0];
  if (!rarityDiv) return;
  typeBarPadding = 9; // calculated from the padding-left and padding-right of cardrarity and .pinline_box>div
  maxWidth = typeBarDiv.getWidth() - rarityDiv.getWidth() - typeBarPadding;
  typeSizeOK = false;
  for(var i=0; !typeSizeOK && i>-3; i-=0.25) { 
    typeSpan.style.letterSpacing = i + "px"; 
    typeSizeOK = (typeBarDiv.getHeight() < 20) && (typeSpan.getWidth() < maxWidth); 
  }
}

function shrinkTextBox(textDiv) {
  //cardDiv = textDiv.up('.card');
  wiggleRoom = 1;
  idealTextBoxHeight = 105;
  currentFontSize = textDiv.getStyles().fontSize;
  currentFontSizeNumber = parseInt(currentFontSize);
  currentFontSizeUnits = currentFontSize.slice(-2); // assumes "px" or "pt"
  textSizeOK = textDiv.getHeight() <= idealTextBoxHeight + wiggleRoom;
  if (textSizeOK) {
    // It started out OK: let's try to centre stuff
  } else {
    // It's stretched: shrink stuff
    for(var i=0; !textSizeOK && i>-5; i-=0.25) { 
      textDiv.style.fontSize = (currentFontSizeNumber + i) + currentFontSizeUnits;
      textSizeOK = textDiv.getHeight() <= idealTextBoxHeight + wiggleRoom;
    }
  }
}

function makeAllCardsFit() {
  $$('div.cardname').each(shrinkName);
  $$('div.cardtype').each(shrinkType);
  $$('div.cardtext').each(shrinkTextBox);
}

Event.observe(window, 'load', makeAllCardsFit);