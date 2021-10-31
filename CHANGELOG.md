31 October 2021 - 2.1.0-beta4
=============================

**[FIXED]** Current Character Inclusion and Tracker Toggle
----------------------------------------------------------
The moved settings 'Include Current Character' and 'Show Tracker Overlay', as well as the `/gpt` command are working again.


31 October 2021 - 2.1.0-beta3
=============================

**[ADDED]** Link Items
----------------------
You can now link items from the Panel as well as the Tracker to post them in chat or other inputs fields.


31 October 2021 - 2.1.0-beta1
=============================

**[ADDED]** Progress Type and Counter Format Options
----------------------------------------------------
There are two new options available for both the Panel and the Tracker visualization:
For the counter style you can now chosse between percentage, numerical or blank style (was percentage before, with numerical on hover).
For the progress type you can choose between 'Fill to Goal', i. e. fill your bars until min reached and again until max reached, or 'Fill to Max' to fill the bar completely from zero to max once.
Each of these options are global and thus are shared between your characters.

**[ADDED]** Localization Started
--------------------------------
Until now, there was no specific localization in place. 
With the upcoming updates, several texts will be translated into German as well as English, including labels, dropdowns and tooltips.

**[ADDED]** Group Selection at Item Enlisting
---------------------------------------------
You can now directly set the target group for a new item in the 'Add Item' panel.
No need to go back and forth to move your items from 'Uncategorized' anymore.

**[CHANGED]** Instant Item Updates
----------------------------------
For item updates (setting min and max values), there is no longer a need to hit the 'Update' button.
In fact, this button is now gone and changes are applied as soon as you leave one of the input fields, tick a checkbox or choose a dropdown selection.

**[CHANGED]** Reduced Variables For Settings
--------------------------------------------
All settings are now collected in a single variable and thus have been reset with this update.
Please consult the reworked Settings panel to reconfigure your settings.

Additionally, settings (inventory inclusions, tracker visibility) got moved to the new Settings panel and these settings are now properly described in a tooltip.

**[FIXED]** Item Info, Again
----------------------------
Another issue has now been addressed, so that already acquired item information from the WoW API do not get erased upon relog or reload.

**[FIXED]** Negative Item Goals
-------------------------------
The item goal input fields no longer accept negative values.

Additionally, if you set a higher value for the 'Minimum' field as already in the 'Maxmimum' field, this input will become the new Maximum automatically, too.


29 October 2021 - 2.1.0-alpha1
==============================

**[ADDED]** Item List Persistence Between Player Sessions
---------------------------------------------------------
When you have selected a character to load its corresponding item list, 
you'll now notice that it will stay selected after a relog or reload.

**[ADDED]** Quick Track in Panel
--------------------------------
You can now track items without having to open the detail popup.
A new checkbox appears next to each item entry in the Panel.

**[ADDED]** Item Group Removal
------------------------------
The right-click menu for groups offers a new option 'Remove' to easily
remove a whole group.
This transfers all items in that group into the default 'Uncategorized' group.

**[CHANGED]** Quick Untrack via Tracker
---------------------------------------
Untracking an item quickly using the tracker bars can be now achieved by 
right clicking, followed by a confirmation via a new context menu.

**[CHANGED]** Group Edit Options
--------------------------------
Untracking an item quickly using the tracker bars can be now achieved by 
right clicking, followed by a confirmation via a new context menu.

**[CHANGED]** Item Quality in Panel
-----------------------------------
Items in the panel are now colored according to their quality level.
This may help to navigate through a big list of items.

**[CHANGED]** Add Items UI
--------------------------
The UI for adding items to the list got a new item dropzone which
displays the future item with its icon and quality-colored name in the
familiar way.

Also, the instruction texts and error messages are now more stable.

**[FIXED]** Tracker Tooltip Positioning
-----------------------------------------
Item tooltips appearing on hovering a tracker bar now are positioned 
properly depending on the position of the tracker on the screen.
This should solve overlap issues.

**[FIXED]** Tracking Status Between Player Sessions
-----------------------------------------------------
Previously, having tracked items on the current active character's 
item list followed by a reload or relog would have result in a clearance of
the tracking status for this character.

Now tracked items for the currently active character should remain tracked 
when reloading or relogging as intended.

**[FIXED]** Item Info Loading
-----------------------------
An issue got resolved where items periodically did lose their information (name, texture, etc.).
From now on, items should load their information after initialization and after a locale change.
You may still have to open Gather Panel a few times before the complete list gets updated after
a locale change, but it should not lose its information any more.


28 October 2021 - 2.1.0-alpha0
==============================

**[ADDED]** Item Groups
-----------------------
You are now able to create groups and move items into them.
Group up raid related items, your character's profession material
or other context of your choosing.
  - Every item group is specific to the character's item list while 
    it is still supported to track and view your other character's item
    lists, including seeing their groups.
  - Alternate existing groups by changing group names.
  - Collapse groups in the panel to focus on specific topics on what to farm.

