

<!-- Card Images -->

<script type="text/javascript">
//overriding the replaceText function
jQuery.fn.replaceText = function(replaceFunc) {
    $(this).contents().filter(function() { return this.nodeType == 3 })
    .each(function() {
        $(this).after(replaceFunc(this.textContent)).remove();
    });
};

var cardNameToId = function(cardname) {
  return cardname.replace(/[-/ ]/g, "_").replace(/[:."!,']/g, "");
};





var injectCardImages = function() {
    var cardToImage = function(cardname) {
        var cardid = cardNameToId(cardname);
        return '<a href="http://gatherer.wizards.com/Pages/Search/Default.aspx?name=+[%22CARDNAME%22]" target="_blank"><img src="http://www.wizards.com/global/images/magic/general/CARDID.jpg" alt="CARDNAME" title="Surround a card name with double brackets to insert its image; for example: [[CARDNAME]]" class="CardImage"/></a>'.replace(/CARDNAME/g, cardname).replace(/CARDID/g, cardid);
    };

    var cardToImageLink = function(cardname) {
        var cardid = cardNameToId(cardname);
        return '<a href="http://gatherer.wizards.com/Pages/Search/Default.aspx?name=+[%22CARDNAME%22]" rel="http://www.wizards.com/global/images/magic/general/CARDID.jpg" target="_blank" title="CARDNAME" class="cardImageLink">CARDNAME</a>'.replace(/CARDNAME/g, cardname).replace(/CARDID/g, cardid);
    };

    var symbolToImage = function(text) {
        var name = text;
        //Rather than directly implementing additional phrases, we take information from variable name and redirect it to the appropriate function. Every function redirected here must also be recognized by filters for variable res. Note that it might be easier to redirect this information before it's filtered in variable res, but this depends on other functions of the variable.
        name = name.replace("S", "snow");
        name = name.replace("T", "tap");
        name = name.replace("Q", "untap");
        name = name.replace("8", "Infinity");
        name = name.replace("GR","RG");
        name = name.replace("RB","BR");
        name = name.replace("BU","UB");
        name = name.replace("UW","WU");
        name = name.replace("WG","GW");
        name = name.replace("WR","RW");
        name = name.replace("UG","GU");
        name = name.replace("BW","WB");
        name = name.replace("RU","UR");
        name = name.replace("GB","BG");
        name = name.replace("G2","2G");
        name = name.replace("R2","2R");
        name = name.replace("B2","2B");
        name = name.replace("U2","2U");
        name = name.replace("W2","2W");

        name = name.replace(/^inf.*/i, "Infinity");

        if (name == "C")
        {
            imageUrl = "http://gatherer.wizards.com/Images/Symbols/chaos.gif";
        }
        else
        {
            imageUrl = "http://gatherer.wizards.com/Handlers/Image.ashx?size=small&name=NAME&type=symbol";
        }
        image = '<img src="' + imageUrl + '" alt="{ALT}" title="{ALT}">';
        return image.replace("NAME", name).replace(/ALT/g, text);
    };

    var cardQuotesToImages = function(text, linksOnly) {
        var res = text.replace(/\[\[\[([:!".'A-Za-z-,\/\s]+)]]]/gi, function(m, g) {
            return cardToImageLink(g);
        });
        if (!linksOnly) {
            res = res.replace(/\[\[([:!".'A-Za-z-,\/\s]+)]]/gi, function(m, g) {
                return cardToImage(g);
            });
        }
        res = res.replace(/\{([WUBRGSTQ8]|RG|GR|GW|WG|WU|UW|UB|BU|BR|RB|RW|WR|GU|UG|WB|BW|UR|RU|BG|GB|2G|G2|2W|W2|2U|U2|2B|B2|2R|R2|X|C|\d+|snow|tap|untap|[Ii]nf|[Ii]nfinity)\}/g, function(m, g) {
            return symbolToImage(g);
        });

        return res;
    };

    var cardListsToImages = function(text) {
        var res = text.replace(/\d{1,2}[Xx] ([:!".'A-Za-z-,\/ ]+)/gi, function(m, g) {
            try
            {
                var prefix = m.replace(/(\d{1,2}[Xx] )[:!".'A-Za-z-,\/ ]+/, function(m, g) {
                    return g;
                });
//                alert("Replacing '" + g + "', with prefix='" + prefix + "'");
                return prefix + cardToImageLink(g) + "<br/>";
            }
            catch (e)
            {
//                alert("Error: " + e);
            }
        });
        return res;
    };

    $(".post-text *").replaceText(function(text) {
        return cardQuotesToImages(text, false);
    });

    $(".post-text *").replaceText(function(text) {
        return cardListsToImages(text);
    });

    $(".comment-text").replaceText(function(text) {
        return cardQuotesToImages(text, true);
    });

    $("#wmd-input").change(function() {
        $("#wmd-preview p").replaceText(function(text) {
          return cardQuotesToImages(text, false);
        });
    });
};


$(document).ready(injectCardImages);



<!-- popup card images -->
/*
 * Url preview script
 * powered by jQuery (http://www.jquery.com)
 *
 * written by Alen Grakalic (http://cssglobe.com)
 *
 * for more info visit http://cssglobe.com/post/1695/easiest-tooltip-and-image-preview-using-jquery
 *
 */

this.screenshotPreview = function(){
    /* CONFIG */

    xOffset = 10;
    yOffset = 30;
    // these 2 variables determine popup's distance from the cursor
    // you might want to adjust to get the right result

    /* END CONFIG */

    $("a.cardImageLink").hover(function(e){
        this.t = this.title;
        this.title = "";
        var popup = $("<p id='cardImageLink'><img src='"+ this.rel +"' alt='Card Preview' /></p>");
        $("body").append(popup.hide());
        popup
            .css("top",(e.pageY - yOffset) + "px")
            .css("left",(e.pageX + xOffset) + "px")
            .fadeIn(150);
    },
    function(){
        this.title = this.t;
        $("#cardImageLink").remove();
    });
    $("a.cardImageLink").mousemove(function(e){
        $("#cardImageLink")
            .css("top",(e.pageY - xOffset) + "px")
            .css("left",(e.pageX + yOffset) + "px");
    });
};


// starting the script on page load
$(document).ready(function(){
    screenshotPreview();
});



