// Multiverse JavaScript functions and classes here
// This file is automatically included by javascript_include_tag :defaults

// ------------ Constants
C_cardHeightMinusPadding = 300 - 4 - 3; // card height minus top and bottom padding
C_tokenNamePadding = 12; // cardtitlebar p-left=p-right=3; namebox p-left=p-right=2; 2px wiggle room
C_defaultNameFontSize = 9; // points, as defined in Card.scss
C_idealFlipTextBoxHeight = 40+2+2;
C_idealSplitTextBoxHeight = 65+2+2;
C_idealPlaneTextBoxHeight = 72;
C_idealSchemeTextBoxHeight = 108;
C_idealTextBoxHeight = 109; // was 99;

// ------------ Skeletons
// - Skeleton View
function toggle_frame_letter(letter) {
  var letter_elems = $$(".frame_" + letter + "_toggle");
  var letter_elem = letter_elems[0];
  if (letter_elem.className.search(/code_shown/) > -1) {
    $$(".code_frame_" + letter_elem.innerHTML).invoke("hide");
    letter_elems.each(function(elem) {
	  elem.removeClassName("code_shown").addClassName("code_not_shown").show();
	});
  } else {
    $$(".code_frame_" + letter_elem.innerHTML).invoke("show");
    letter_elems.each(function(elem) {
	  elem.removeClassName("code_not_shown").addClassName("code_shown").show();
	});
  }
}
function toggle_rarity_letter(letter) {
  var letter_elems = $$(".rarity_" + letter + "_toggle");
  var letter_elem = letter_elems[0];
  if (letter_elem.className.search(/code_shown/) > -1) {
    $$(".code_rarity_" + letter_elem.innerHTML).invoke("hide");
    letter_elems.each(function(elem) {
	  elem.removeClassName("code_shown").addClassName("code_not_shown").show();
	});
  } else {
    $$(".code_rarity_" + letter_elem.innerHTML).invoke("show");
    letter_elems.each(function(elem) {
	  elem.removeClassName("code_not_shown").addClassName("code_shown").show();
	});
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

function update_card_supertype(card_index, new_value) {
  var card_supertype_field = (card_index==1 ? $("card_supertype") : $("card_link_attributes_supertype"));
  if (new_value == "Custom") {
    $("card_supertype_select_" + card_index).hide();
    card_supertype_field.show();
  } else {
    card_supertype_field.value = new_value;
  }
}

function updateWatermarks() {
 $$(".card_watermark_select").each(function(selector){
  var new_watermark = $F(selector);
  var card = selector.up(".card");
  var watermark_field = card.select(".type_field.watermark")[0];
  var watermark_div = card.select(".cardtext_container")[0].select(".watermark")[0];
  if (new_watermark == "CUSTOM") {
    card.select(".card_watermark_select")[0].hide();
    card.select(".watermark_label")[0].innerHTML = "Watermark URL"
    watermark_field.show();
    /* watermark_field.setAttribute("type","url");
    watermark_field.setAttribute("inputmode","url lowerCase");*/
  } else if (new_watermark == "") {
    watermark_field.value = new_watermark;
    watermark_div.style.backgroundImage = "none";
  } else {
    watermark_field.value = new_watermark;
    watermark_div.style.backgroundImage = 'url(' + standard_watermark_urls[new_watermark] + ")";
  }
 });
}


var colour_affiliation_regexps = {
    "White": /(\([Ww]\)|\{[Ww]\}|[Pp]lains)/,
    "Blue" : /(\([Uu]\)|\{[Uu]\}|[Ii]sland)/, 
    "Black": /(\([Bb]\)|\{[Bb]\}|[Ss]wamp)/, 
    "Red"  : /(\([Rr]\)|\{[Rr]\}|[Mm]ountain)/, 
    "Green": /(\([Gg]\)|\{[Gg]\}|[Ff]orest)/, 
    "Multicolour": /any colo[u]?r/
}

function update_frame(card_id) {
  // Only applies to editing cards in a form
  var this_card = $(card_id);
  var frame_selector = this_card.select(".frame_selector")[0];
  var outer_frame_selector = $("card_structure_display").value;
  var cardframe = frame_selector.value;
  var cardtype = this_card.select(".type_field.cardtype")[0].value;
  var cardsubtype = this_card.select(".type_field.subtype")[0].value;
  var cardTrueFrameField = this_card.select(".frame_selector_wrapper")[0].select("input[type=hidden]")[0];
  var newClass;
  if (nontraditional_frame(this_card)) {
    // Can skip a lot of the colour-determining code
    newClass = cardframe;
    newTrueFrame = cardframe;
  } else {
    var cost = this_card.select(".cost_field")[0].value;
    var colours = get_cost_colours(this_card);
    var num_colours = 0;
    for( i=0; i<5; i++ ) {
      if ( colours[i] != "") num_colours++;
    }
    var outer = "";
    if (num_colours > 0 && cardtype.search(/Artifact/) >- 1) {
      outer += "Coloured_Artifact ";
    }
    if (isPlaneswalker()) {
      outer += "Planeswalker ";
    }
    if (isToken()) {
      outer += "token ";
    }
    var inner;
    if (cardframe != "Auto") {
      inner = cardframe;
    } else {
      // calculate frame
      switch ( num_colours ) {
        case 1: inner = colours.join(""); break;
        case 3: case 4: case 5: inner = "Multicolour"; break;
        case 2: inner = (cost.search(/[({][^)}]{2,}[)}]/)>-1 ? "Hybrid" : "Multicolour"); break;
        // this case 2 is buggy for Twinclaws cases, but meh
        case 0: if (cardtype.search(/Land/)>-1) {
                  // Detect land colour affiliation
                  var cardtext = this_card.select(".rulestextfield")[0].value;
                  var affiliated_colours = [];
                  ["White", "Blue", "Black", "Red", "Green", "Multicolour"].each(function(this_colour) {
                    if (cardtext.search(colour_affiliation_regexps[this_colour])>-1 || cardsubtype.search(colour_affiliation_regexps[this_colour])>-1 ) {
                      affiliated_colours.push(this_colour);
                    }
                  });
                  switch ( affiliated_colours.length ) {
                    case 0: inner = "Land"; break;
                    case 1: inner = "Land " + affiliated_colours[0].toLowerCase(); break;
                    case 2: inner = "Land " + affiliated_colours.join("").toLowerCase(); break;
                    case 3: case 4: case 5: inner = "Land multicolour"; break;
                  }
                } else { 
                  // Nonland: either Artifact or Colourless
                  inner = ( cardtype.search(/Artifact/)>-1 ? "Artifact" : "Colourless" ); 
                } 
                break;

      }
    }
    if (card_id == "card2" && inner == "Colourless" && cardframe != "Colourless") {
      // get card 1 instead
      inner = $("card").getAttribute("class").replace(/(part1|form |card )/g,"");
    }
    
    var pinline;
    if (num_colours == 2) {
      pinline = " " + colours.join("").toLowerCase();
    } else if (card_id == "card2" && num_colours == 0) {
      var card1_colours = get_cost_colours($("card"));
      pinline = " " + card1_colours.join("").toLowerCase();
    } else {
      pinline = "";
    }
    newClass = outer + inner + pinline;
    newTrueFrame = outer + inner;
  }

  var universalClass = "form card ";
  if (isToken()) { universalClass += "token "; }
  if (this_card.hasClassName("part1")) { universalClass += "part1 "; }
  if (this_card.hasClassName("part2")) { universalClass += "part2 "; }
  this_card.className = universalClass + newClass;
  
  cardTrueFrameField.value = newTrueFrame;
}

