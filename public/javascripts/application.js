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
  var parsed = parseInt($(id).value, 10);
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
  var cardframe = $("card_frame").value;
  var cost = $("card_cost").value;
  var cardtype = $("card_cardtype").value;
  var colours = [
    (cost.search(/w/i)>-1 ? "White" : ""),
    (cost.search(/u/i)>-1 ? "Blue" : ""),
    (cost.search(/b/i)>-1 ? "Black" : ""),
    (cost.search(/r/i)>-1 ? "Red" : ""),
    (cost.search(/g/i)>-1 ? "Green" : "")
  ];
  var num_colours = 0;
  for( i=0; i<5; i++ ) {
    if ( colours[i] != "") num_colours++;
  }
  var outer = "";
  outer += cardtype.search(/Artifact/)>-1 ? "Coloured_Artifact " : "";
  outer += cardtype.search(/Planeswalker/)>-1 ? "Planeswalker " : "";
  if (cardframe != "Auto") {
    var inner = cardframe;
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
    var pinline = " " + colours.join("").toLowerCase();
  } else {
    var pinline = "";
  }
  var newClass = outer + inner + pinline;

  var universalClass = "form card ";
  if ($("card").className.search(/token/) > -1) { universalClass += "token "; }
  $("card").className = universalClass + newClass;
}

