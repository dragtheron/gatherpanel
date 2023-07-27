Change Log
==========

2.8.0 (Unreleased)
------------------

Release Candidate.

[ADDED] Show Completed Objectives Toggle

You can now choose on how completed objectives are displayed.
A new setting appeared (default: enabled) and when disabled, completed objectives are hidden from the Objective Tracker.
And in the case of every objective completed, the whole "Gathering" section in the Objective Tracker disappears.

[ADDED] Show Gather Panel on Objetive Tracker Click

If you left-click on a group inside the Objective Tracker, the Gather Panel will now show up and scrolls to the
corresponding group where you can adjust entry properties.

[FIXED] Objective Tracker Overflow

If the objective list of a group exceeds the Objective Tracker size, the group will now be hidden until there is space
available again. This is the default behaviour of any objective block in the Objective Tracker.

2.7.0 (July 13, 2023)
---------------------

Updated for World of Warcraft Retail v10.1.5.

[ADDED] Untrack Groups in Objective Tracker

Untrack whole groups by Shift-Clicking a group in the Objective Tracker.

[CHANGED] Minimap Button Moved to AddOn Drawer

WoW v10.1.0 introduced a new AddOn Drawer in the corner of the minimap.
You'll find GatherPanel's clickable entrypoint from there from now on.

[CHANGED] Objective Tracker Heading

GatherPanel gathered more confidence, hence the heading on the Objective Tracker is now more descriptive.

[CHANGED] Objective Format in Objective Tracker

Once again, reformatted objectives to match Blizzard's current style of tracking progress instead of the classic one.

[FIXED] Untrackable Items in Objective Tracker

If you set a goal of 0 (e.g. when tracking higher-quality profession items), these items
won't show up in the trackers anymore.

[FIXED] Blizzard Professions Dependency

Blizzard's Professions addon is now required.

2.6.3 (May 3, 2023)
-------------------

Updated for WoW 10.1.0.

2.6.2 (March 16, 2023)
----------------------

[CHANGED] Count Updates

- With DataStore enabled, one now receives proper count updates.
- Updated counts on not-fulfilled gather objective now always trigger the notification message
  (this reverts the change in 2.6.0).
- The coloration of the entries on the Objective Tracker now is reflecting the state (min/max/full) correctly once more.

2.6.1 (February 1, 2023)
------------------------

[CHANGED] New Interface Version

- Updated to Interface Version 10.0.5
- Updates now trigger immediately upon item loot. The former trigger method did stop working in the latest interface
  version.

[FIXED] Objective Tracker Minimum Updates