function get_colour_indicator(this_card) {
  return (this_card.id == "card" ? this_card.select("#card_colour_indicator")[0] : this_card.select("#card_link_attributes_colour_indicator")[0]);
}

function get_cost_colours(this_card) {
  var cost = this_card.select(".cost_field")[0].value;
  var colours = [
    (cost.search(/w/i)>-1 ? "White" : ""),
    (cost.search(/u/i)>-1 ? "Blue" : ""),
    (cost.search(/b/i)>-1 ? "Black" : ""),
    (cost.search(/r/i)>-1 ? "Red" : ""),
    (cost.search(/g/i)>-1 ? "Green" : "")
  ];
  return colours;
}

function nontraditional_frame(this_card) {
  var actual_card;
  if (this_card.hasClassName("card")) {
    actual_card = this_card.parentElement.parentElement;
  } else {
    actual_card = this_card;
  }
  return (actual_card.hasClassName("scheme") || actual_card.hasClassName("plane") || actual_card.hasClassName("vanguard"));
}

function update_card_rarity(rarity_in) {
  var new_rarity = rarity_in.toLowerCase();
  $$(".raritycell").each(function(this_div) {
    this_div.removeClassName("basic");
    this_div.removeClassName("token");
    this_div.removeClassName("common");
    this_div.removeClassName("uncommon");
    this_div.removeClassName("rare");
    this_div.removeClassName("mythic");
    this_div.addClassName(new_rarity);
  });
  
  if ($("cardborder").hasClassName("split") || $("cardborder").hasClassName("dfc")) {
   $("card_rarity").value = rarity_in;
   $("card_link_attributes_rarity").value = rarity_in;
  }
  // Add or remove token frame if necessary
  updateFrameAndMultipart();
}

