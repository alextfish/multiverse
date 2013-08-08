/*
 * Fabtabulous! Simple tabs using Prototype
 * http://tetlaw.id.au/view/blog/fabtabulous-simple-tabs-using-prototype/
 * Andrew Tetlaw
 * version 1.1 2006-05-06
 * http://creativecommons.org/licenses/by-sa/2.5/
 *
 * Modified by Alex Churchill 2010-11-13 to add initial_tab input string
 */
var Fabtabs = Class.create();

Fabtabs.prototype = {
  initialize : function(element, initial_tab) {
    // Takes 2 or 3 input arguments.
    // First argument is the element containing the hyperlinks (<a> tags).
    // Second is the ID of the initial tab.
    // Third is a function f which is called when the tab changes, as f(hyperlink_object).
    this.element = $(element);
    if(arguments.length > 2) {
      this.onActivate = arguments[2];
    } else {
      this.onActivate = null;
    }
    this.menu = $A(this.element.getElementsByTagName('a'));
    this.show($(initial_tab));    // this.getInitialTab());
    this.menu.each(this.setupTab.bind(this));
  },
  setupTab : function(elm) {
    Event.observe(elm,'click',this.activate.bindAsEventListener(this),false)
  },
  activate :  function(ev) {
    var elm = Event.findElement(ev, "a");
    Event.stop(ev);
    this.show(elm);
    this.menu.without(elm).each(this.hide.bind(this));
    if (this.onActivate !== null) {
      this.onActivate(elm);
    }
  },
  hide : function(elm) {
    $(elm).removeClassName('active-tab');
    $(this.tabID(elm)).removeClassName('active-tab-body');
  },
  show : function(elm) {
    $(elm).addClassName('active-tab');
    $(this.tabID(elm)).addClassName('active-tab-body');
  },
  tabID : function(elm) {
    return elm.href.match(/#(\w.+)/)[1];
  },
  
  // Never got this working
  getInitialTab : function() {
    if(document.location.href.match(/#(\w.+)/)) {
      var loc = RegExp.$1;
      var elm = this.menu.find(function(value) { return value.href.match(/#(\w.+)/)[1] == loc; });
      return elm || this.menu.first();
    } else {
      return this.menu.first();
    }
  }
}
