## New Features: New Features List!


Sat Jan 15 00:16:46
## New Features: (((Card Code)))

You can now include (((triple parenthesis links))) to card codes like CW01 that _don't exist yet_. Clicking on these links will take you to the card creation page, with the appropriate fields already filled in. This is useful for set skeletons such as those on [Arcunda](http://multiverse.heroku.com/cardsets/14/details_pages/29). I'm expecting to provide a way to generate these skeletons for any cardset within the week.

Mon Jan 10 02:00:51 2011
## New Features: Basic and Token Rarities, Supertypes Clearer

There are now two more options for card rarities: Basic and Token. These will each appear in the appropriate slot in the virtual boosters. If a cardset has any tokens, this means the booster will now be 16 cards. (If a cardset doesn't contain any basic cards, it'll just use a random basic land as it always did. If a cardset doesn't contain any tokens, the boosters will remain 15 cards rather than 16.) The token frame is quite flashy - check out [an example](http://multiverse.heroku.com/cards/2657) :) 

I've also done some work on the card editing form, specifically the type line. The three text boxes were always meant to be supertype, type and subtype, but many people were using the leftmost one (supertype) for card types such as Creature or Artifact, and frankly I can't blame them. I've tried to make the interface a lot clearer: the type and subtype boxes are as they were, but the supertype box is now a supertype dropdown, with options for each of the current supertypes: Legendary, Basic, World and Snow. But if you want to combine multiple of those, or make up your own supertypes, there's another option in the dropdown, Custom, which will restore the free text entry supertype field. I'm hoping this will make it a lot easier for people to use Multiverse easily and correctly. I've gone through all the cards which had a card type (like Creature or Artifact) in the supertype box and fixed them up.

Finally, for those of you who use the CSV Import feature, if you encounter errors, those errors should in most cases be a bit more useful now.

Sat Jan 8 01:06:34 2011
## New Features: All Activity in Cardset Recent Activity

The new kinds of activity - deleting cards and comments, updating mechanics, and so on - now appear in the cardset recent activity list.

Thu Jan 6 09:36:56 2011
## New Features: Embed Images / Mockups with Double Brackets

I've finally introduced a feature I've always meant to add. The triple-bracket syntaxes for links to \[\[\[printed cards]]] and (((cards in the same cardset))) were always designed to allow me to introduce **double**-bracket links. These will appear not as just a hyperlink, but embed the full image of the card into the comment or details page where you use them. 

This lets you do some very cool things. On details pages you can include the mockups of several cards, to allow you to show examples, like [this](http://multiverse.heroku.com/cardsets/1/details_pages/1), and of course any embedded mockups like this will always show the latest state of the card. In certain cases where the substance of your comment would be enhanced by showing the text of a card, you can do that. 

Those of you who visit <http://draw3cards.com> will note that the Markdown for embedding card links and card images is identical on Multiverse to how it is there, and that's of course deliberate.

Mon Jan 3 00:36:34 2011
## New Features: Recent Activity View

Fri Dec 31 02:28:27 2010
## New Features: Bold and Italics in Card Text

Thu Dec 30 23:44:39 2010
## New Features: Export to CSV and Plain Text