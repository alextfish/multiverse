news_latest_update = {
  :date => Time.gm(2011,1,22,23,34,00),
  :title => "New Features: Set Skeletons, Planeswalkers, and New Features List!",
  :body => <<ENDBODY };

### New Features: New Features List!

----
### New Features: (((Card Code)))
#### Sat Jan 15 00:16:46 

You can now include (((triple parenthesis links))) to card codes like CW01 that _don't exist yet_. Clicking on these links will take you to the card creation page, with the appropriate fields already filled in. This is useful for set skeletons such as those on [Arcunda](http://multiverse.heroku.com/cardsets/14/details_pages/29). I'm expecting to provide a way to generate these skeletons for any cardset within the week.

----
### New Features: Basic and Token Rarities, Supertypes Clearer
#### Mon Jan 10 02:00:51 2011

There are now two more options for card rarities: Basic and Token. These will each appear in the appropriate slot in the virtual boosters. If a cardset has any tokens, this means the booster will now be 16 cards. (If a cardset doesn't contain any basic cards, it'll just use a random basic land as it always did. If a cardset doesn't contain any tokens, the boosters will remain 15 cards rather than 16.) The token frame is quite flashy - check out [an example](http://multiverse.heroku.com/cards/2657) :) 

I've also done some work on the card editing form, specifically the type line. The three text boxes were always meant to be supertype, type and subtype, but many people were using the leftmost one (supertype) for card types such as Creature or Artifact, and frankly I can't blame them. I've tried to make the interface a lot clearer: the type and subtype boxes are as they were, but the supertype box is now a supertype dropdown, with options for each of the current supertypes: Legendary, Basic, World and Snow. But if you want to combine multiple of those, or make up your own supertypes, there's another option in the dropdown, Custom, which will restore the free text entry supertype field. I'm hoping this will make it a lot easier for people to use Multiverse easily and correctly. I've gone through all the cards which had a card type (like Creature or Artifact) in the supertype box and fixed them up.

Finally, for those of you who use the CSV Import feature, if you encounter errors, those errors should in most cases be a bit more useful now.

----
### New Features: All Activity in Cardset Recent Activity
#### Sat Jan 8 01:06:34 2011

The new kinds of activity - deleting cards and comments, updating mechanics, and so on - now appear in the cardset recent activity list.

----
### New Features: Embed Images / Mockups with Double Brackets
#### Thu Jan 6 09:36:56 2011

I've finally introduced a feature I've always meant to add. The triple-bracket syntaxes for links to \[\[\[printed cards]]] and (((cards in the same cardset))) were always designed to allow me to introduce **double**-bracket links. These will appear not as just a hyperlink, but embed the full image of the card into the comment or details page where you use them. 

This lets you do some very cool things. On details pages you can include the mockups of several cards, to allow you to show examples, like [this](http://multiverse.heroku.com/cardsets/1/details_pages/1), and of course any embedded mockups like this will always show the latest state of the card. (This will also be useful when I let you embed a details page into the front page of your set, so that certain showcase cards are always shown off.) You can do these in comments too, such as [this one](http://multiverse.heroku.com/cards/1463#comment_1467), so that in certain cases where the substance of your comment would be enhanced by showing the text of a card, you can do that. 

Those of you who visit [draw3cards.com](http://draw3cards.com) will note that the Markdown for embedding card links and card images is identical on Multiverse to how it is there, and that's of course deliberate.

----
### New Features: Recent Activity View
#### Mon Jan 3 00:36:34 2011

The "Cardsets" link at the top-centre of every Multiverse page has been replaced with a "Recent updates" link. This still shows you a list of all cardsets, but now they're sorted by how recently anything happened on the cardset. It shows you what the most recent activity was and who it was by. The time link (like "2 hours ago") goes to the list of *all* recent activity for the cardset in question, so you can see what all of the hot topics are in each cardset you're interested in. 

The cardsets view is now sortable, so you can always still sort it alphabetically, or by number of cards in the cardset, or any of the other columns if you want. And a number of new types of activity are now being logged that didn't show up in recent activity logs before. Deleting cards/comments/details pages now shows up, although there's less information available on things that have been deleted. Creating, editing and deleting mechanics also shows up now.

----
### New Features: Bold and Italics in Card Text
#### Fri Dec 31 02:28:27 2010

For a long time I didn't have a way to provide italicised words in card text that weren't in parentheses. Normally  you don't need to, but for ability words such as "*Metalcraft* - ~ has +2/+2 as long as you control 3 or more artifacts", the ability word is properly in italics. Now you can do this, just the same way you'd make any other text in Multiverse italicised: surround it by asterisks or underscores, like `*Metalcraft*`. Similarly, flavour text is normally italicised, but if you want bits of it to not be italics, or to be in bold, you can do that too.

This isn't full Markdown support for card texts: there are assorted problems with that, and I don't think it's a good idea. But if there's any other formatting you want to be able to do in card text, let me know your use case and I'll give it some consideration.

----
### New Features: Export to CSV and Plain Text
#### Thu Dec 30 23:44:39 2010

The cardset Export page now has three types of export. The "plain text" spoiler is now *really* plain text - it arrives in MIME-type text/plain. The CSV is suitable for re-importing into Multiverse's Import page. And the XML probably won't be much use to most people, but it might be to someone. It's there, anyway.
ENDBODY