function update_card_rarity(rarity_in) {
  var new_rarity = rarity_in.toLowerCase();
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
  var commentdiv = document.getElementById("comment_" + commentid);
  // Find the buttons to show the right ones
  var addressform     = document.getElementById("address_comment_" + commentid);
  var unaddressform   = document.getElementById("unaddress_comment_" + commentid);
  var highlightform   = document.getElementById("highlight_comment_" + commentid);
  var unhighlightform = document.getElementById("unhighlight_comment_" + commentid);
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


////// Resizing //////
function shrinkName(nameDiv, typeDiv) {
  var titleBarDiv = nameDiv.parentNode;
  var manaCostDiv = titleBarDiv.select("div.cardmanacost")[0];
  // Non-token algorithm:
  var defaultNameFontSize = 9; // points, as defined in Card.scss
  var nameSizeOK = 0;
  var fontSize = defaultNameFontSize;
  // .cardtitlebar, .cardtypebar { font: bold 9pt serif; }
  for(var i=0; !nameSizeOK && i>-3; i-=0.25) { 
    nameDiv.style.letterSpacing = i + "px"; 
    nameSizeOK = (manaCostDiv.offsetTop == nameDiv.offsetTop) && titleBarDiv.clientHeight <= idealTitleHeight;
    if (!nameSizeOK) {
      nameDiv.style.fontSize = (defaultNameFontSize + i) + "pt";
      nameSizeOK = (manaCostDiv.offsetTop == nameDiv.offsetTop) && titleBarDiv.clientHeight <= idealTitleHeight;
    }
  }
}
function sizeTokenName(nameDiv, typeDiv) {
  // Token algorithm
  var titleBarDiv = nameDiv.parentNode;
  var titlePinline = titleBarDiv.parentNode;
  var tokenNamePadding = 12; // cardtitlebar p-left=3=3; namebox p-left=p-right=2; 2px wiggle room
  var defaultNameFontSize = 9; // points, as defined in Card.scss
  var nameWidth = nameDiv.getWidth();
  var nameSizeOK = (nameWidth + tokenNamePadding < titlePinline.getWidth()) && (titleBarDiv.clientHeight <= idealTitleHeight);
  if (nameSizeOK) {
    titlePinline.style.width = nameWidth + tokenNamePadding + "px";
  } else {
    for(var i=0; !nameSizeOK && i>-3; i-=0.25) { 
      nameDiv.style.letterSpacing = i + "px"; 
      nameSizeOK = (nameWidth + tokenNamePadding < titlePinline.getWidth()) && (titleBarDiv.clientHeight <= idealTitleHeight)
      if (!nameSizeOK) {
        nameDiv.style.fontSize = (defaultNameFontSize + i) + "pt";
        nameSizeOK = (nameWidth + tokenNamePadding < titlePinline.getWidth()) && (titleBarDiv.clientHeight <= idealTitleHeight)
      }
    }
  }
}
function sizeTokenArt(cardDiv, artDiv) {
  // Should come after sizing token name
  var bottomBox = cardDiv.getElementsByClassName("bottombox")[0];
  var artHeight = artDiv.getHeight();
  var bottomHeight = bottomBox.getHeight();
  var cardHeight = cardDiv.getHeight();
  // The art's minHeight is based on its current height, plus or minus whatever
  // the offset of the bottomBox is
  artDiv.style.minHeight = artHeight + cardHeight - (bottomBox.offsetTop + bottomHeight) + "px";
}

function shrinkType(typeDiv) { //, rarityDiv) {
  var typeSpan = typeDiv.childElements()[0];
  var typeBarDiv = typeDiv.parentNode;
  var rarityDiv = typeBarDiv.getElementsByClassName("cardrarity")[0];
  if (!rarityDiv) return;
  var typeBarPadding = 9; // calculated from the padding-left and padding-right of cardrarity and .pinline_box>div
  
  var maxWidth = typeBarDiv.getWidth() - rarityDiv.getWidth() - typeBarPadding;
  var typeSizeOK = false;
  for(var i=0; !typeSizeOK && i>-3; i-=0.25) { 
    typeSpan.style.letterSpacing = i + "px"; 
    typeSizeOK = (typeBarDiv.getHeight() <= idealTypeHeight) && (typeSpan.getWidth() <= maxWidth); 
  }
}

function shrinkTextBox(textDiv, isPlaneswalker) {
  //cardDiv = textDiv.up('.card');
  var wiggleRoom = (isPlaneswalker ? 5 : 0);
  var idealTextBoxHeight = 109;
  var currentFontSize = textDiv.getStyles().fontSize;
  var currentFontSizeNumber = parseInt(currentFontSize);
  var currentFontSizeUnits = currentFontSize.slice(-2); // assumes "px" or "pt"
  var textSizeOK = textDiv.getHeight() <= idealTextBoxHeight + wiggleRoom;
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

function shrinkCardBits(cardDiv) {
  if (cardDiv.getHeight() == 0) {
    // Card is invisible: do nothing
    return
  }
  var nameDiv = cardDiv.getElementsByClassName("cardname")[0];
  var typeDiv = cardDiv.getElementsByClassName("cardtype")[0];
  var rarityDiv = cardDiv.getElementsByClassName("cardrarity")[0];
  
  if (idealTypeHeight < 0) {
    // Oneoff: calculate ideal height of type bar (global variable)
    // defined as this card's type bar if the text size is teenytiny
    var typeBarDiv = typeDiv.parentNode;
    var typeSpan = typeDiv.childElements()[0];
    origLetterSpacing = typeSpan.getStyles().letterSpacing; 
    typeSpan.style.letterSpacing = "-20px"; 
    idealTypeHeight = typeBarDiv.getHeight();
    idealTitleHeight = typeBarDiv.getHeight() + 2;
    typeSpan.style.letterSpacing = origLetterSpacing; 
  }
  
  if (cardDiv.hasClassName("token")) {
    var artDiv = cardDiv.getElementsByClassName("cardart")[0];
    sizeTokenName(nameDiv, typeDiv);
    sizeTokenArt(cardDiv, artDiv);
  } else {
    var isPlaneswalker = cardDiv.hasClassName("Planeswalker")
    var textDiv = cardDiv.getElementsByClassName("cardtext")[0];
    shrinkName(nameDiv, typeDiv);
    shrinkTextBox(textDiv, isPlaneswalker);
  }
  shrinkType(typeDiv, rarityDiv);
}

function makeAllCardsFit() {
  $A(document.getElementsByClassName("card")).each(shrinkCardBits);
  return;
  
  t0 = (new Date()).getTime();
  var names = $A(document.getElementsByClassName("cardname"));
  t05 = (new Date()).getTime();
  names.each(shrinkName);
  t1 = (new Date()).getTime();
  var types = $A(document.getElementsByClassName("cardtype"));
  t15 = (new Date()).getTime();
  //types.each(shrinkType);
  t2 = (new Date()).getTime();
  var texts = $A(document.getElementsByClassName("cardtext"));
  t25 = (new Date()).getTime();
  //texts.each(shrinkTextBox);
  t3 = (new Date()).getTime();
  alert("Names: finding " + (t05-t0) + ", shrinking " + (t1-t05) + ".\n Types: finding " + (t15-t1) + ", shrinking " + (t2-t15) + ".\nTexts: finding " + (t25-t2) + ", shrinking " + (t3-t25));
  // SF on FF: names 1.256, types 3.825, texts 2.119
  // SF on IE: names 74.8, types 85.9, texts 21.6. Finding in each case 0.13.
  // COCA on IE: names .547, types 1.1, texts .391. Finding in each case 0.016.
}

idealTypeHeight = -1;
idealTitleHeight = -1;

Event.observe(window, 'load', makeAllCardsFit);


///// Dates /////
// Functions adapted from the renderDate and renderTime functions on
// http://www.stephenmcintosh.com/puzzle/puzzles.pl
// (with Stephen's permission)

var month_names = new Array("January", "February", "March", "April", "May", "June", "July", "August", "September", "October", "November", "December");

function renderDate(span) {
    //Date Format: 'Y-m-d H:i:s'
    var matches = /(\d+)-(\d+)-(\d+)\ (\d+):(\d+):(\d+)/.exec(span.innerHTML);   
    if (matches) {
        var LocaleDate = new Date();
        LocaleDate.setUTCFullYear(matches[1], matches[2] - 1, matches[3]);
        LocaleDate.setUTCHours(matches[4], matches[5], matches[6], 0);  
        hours   = LocaleDate.getHours() + "";
        minutes = LocaleDate.getMinutes() + "";
        seconds = LocaleDate.getSeconds() + "";
        var date_out = month_names[LocaleDate.getMonth()] + " " + LocaleDate.getDate() + " " + LocaleDate.getFullYear() + ", " + (hours.length == 1 ? "0" : "") + hours + ":" + (minutes.length == 1 ? "0" : "") + minutes + ":" + (seconds.length == 1 ? "0" : "") + seconds;
        span.innerHTML = date_out;
    }
}
function renderAllDatesAndTimes() {
    $$("span.date").each(renderDate);
}
Event.observe(window, 'load', renderAllDatesAndTimes);


///// Preview card images /////
cardTooltipParams = {
  hook: { tip: 'topLeft', mouse: true },
  offset: { x: 14, y: -54 }
};
function createBlackBorderImage(src) {
  div = new Element('div', {'class': 'blackborder wizardsimage'});
  div.appendChild(new Element('img', {'src': src, 'alt': "No card by that name found"}));
  div.appendChild(new Element('br'));
  div.appendChild(document.createTextNode("No card by that name found"));
  return div
}
// Add tooltips for Wizards cards
document.observe('dom:loaded', function() {
  $$('a.wizardscard[name]').each(function(element) {
    new Tip(element, createBlackBorderImage(element.name), cardTooltipParams);
  });
});
// Add tooltips for Multiverse mockups
document.observe('dom:loaded', function() {
  card_tooltips = {} // global hash
  var site_url = /(^.*:\/\/[^\/]+)/.exec(window.location.href)[1];
  var card_link_regex = new RegExp ( "^(" + site_url + ")?/cards\/([0-9]+)($|[#?])");
  $$("a[href]").each( function(link_element){
    if (matches = card_link_regex.exec(link_element.href)) {
      card_id = matches[2];
      tooltip_div = makeTooltipDiv(link_element, card_id);
      link_element.tip = new Tip( link_element, tooltip_div, cardTooltipParams );
      // Store some useful data
      link_element.card_id = card_id;
      link_element.mockup_wrapper = tooltip_div;
      link_element.observe('prototip:shown', function() {
          // "this" is the link_element
          getTooltipContent(this.card_id, this.mockup_wrapper);
      }); 
    }
  });
});
// Function to create a unique wrapper div for each intra-MV link 
function makeTooltipDiv(parent_element, card_id){
  div_id = "card_tooltip_" + card_id;
  while ( $(div_id) ) {
    div_id += "_2"
  }
  // now we have an unused id
  div = new Element("div", {"class": "distinct_mockup_container", "id": div_id});
  div.appendChild(new Element("div", {"class": "cardborder blackborder card_loading"}));
  // $() in the while loop above will only find this if it's added into the DOM somewhere,
  // so we append it to the parent element for now
  parent_element.appendChild(div.hide());
  // store the card id for easy access by the Ajax onSuccess callback
  div.card_id = card_id;
  return div;
}
// Function called when a tooltip is actually shown
function getTooltipContent(card_id, mockup_wrapper){
  card_id_string = ""+card_id;
  render = card_tooltips[card_id_string]; // returns a div object
  if (!render) {
    // We'll go get it via Ajax.
    // First, store a temp div so that we don't send multiple requests in case of a shaky mouse
    card_tooltips[card_id_string] = new Element("div", {"class": "request_sent"});
    // Create the Ajax request
    new Ajax.Updater(mockup_wrapper, '/cards/' + card_id_string + '/mockup', {
      method: "get",
      parameters: card_id_string, 
      onComplete: function(transport) {
        mockup_wrapper = transport.request.container.success;
        card_id_string = mockup_wrapper.card_id;
        // Store this One True Mockup of this card in the global array
        card_tooltips[card_id_string] = mockup_wrapper.firstElementChild;
        // Shrink the bits appropriately
        cardDiv = mockup_wrapper.down("div.card");
        shrinkTooltipCardBits(cardDiv);
      }
    });
  } else {
    if (!render.hasClassName("request_sent")) {
      // Get rid of any "card loading" divs, and move the proper one here
      mockup_wrapper.select("div.card_loading").invoke("remove");
      mockup_wrapper.appendChild(render);
    }
  }
}

function shrinkTooltipCardBits(cardDiv) {
  tooltip = cardDiv.up("div.prototip");
  wasVisible = tooltip.visible();
  tooltip.show();
  shrinkCardBits(cardDiv);
  if (!wasVisible) {
    tooltip.hide();
  }
}