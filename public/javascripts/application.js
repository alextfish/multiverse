// Place your application-specific JavaScript functions and classes here
// This file is automatically included by javascript_include_tag :defaults

function update_card_rarity(new_rarity) {
  cell = document.getElementById("raritycell");
  cell.className = "cardrarity " + new_rarity.toLowerCase();
}