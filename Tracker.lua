local _, addon = ...;
local module = addon:RegisterModule("Tracker");


---@type Entries.Entry[]
local entries = addon.Entries.Entries;


local trackerFrames = {};
local numActive = 0;
local numCreated = 0;


function module:Init()

end


function module:Update()
end


local function createTracker()
  local frame = CreateFrame("Frame", nil, module.frame, "GatherPanel_TrackerTemplate");
  frame:SetPoint("TOPLEFT", trackerFrames[numCreated], "BOTTOMLEFT", 0, 5);
  frame.AnimValue = nil;
  numCreated = numCreated + 1;
end


local function getOrCreateFreeTracker()
  if numActive < numCreated then
    return trackerFrames[numActive + 1];
  else
    return createTracker();
  end
end


local function setTrackerEntryInfo(frame, entry)
  frame.entry = entry;
  frame.Icon = entry.texture;
  frame.AnimValue = entry.percentageMax * 100;
  frame.Bar.Icon:SetTexture(item.texture);
end


local function updateCheckpointMarkers(frame, entry)
  if entry.min ~= entry.max
    and entry.min > entry.count then
      local progress = entry.min / entry.max;
      local xPos = progress * frame.Bar:GetWidth();
      frame.Bar.CheckPoint:Show();
      frame.Bar.CheckPoint:SetPoint("CENTER", frame.Bar, "LEFT", xPos, -1.5);
    else
      frame.Bar.CheckPoint:Hide();
    end
end


local function updateCheckMark(frame, entry)
  if entry.goal <= entry.count then
    frame.Bar.CheckMarkTexture:Show();
  else
    frame.Bar.CheckMarkTexture:Hide();
  end
end


local function initTracker(entry, index)
  entry.trackerIndex = index;
  local frame = trackerFrames[index];
  setTrackerEntryInfo(frame, entry);
  updateCheckpointMarkers(frame, entry);
  updateCheckMark(frame, entry);
end


function module:Create(entry)
  getOrCreateFreeTracker();
  numActive = numActive + 1;
  initTracker(entry, numActive);
end


local function reset()
  local active = 0;

  for _, entry in pairs(entries) do
    if entry.tracking then
      active = active + 1;
      if active < numActive then
        initTracker(entry, active);
      else
        module:Create(entry);
      end
    end
  end

  for index = active, numActive do
    trackerFrames[index]:Hide();
  end

  numActive = active;
end


function module:Remove(entry)
  entry.tracking = false;
  reset();
end