- Entries on the Objective Tracker now get colored depending on their state (missing minimum/maximum/filled) properly
  when looting items (i.e. unfulfilled minimum entries won't lose their red colorization anymore).

2.6.0 (January 7, 2023)
-----------------------

[ADDED] Tooltip Text

- Items you added to your list will now have their tooltips extended by their progress information.
- It will show you the group where this item is listed in, as well as the current amount and goal for that item.
- Additionally, if you have added the same items but with lower quality to the appropriate group, their item counts
  will show as well, as long as they have a quantity goal.

[CHANGED] Progress Notifications

- Progress notifications will now appear only when the corresponding item is being tracked.
- Untracked items will only be visible on the Panel.

[CHANGED] Items Without Quantity Goals

- You may add items without a minimum or maximum quantity goal set.
- If there is no goal set, then they will appear now as "In Stock" and won't show up in tooltips at all.
- This may be useful to add higher-quality items to your lists while you are only interested in their lower-quality
  quantites, so that the higher-quality items can be accumulated - without the need of setting a fictional quantity
  goal for the higher-quality items.

[FIXED] Objective Tracker Update on Goal Count Change

- As soon as you change the minimum or maximum quantity goal for one item in your list, the Objective Tracker gets
  updated immediately now.

---

2.5.0 (December 12, 2022)
-------------------------

[ADDED] Dragonflight Profession Quality

- The profession quality now will be displayed beneath the name using its appropriate icon you got familiar with by
  Blizzard default.

[ADDED] Cumulate Items With Higher Qualities

- You can now choose if you want items of higher qualities included in the quantity calculation.
- There is a new setting available in the game Settings panel.
- Please note: This feature only works if you have that item of lower quality added onto your list!

[ADDED] Track Group

- Track or untrack an entire group by right-clicking the group name in the Panel.

[ADDED] Quest-like Objective Tracker

- In addition to the movable tracker bars, tracked item now are displayed in Blizzard's objective tracker.
- As soon as you fulfill an entry's quantity goal, the objective gets animated.
- If an entire group gets fulfilled, it fades/collapses to the completed note.
- You can choose wether you want your tracked entries be displayed in Blizzard's Objective Tracker or not.

[CHANGED] Item Ordering

- Items in the Panel are now sorted by item quality, then by name and then by profession quality.

[FIXED] Textual Progress Notifications

- Textual objective notifications now occur only if the respective quantity increases.

[FIXED] DropDown Tainting Errors

- Resolved tainting errors caused by using Blizzard's DropDown code.

---

2.4.1 (November 20, 2022)
-------------------------

[FIXED] Minimap Button Click Error

- Fixed an issue when clicking the minimap icon.

2.4.0 (November 17, 2022)
-------------------------

[ADDED] Settings Page in Game Settings

- Gather Panel's settings are now available via the Interface Options -> Addons page.
- The former settings tab in the Gather Panel itself is now gone.
- Every setting comes with a default setting you can load via the new "Default" button.
- Additionally, you can reach the settings directly using the new slash command:

      /gp options

[ADDED] New Setting: Play Sounds

- You can now choose wether you like to hear sounds in these situations at once:

  - tracking an item
  - untracking an item
  - reaching the item collect goal

[ADDED] Quest-like Progress Notification

- There is now a textual notification when you collect new items you are currently tracking.
- You can disable this notification in the settings.

[CHANGED] Dragonflight Support

- With the release of Dragonflight, the UI base changed and so Gather Panel now uses the brand-new UI elements.

[FIXED] Settings Storage and Defaults

- Settings are now stored properly in the user storage and defaults now only replace values which were not available
  before (i.e. don't override `false` anymore).

[FIXED] Item Group Selections

- The detail window besides Gather Panel (which opens when you click on an item) now shows the currently assigned group
  for that item without overflowing the dropdown menu frame.
- The currently selected option gets now marked as selected in the option list.
- This behavior has been applied to the panel where you can add new items, too, and the character selection.
- Additionally, when you reassign an item to a new group, that group's name in the dropdown menu button gets refreshed
  immediately.

[FIXED] Item Group Ordering

- The options in the item group selection drop down are now ordered alphabetically, just as they are in the item
  listings.

[FIXED] Single Item

- If you happen to have only one item in your list, that is now visible, even in this case.

[REMOVED] Settings Tab

- The settings tab has moved into the game settings.

---

2.3.0-beta0 (January 19, 2022)
------------------------------

[CHANGED] Alphabetical Group Sorting

- Groups are now ordered according to their name alphabetically.

---

2.2.0 (January 16, 2022)
------------------------

[ADDED] Keybinds and Minimap Button

- In addition to the chat commands, you can now toggle the tracker overlay and the panel frame via keybinds ("other"
  section) or the new minimap button.
- Regarding the minimap button: Use the left mouse button to toggle the panel and the right button to toggle the tracker
  overlay.

---

2.1.5 (January 13, 2022)
------------------------

[FIXED] Item Names After Locale Change

- Item information are now being updated after a locale change as intended.

2.1.4 (December 18, 2021)
-------------------------

[FIXED] Add Item: Minimum Amount Label

- This label is now properly named.

2.1.2 (December 16, 2021)
-------------------------

[FIXED] Empty Tracker Relic

- An empty Tracker will now be removed from the HUD so it no longer prevents interactions in its invisible state.

2.1.0 (November 10, 2021)
-------------------------

[ADDED] Localization for deDE and enUS

- All texts are now translated according to the client's locale.
- For the time being, this AddOn supports deDE and enUS.

[CHANGED] Support for WoW 9.1.5

- Updated TOC to latest game version.

2.1.0-beta4 (October 31, 2021)
------------------------------

[FIXED] Current Character Inclusion and Tracker Toggle

- The recently moved settings 'Include Current Character' and 'Show Tracker Overlay', as well as the `/gpt` command are
  working once more.

2.1.0-beta3 (October 31, 2021)
------------------------------

[ADDED] Link Items

- You can now link items from the Panel as well as the Tracker to post them in chat or other inputs fields.-

2.1.0-beta1 (October 31, 2021)
------------------------------

[ADDED] Progress Type and Counter Format Options

- There are two new options available for both the Panel and the Tracker visualization:
- For the counter style you can now chosse between percentage, numerical or blank style (was percentage before, with
  numerical on hover).
- For the progress type you can choose between 'Fill to Goal', i. e. fill your bars until min reached and again until
  maximum fill level reached, or 'Fill to Max' to fill the bar completely from zero to max once.
- Each of these options are global and thus are shared between your characters.

[ADDED] Localization Started

- Until now, there was no specific localization in place.
- With the upcoming updates, several texts will be translated into German as well as English, including labels,
  dropdowns and tooltips.

[ADDED] Group Selection at Item Enlisting

- You can now directly set the target group for a new item in the 'Add Item' panel.
- No need to go back and forth to move your items from 'Uncategorized' anymore.

[CHANGED] Instant Item Updates

- For item updates (setting min and max values), there is no longer a need to hit the 'Update' button.
- In fact, this button is now gone and changes are applied as soon as you leave one of the input fields, tick a checkbox
  or choose a dropdown selection.

[CHANGED] Reduced Variables For Settings

- All settings are now collected in a single variable and thus have been reset with this update. Please consult the
  reworked Settings panel to reconfigure your settings.
- Settings (inventory inclusions, tracker visibility) got moved to the new Settings panel and these
  settings are now properly described in a tooltip.

[FIXED] Item Info, Again

- Another issue has now been addressed, so that already acquired item information from the WoW API do not get erased
  upon relog or reload.

[FIXED] Negative Item Goals

- The item goal input fields no longer accept negative values.
- If you set a higher value for the 'Minimum' field as already in the 'Maxmimum' field, this input will become the new
  maximum level automatically, too.

2.1.0-alpha1 (October 29, 2021)
-------------------------------

[ADDED] Item List Persistence Between Player Sessions

- When you have selected a character to load its corresponding item list, you'll now notice that it will stay selected
  after a relog or reload.

[ADDED] Quick Track in Panel

- You can now track items without having to open the detail popup.
- A new checkbox appears next to each item entry in the Panel.

[ADDED] Item Group Removal

- The right-click menu for groups offers a new option 'Remove' to easily remove a whole group.
- This transfers all items in that group into the default 'Uncategorized' group.

[CHANGED] Quick Untrack via Tracker

- Untracking an item quickly using the tracker bars can be now achieved by right clicking, followed by a confirmation
  via a new context menu.

[CHANGED] Group Edit Options

- Untracking an item quickly using the tracker bars can be now achieved by right clicking, followed by a confirmation
  via a new context menu.

[CHANGED] Item Quality in Panel

- Items in the panel are now colored according to their quality level.
- This may help to navigate through a big list of items.

[CHANGED] Add Items UI

- The UI for adding items to the list got a new item dropzone which displays the future item with its icon and
  quality-colored name in the familiar way.
- Also, the instruction texts and error messages are now more stable.

[FIXED] Tracker Tooltip Positioning

- Item tooltips appearing on hovering a tracker bar now are positioned properly depending on the position of the tracker
  on the screen.
- This should solve overlap issues.

[FIXED] Tracking Status Between Player Sessions

- Previously, having tracked items on the current active character's item list followed by a reload or relog would have
  been resulted in a clearance of the tracking status for this character.
- Now tracked items for the currently active character should remain tracked when reloading or relogging as intended.

[FIXED] Item Info Loading

- An issue got resolved where items periodically did lose their information (name, texture, etc.).
- From now on, items should load their information after initialization and after a locale change.
- You may still have to open Gather Panel a few times before the complete list gets updated after a locale change, but
  it should not lose its information any more.

2.1.0-alpha0 (October 28, 2021)
-------------------------------

[ADDED] Item Groups

- You are now able to create groups and move items into them.
- Group up raid related items, your character's profession material or other context of your choosing.
- Every item group is specific to the character's item list while it is still supported to track and view your other
  character's item lists, including seeing their groups.
- Alternate existing groups by changing group names.
- Collapse groups in the panel to focus on specific topics on what to farm.
