local _, addon = ...;
local module = addon:RegisterModule("Popups");


local function popupConfirmGroupCreation(frame)
  addon.Groups.Create(frame.editBox:GetText());
end


local function setupNewGroupPopup()
  StaticPopupDialogs["GatherPanel_CreateGroup"] = {
    text = addon.T["CREATE_NEW_GROUP"],
    button1 = ACCEPT,
    button2 = CANCEL,
    hasEditBox = 1,
    hideOnEscape = 1,
    OnAccept = popupConfirmGroupCreation,
    OnShow = function(frame)
      frame.editBox:SetFocus();
    end,
    OnHide = function(frame)
      frame.editBox:SetText("");
    end,
    EditBoxOnEnterPressed = function(frame)
      local popup = frame:GetParent();
      popupConfirmGroupCreation(frame);
      popup:Hide();
    end,
    EditBoxOnEscapePressed = function(frame)
      frame:GetParent():Hide();
    end,
  }
end


local function popupConfirmGroupNameEdit(frame, group)
  addon.Groups.EditName(group.id, frame.editBox:GetText());
end


local function setupEditGroupNamePopup()
  StaticPopupDialogs["GatherPanel_EditGroupName"] = {
    text = addon.T["RENAME_GROUP"],
    button1 = ACCEPT,
    button2 = CANCEL,
    hasEditBox = 1,
    hideOnEscape = 1,
    OnAccept = popupConfirmGroupNameEdit,
    OnShow = function(frame, group)
      frame.editBox:SetText(group.name);
      frame.editBox:SetFocus();
    end,
    OnHide = function(frame)
      frame.editBox:SetText("");
    end,
    EditBoxOnEnterPressed = function(frame, group)
      local popup = frame:GetParent();
      popupConfirmGroupNameEdit(frame, group);
      popup:Hide();
    end,
    EditBoxOnEscapePressed = function(frame)
      frame:GetParent():Hide();
    end,
  }
end


function module:Init()
  setupNewGroupPopup();
  setupEditGroupNamePopup();
end