function update_details_pages(new_text) {
  $( "details_pages" ).update(new_text);
}


function updateFrameAndMultipart(){
  var new_frame = $("card_structure_display").value;
  var multipartPrefix = "multipart_";
  var form = $$(".form")[0];
  
  if (new_frame.substring(0, multipartPrefix.length) == multipartPrefix) {
    // The new setting is multipart
    // Specify it for the server
    $("card_multipart").value = new_frame.substring(multipartPrefix.length);
    
    // Now apply multipart setting
    if (new_frame == multipartPrefix + MULTIPART_SPLIT1) {
      $("cardborder").addClassName("split");
      $("cardborder").removeClassName("flip").removeClassName("dfc");
      $("card_link_attributes_rarity").value = $("card_rarity").value;
      $("rotate_link").hide();
      $("cardborder").removeClassName("rotated");
      //get_colour_indicator($("card2")).setValue(false);
         // work around Chrome bug
    } else if (new_frame == multipartPrefix + MULTIPART_DFCFRONT) {
      $("cardborder").addClassName("dfc");
      $("cardborder").removeClassName("flip").removeClassName("split");
      $("card_link_attributes_rarity").value = $("card_rarity").value;
      $("rotate_link").hide();
      $("cardborder").removeClassName("rotated");
      //get_colour_indicator($("card2")).setValue(true);
         // work around Chrome bug
    } else if (new_frame == multipartPrefix + MULTIPART_FLIP1) {
      $("cardborder").addClassName("flip");
      $("cardborder").removeClassName("split").removeClassName("dfc");
      $("rotate_link").show();
      //get_colour_indicator($("card2")).setValue(false);
    }
    
  } else {
    // The new setting is not multipart. 
    // Remove multipart classes
    $("cardborder").removeClassName("split").removeClassName("flip").removeClassName("dfc");
    $("rotate_link").hide();
    $("cardborder").removeClassName("rotated");
    // and specify not multipart
    $("card_multipart").value = MULTIPART_STANDALONE;
  }
  
  // Remove scheme/plane/vanguard classes - we'll add them back later if necessary
  var wasNontrad = form.hasClassName("scheme") || form.hasClassName("plane") || form.hasClassName("vanguard");
  form.removeClassName("scheme").removeClassName("plane").removeClassName("vanguard");
   
  var frame_hidden = $("card_frame");
  var frame_select = $("card_frame_display");
  if (new_frame == "Scheme" || new_frame == "Plane" || new_frame == "Vanguard") {
    // Move to a nontraditional frame
    var newFrameCap = new_frame;
    var newFrameLower = newFrameCap.toLowerCase();
    $$(".form")[0].addClassName(newFrameLower);
    // The frame selector hides by virtue of having the CSS class plane/scheme/vanguard
    frame_hidden.value = newFrameCap;
  } else if (wasNontrad) {
    // Back to a traditional frame
    //frame_select.value = "Auto";
  }
  update_frame("card");
 
  // Recalculate trad-frame special classes (token, planeswalker)
  
  if (isPlaneswalker()) {
    $$(".card").each(function(card) {
      card.addClassName("Planeswalker");
    });
  } else {
    $$(".card").each(function(card) {
      card.removeClassName("Planeswalker");
    });
  };
  if (isToken()) {
    $$(".card").each(function(card) {
      card.addClassName("token");
    });
  } else {
    $$(".card").each(function(card) {
      card.removeClassName("token");
    });
  };
}

function isPlaneswalker() {
  // Only applies to card edit form
  var new_frame = $("card_structure_display").value;
  var cardtype = $("card").select(".type_field.cardtype")[0].value;
  return (new_frame == "Planeswalker" || cardtype.search(/Planeswalker/)>-1);
}
function isToken() {
  // Only applies to card edit form
  var new_frame = $("card_structure_display").value;
  var cardrarity = $("card_rarity").value;
  return (new_frame == "Token" || cardrarity == "token");
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
  var nameSizeOK = 0;
  var fontSize = C_defaultNameFontSize;
  // .cardtitlebar, .cardtypebar { font: bold 9pt serif; }
  for(var i=0; !nameSizeOK && i>-3; i-=0.25) {
    nameDiv.style.letterSpacing = i + "px";
    nameSizeOK = (manaCostDiv.offsetTop == nameDiv.offsetTop) && titleBarDiv.clientHeight <= idealTitleHeight;
    if (!nameSizeOK) {
      nameDiv.style.fontSize = (C_defaultNameFontSize + i) + "pt";
      nameSizeOK = (manaCostDiv.offsetTop == nameDiv.offsetTop) && titleBarDiv.clientHeight <= idealTitleHeight;
    }
  }
}
function sizeTokenName(nameDiv, typeDiv) {
  // Token algorithm
  var titleBarDiv = nameDiv.parentNode;
  var titlePinline = titleBarDiv.parentNode;
  var nameWidth = nameDiv.getWidth();
  var nameSizeOK = (nameWidth + C_tokenNamePadding < titlePinline.getWidth()) && (titleBarDiv.clientHeight <= idealTitleHeight);
  if (nameSizeOK) {
    // titlePinline.style.width = nameWidth + C_tokenNamePadding + "px";
  } else {
    // Only go down to -2
    for(var i=0; !nameSizeOK && i>-2; i-=0.25) {
      nameDiv.style.letterSpacing = i + "px";
      nameSizeOK = (nameWidth + C_tokenNamePadding < titlePinline.getWidth()) && (titleBarDiv.clientHeight <= idealTitleHeight)
      if (!nameSizeOK) {
        nameDiv.style.fontSize = (C_defaultNameFontSize + i) + "pt";
        nameSizeOK = (nameWidth + C_tokenNamePadding < titlePinline.getWidth()) && (titleBarDiv.clientHeight <= idealTitleHeight)
      }
    }
  }
}
function sizeTokenArt(cardDiv, artDiv) {
  // Should come after sizing token name
  var bottomBox = cardDiv.getElementsByClassName("bottombox")[0];
  var artHeight = artDiv.getHeight();
  var bottomHeight = bottomBox.getHeight();
  // The art's minHeight is based on its current height, plus or minus whatever
  // the offset of the bottomBox is
  artDiv.style.minHeight = artHeight + C_cardHeightMinusPadding - (bottomBox.offsetTop + bottomHeight) + "px";
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

function shrinkTextBox(textDiv, frameType) {
  var wiggleRoom = (frameType=="planeswalker" ? 5 : 0);
  var desiredHeight = (frameType == "normal" ? C_idealTextBoxHeight : frameType=="flip" ? C_idealFlipTextBoxHeight : frameType=="split" ? C_idealSplitTextBoxHeight : frameType=="plane" ?  C_idealPlaneTextBoxHeight : frameType=="scheme" ?  C_idealSchemeTextBoxHeight :  C_idealTextBoxHeight );
  var currentFontSize = textDiv.getStyle("fontSize");
  var currentFontSizeNumber = parseInt(currentFontSize);
  var currentFontSizeUnits = currentFontSize.slice(-2); // assumes "px" or "pt"
  var textSizeOK = textDiv.getHeight() <= desiredHeight + wiggleRoom;
  if (textSizeOK) {
    // It started out OK: let's try to centre stuff
  } else {
    // It's stretched: shrink stuff
    for(var i=0; !textSizeOK && i>-5; i-=0.25) {
      textDiv.style.fontSize = (currentFontSizeNumber + i) + currentFontSizeUnits;
      textSizeOK = textDiv.getHeight() <= desiredHeight + wiggleRoom;
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
    origLetterSpacing = typeSpan.getStyle("letterSpacing");
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
    var frameType;
    var cardOuterFrame = cardDiv.parentNode.parentNode;
    if (cardDiv.hasClassName("Planeswalker")) {
      frameType = "planeswalker";
    } else if (cardOuterFrame.hasClassName("flip")) {
      frameType = "flip";
    } else if (cardOuterFrame.hasClassName("split")) {
      frameType = "split";
    } else if (cardOuterFrame.hasClassName("scheme")) {
      frameType = "scheme";
    } else if (cardOuterFrame.hasClassName("plane")) {
      frameType = "plane";
    } else {
      frameType = "normal";
    }
    var textDiv = cardDiv.getElementsByClassName("cardtext")[0];
    if (frameType != "plane" && frameType != "scheme") {
      shrinkName(nameDiv, typeDiv);
      shrinkTextBox(textDiv, frameType);
    }
  }
  shrinkType(typeDiv, rarityDiv);
}

function makeAllCardsFit() {
  // Don't try to shrink form cards! 
  $A(document.getElementsByClassName("card")).filter(function(elm){return !elm.hasClassName("form")}).each(shrinkCardBits);
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
  // Read the date in UTC
  var date = moment.utc(span.innerHTML, 'YYYY-MM-DD hh:mm:ss');
  if (!date.isValid()) { 
    // We can't do anything here
    return; 
  }
  if (span.hasClassName("relative")) {
    // Render relatively
    span.innerHTML = date.fromNow();
  } else {
    // Render in absolute (but friendly) local time
    date.local(); // switch the date object to local time
    // span.innerHTML = date.format('MMMM Do YYYY, h:mm:ss a');
    span.innerHTML = date.format('MMMM Do YYYY, H:mm:ss');
  }
}
function renderAllDatesAndTimes() {
    $$("span.date").each(renderDate);
}
Event.observe(window, 'load', renderAllDatesAndTimes);


///// Preview card images /////
cardTooltipParamsLeft = {
  hook: { target: 'topLeft', tip: 'rightMiddle' }, 
  offset: { x: 0, y: 0 },
  hideOn: false,
  hideAfter: 0.15
};
cardTooltipParamsRight = {
  hook: { target: 'topRight', tip: 'leftMiddle' },
  hideOn: false,
  hideAfter: 0.15
};
// hook: { 'topLeft', mouse: true },
//offset: { x: 14, y: -54 }
function createWizardsCardImage(src) {
  div = new Element('div', {'class': 'wizardsimage'});
  div.appendChild(new Element('img', {'src': src, 'alt': "No card by that name found"}));
  //div.appendChild(new Element('br'));
  //div.appendChild(new Element('br'));
  //div.appendChild(document.createTextNode("No card by that name found"));
  return div
}
// Add tooltips for Wizards cards
document.observe('dom:loaded', function() {
  $$('a.wizardscard[name]').each(function(element) {
    new Tip(element, createWizardsCardImage(element.name), chooseTooltipParams(element));
  });
});
function chooseTooltipParams(element) {
  var requiredOffset;
  if (element.hasClassName("dfc") || element.hasClassName("plane")) {
    requiredOffset = 450;
  } else if (element.hasClassName("split") || element.hasClassName("scheme")) {
    requiredOffset = 300;
  } else {
    requiredOffset = 200;
  }
  if (element.cumulativeOffset().left > requiredOffset) {
    return cardTooltipParamsLeft;
  } else {
    return cardTooltipParamsRight;
  }
}
// Add tooltips for Multiverse mockups
document.observe('dom:loaded', function() {
  card_tooltips = {} // global hash
  var site_url = /(^.*:\/\/[^\/]+)/.exec(window.location.href)[1];
  var card_link_regex = new RegExp ( "^(" + site_url + ")?/cards\/([0-9]+)($|[#?])");
  $$("a[href]").each( function(link_element){
    if ((matches = card_link_regex.exec(link_element.href)) && !link_element.hasClassName("no_tooltip")) {
      card_id = matches[2];
      tooltip_div = makeTooltipDiv(link_element, card_id);
      link_element.tip = new Tip( link_element, tooltip_div, chooseTooltipParams(link_element) );
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
function makeTooltipDiv(parent_link_element, card_id){
  div_id = "card_tooltip_" + card_id;
  while ( $(div_id) ) {
    div_id += "_2"
  }
  // now we have an unused id
  div = new Element("div", {"class": "distinct_mockup_container " + parent_link_element.className, "id": div_id});
  div.appendChild(new Element("div", {"class": "cardborder blackborder card_loading"}));
  div.appendChild(new Element("div", {"class": "tooltip_footer"}));
  // $() in the while loop above will only find this if it's added into the DOM somewhere,
  // so we append it to the parent element for now
  parent_link_element.appendChild(div.hide());
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
  tooltip.select(".card").each(shrinkCardBits);
  if (!wasVisible) {
    tooltip.hide();
  }
}

// ------------ Expand/shrink text
function expand_text() {
 $$(".card").each(function(card){
   textbox = card.select(".cardtext")[0];
   if (/font-size/.match(textbox.getAttribute('style'))) {
     // "Expand": remove size, and set
     // button to "Expand further"
     textbox.style.fontSize = "";
     $("expand_text_link").innerHTML = "Expand further";
   } else if (!textbox.hasClassName("enlarged")) {
     // "Expand further": add enlarged
     // class, and set button to "Shrink"
     textbox.addClassName("enlarged");
     $("expand_text_link").innerHTML = "Shrink text";
   } else {
     // Shrink again, and set button text
     // to "Expand text"
     textbox.removeClassName("enlarged");
     shrinkCardBits(card);
     $("expand_text_link").innerHTML = "Expand text";
   }
 });
}

function changeCardZoom(multiplyingFactor) { 
  var theSheet = $A(document.styleSheets).select(function(s){
    return /Multiverse.css/.match(s.href);
  })[0];
  var theRules = new Array(); 
  if (theSheet.cssRules) { 
    theRules = theSheet.cssRules; 
  } else if (theSheet.rules) { 
    theRules = theSheet.rules; 
  } 
  var cardSizeRule = $A(theRules).select(function(r){
    return r.selectorText.toLowerCase() == "div.cardrenderinline"; // IE has it as "DIV.CardRenderInline"
  })[0];
  if (cardSizeRule.style.zoom) {
    cardSizeRule.style.zoom = parseInt(cardSizeRule.style.zoom) * multiplyingFactor + "%";
  }
  if (cardSizeRule.style.MozTransform) {
    cardSizeRule.style.MozTransform = "scale(" + (cardSizeRule.style.MozTransform.split(/[()]/)[1] * multiplyingFactor) + ")";
  }
  makeAllCardsFit();
}

// ------------ Rotate cards
function rotate_card() {
  var activeTab = $$(".active-tab")[0];
  if (activeTab && activeTab.id == "cardimage_link") {
    // Rotate the image
    $("cardimage").toggleClassName('rotated');
  } else {
    // Rotate the mockup
    $$('.cardborder')[0].toggleClassName('rotated');
  }
}

// ----------- Resize the fixed-width wrapper
// function resizeCardWrapper() 
// And the associated onload trigger
// are both defined in card/show.html.erb so that the Fabtabs can find the handle to the wrapper function

// ------------ Text selection
function selectCardLink(cardId) {
  var showlinkid = "show_link_text_card_" + cardId;
  var hidelinkid = "hide_link_text_card_" + cardId;
  var linkid = "link_text_card_" + cardId;
  var hintid = "link_hint_" + cardId;
  $(showlinkid).toggle();
  $(hidelinkid).toggle();
  $(linkid).focus();
  setTimeout("selectTextIn('"+linkid+"')", 10);
}

// (Functions below are from CoderZone.org)
function selectTextIn(objId) {
  deselectAllText();
  if (document.selection) {
  var range = document.body.createTextRange();
        range.moveToElementText(document.getElementById(objId));
  range.select();
  }
  else if (window.getSelection) {
  var range = document.createRange();
  range.selectNode(document.getElementById(objId));
  window.getSelection().addRange(range);
  }
}

function deselectAllText() {
  if (document.selection) document.selection.empty(); 
  else if (window.getSelection)
              window.getSelection().removeAllRanges();
}
