if rawget(_G, "__MHWS_ITEM_EDITOR_LOADED") == true then
    return
end
_G.__MHWS_ITEM_EDITOR_LOADED = true

local re = re
local sdk = sdk
local d2d = d2d
local imgui = imgui
local log = log
local json = json
local draw = draw
local string = string
local tostring = tostring
local tonumber = tonumber
local pairs = pairs
local table = table
local _ = _
local math = math

local Core = require("_CatLib")
local Imgui = require("_CatLib.imgui")

local mod = Core.NewMod("Item Editor")
mod.EnableCJKFont(18) -- if needed

if mod.Config.ItemConfEditList == nil then
    mod.Config.ItemConfEditList = {}
end

local function ApplyItemEdits()
    local mgr = Core.GetVariousDataManager()
    if not mgr then
        return
    end

    local values = mgr._Setting._ItemSetting._ItemData._Values

    Core.ForEach(values, function (value)
        local id = Core.FixedToEnum("app.ItemDef.ID", value._ItemId)

        local data = mod.Config.ItemConfEditList[tostring(id)]
        if data ~= nil then
            if data.Infinity ~= nil then
                value._Infinit = data.Infinity
            end
            if data.MaxCount ~= nil then
                value._MaxCount = data.MaxCount
            end
        end
    end)
end

ApplyItemEdits()
Core.OnLoadSave(function ()
    ApplyItemEdits()
end)

local BasicParamUtil = Core.WrapTypedef("app.BasicParamUtil")
local ItemDef = Core.WrapTypedef("app.ItemDef")
local ItemUtil = Core.WrapTypedef("app.ItemUtil")
local ItemIDNone = Core.TypeField("app.ItemDef.ID", "NONE"):get_data()
local ItemIDMax = Core.TypeField("app.ItemDef.ID", "MAX"):get_data()

local ItemRareNames = Core.GetEnumMap("app.ItemDef.RARE")
local ItemTypeNames = Core.GetEnumMap("app.ItemDef.TYPE")
local AddIconTypeNames = Core.GetEnumMap("app.IconDef.AddIcon")
local PouchTypeNames = Core.GetEnumMap("app.ItemUtil.POUCH_TYPE")

local function GetItemType(id)
    return ItemDef:StaticCall("Type(app.ItemDef.ID)", id)
end

local function GetItemRare(id)
    return ItemDef:StaticCall("Rare(app.ItemDef.ID)", id)
end

local function GetItemExtraIcon(id)
    return ItemDef:StaticCall("AddIconType(app.ItemDef.ID)", id)
end

local function GetItemPouchType(id)
    return ItemDef:StaticCall("PouchType(app.ItemDef.ID)", id)
end

local function IsValid(id)
    return ItemDef:StaticCall("isValid(app.ItemDef.ID)", id)
end
local function IsInfinity(id)
    return ItemDef:StaticCall("Infinit(app.ItemDef.ID)", id)
end

local function IsValidName(name)
    if mod.Config.Debug then
        return true
    end
    return Core.IsValidName(name)
end

local function GetItemBoxItemCount(id)
    return ItemUtil:StaticCall("getItemNum(app.ItemDef.ID, app.ItemUtil.STOCK_TYPE)", id, 1) -- 1 BOX
end
local function GetItemBoxItemCapacity(id)
    return ItemUtil:StaticCall("getItemCapacity(app.ItemDef.ID, app.ItemUtil.STOCK_TYPE)", id, 1) -- 1 BOX
end

local function GetPouchItemCount(id)
    return ItemUtil:StaticCall("getItemNum(app.ItemDef.ID, app.ItemUtil.STOCK_TYPE)", id, 0) -- 1 BOX
end
local function GetPouchItemCapacity(id)
    return ItemUtil:StaticCall("getItemCapacity(app.ItemDef.ID, app.ItemUtil.STOCK_TYPE)", id, 0) -- 1 Pouch
end

local function ChangeItemBoxItemCount(id, num)
    return ItemUtil:StaticCall("changeItemNum(app.ItemDef.ID, System.Int16, app.ItemUtil.STOCK_TYPE)", id, num, 1) -- 1 BOX
end

local function ChangePouchItemCount(id, num)
    return ItemUtil:StaticCall("changeItemNum(app.ItemDef.ID, System.Int16, app.ItemUtil.STOCK_TYPE)", id, num, 0) -- 1 BOX
end

local __AuthorChoiceItemIDs = {
    1, -- 回复药
    2, -- 回复药G
    3, -- 解毒药
    4, -- 秘药
    5, -- 远古秘药
    6, -- 打消果实
    11, -- 生命粉尘
    177, -- 生命大粉尘

    15, -- 投射器闪光弹
    277, -- 投射器音爆弹
    71, -- 投射器异臭弹
    456, -- 投射器大异臭弹

    18, -- 落穴陷阱
    19, -- 麻痹陷阱

    25, -- 药草
    27, -- 蜂蜜
    65, -- 曼陀罗

    -- 通常弹
    -- 贯穿弹
    -- 散弹
    -- 穿甲榴弹
    -- 扩散弹
    -- 火炎弹
    -- 水冷弹
    -- 电击弹
    -- 冰结弹
    -- 灭龙弹
    -- 毒弹
    -- 麻痹弹
    -- 睡眠弹
    -- 斩裂弹

    -- 鬼人弹
    -- 硬化弹
    -- 回复弹
    -- 捕获用麻醉弹
    -- 减气弹

    13, -- 小桶爆弹
    14, -- 大桶爆弹
    196, -- 大桶爆弹G

    76, -- 回归球
    150, -- 烟雾球
    179, -- 毒烟雾球
    180, -- 捕获用麻醉球
    270, -- 坚硬竹荚鱼的鳍
    683, -- 坚硬竹荚鱼的上等鳍
    684, -- 大刺身鱼鳞片
    
    125, -- 怪力种子
    126, -- 忍耐种子

    162, -- 元气饮料
    163, -- 强走药
    164, -- 活力剂
    165, -- 冷饮
    166, -- 热饮
    167, -- 鬼人药
    168, -- 怪力药丸
    169, -- 鬼人药G
    170, -- 硬化药
    171, -- 忍耐药丸
    172, -- 硬化药G
    173, -- 汉方药
    174, -- 汉方粉尘
    175, -- 鬼人粉尘
    176, -- 硬化粉尘

    178, -- 消散剂

    621, -- 铠玉
    622, -- 上铠玉
    623, -- 尖铠玉
    624, -- 坚铠玉
    653, -- 重铠玉

    646, -- 钢之炼金票
    647, -- 银之炼金票
    648, -- 钢之遗物票
    649, -- 银之遗物票
    661, -- 金之炼金票
    662, -- 金之遗物票
}

local AuthorChoiceItemIDs = {}

local inited = false
local FilterType = {
    "All Items (no filter)",
    "Category",
    "Rarity",
    "Property",
    "Extra Icon",
    "PouchType",
    "Slinger Ammo",
    "Mod Author's Choice",
}

---@class EditorItemData
---@field ID app.ItemDef.ID
---@field Name string
---@field RawName string
---@field SortID number

---@class EditorItemTable
---@field DataMap table<app.ItemDef.ID, EditorItemData>
---@field SortedItemIDArray app.ItemDef.ID[]
---@field SortedItemNameArray string[]

---@return EditorItemTable
local function NewItemTable()
    return {
        DataMap = {},
        SortedItemIDArray = {},
        SortedItemNameArray = {},
    }
end

---@param itemTable EditorItemTable
local function BuildSortedItemTable(itemTable)
    local map = itemTable.DataMap

    local list = {}

    for id, data in pairs(map) do
        table.insert(list, data)
    end

    table.sort(list, function (a, b)
        return a.SortID < b.SortID
    end)

    for _, data in pairs(list) do
        table.insert(itemTable.SortedItemIDArray, data.ID)
        table.insert(itemTable.SortedItemNameArray, data.Name)
    end
end

local SlingerToItemIdDict = Core.WrapTypedef("app.HunterDef"):StaticField("SLINGER_AMMO_TYPE_TO_ITEM_ID")

local AllItemTable = NewItemTable()
local SlingerItemTable = NewItemTable()
local AuthorChoiceItemTable = NewItemTable()

---@type table<app.ItemDef.RARE, EditorItemTable>
local ItemRarityTables = {}

---@type table<app.ItemDef.TYPE, EditorItemTable>
local ItemTypeTables = {}

---@type table<string, EditorItemTable>
local ItemPropertyTables = {}

---@type table<app.IconDef.AddIcon, EditorItemTable>
local ItemExtraIconTables = {}

---@type table<app.ItemUtil.POUCH_TYPE, EditorItemTable>
local ItemPouchTypeTables = {}

-- ids
local Properties = {
    "EnableOnRaptor",
    "Fix",
    "Shikyu",
    "Eatable",
    "Window",
    "Heal",
    "Battle",
    "Special",
    "ForMoney",
    "OutBox",
}

local NonNilIconNames = {}

-- batch ids
local HealItemIDs = {}
local ShellItemIDs = {}
local FoodItemIDs = {}
local ExpendableIDs = {}
local SlingerIDs = {}

local inited = false
local function InitItemNames()
    if inited then return end

    local mgr = Core.GetVariousDataManager()
    if not mgr then
        return
    end

    local values = mgr._Setting._ItemSetting._ItemData._Values

    Core.ForEach(values,
    ---@param value app.user_data.ItemData.cData
    function (value)
        local rawName = Core.GetLocalizedText(value._RawName)
        if not Core.IsValidName(rawName) then
            return
        end

        local id = Core.FixedToEnum("app.ItemDef.ID", value._ItemId)
        local sort = value._SortId
        
        local name = string.format("%d: %s", sort, rawName)
        if mod.Config.Debug then
            name = string.format("%s: ID[%d] Sort[%d]", name, id, sort)
        end
        local itemData = {
            ID = id,
            RawName = rawName,
            Name = name,
            SortID = sort,
        }


        -- no filter
        AllItemTable.DataMap[id] = itemData

        -- item type
        local type = value:get_Type()
        if ItemTypeTables[type] == nil then
            ItemTypeTables[type] = NewItemTable()
        end
        ItemTypeTables[type].DataMap[id] = itemData

        if type == 0 then
            ExpendableIDs[id] = name
        elseif type == 3 then
            ShellItemIDs[id] = name
        end

        -- rarity
        local lv = value:get_Rare()
        if ItemRarityTables[lv] == nil then
            ItemRarityTables[lv] = NewItemTable()
        end
        ItemRarityTables[lv].DataMap[id] = itemData

        -- some properties
        for _, prop in pairs(Properties) do
            if value:call(string.format("get_%s()", prop)) then
                if ItemPropertyTables[prop] == nil then
                    ItemPropertyTables[prop] = NewItemTable()
                end
                ItemPropertyTables[prop].DataMap[id] = itemData
                if prop == "Heal" then
                    HealItemIDs[id] = name
                end
            end
        end

        -- add icon
        local icon = value:get_AddIconType()
        if ItemExtraIconTables[icon] == nil then
            ItemExtraIconTables[icon] = NewItemTable()
            NonNilIconNames[icon] = AddIconTypeNames[icon]
        end
        ItemExtraIconTables[icon].DataMap[id] = itemData

        if icon == 30 then
            FoodItemIDs[id] = name
        end

        -- pouch type
        local type = GetItemPouchType(id)
        if ItemPouchTypeTables[type] == nil then
            ItemPouchTypeTables[type] = NewItemTable()
        end
        ItemPouchTypeTables[type].DataMap[id] = itemData
    end)
    
    -- Slinger Type
    Core.ForEachDict(SlingerToItemIdDict, function (slingerType, itemID)
        local data = AllItemTable.DataMap[itemID]
        if data then
            SlingerItemTable.DataMap[itemID] = data
            SlingerIDs[itemID] = data.Name
        end
    end)

    -- Author choice
    for _, itemID in pairs(__AuthorChoiceItemIDs) do
        local data = AllItemTable.DataMap[itemID]
        if data then
            AuthorChoiceItemTable.DataMap[itemID] = data
            AuthorChoiceItemIDs[itemID] = data.Name
        end
    end

    -- sort items by sort id
    local function _build_tables(itemTables)
        for _, itemTable in pairs(itemTables) do
            BuildSortedItemTable(itemTable)    
        end
    end

    BuildSortedItemTable(AllItemTable)
    BuildSortedItemTable(SlingerItemTable)
    BuildSortedItemTable(AuthorChoiceItemTable)
    _build_tables(ItemRarityTables)
    _build_tables(ItemTypeTables)
    _build_tables(ItemPropertyTables)
    _build_tables(ItemExtraIconTables)
    _build_tables(ItemPouchTypeTables)

    inited = true
    mod.SaveConfig()
end

-- 5 Money 6 Point 7 Ticket 8 HunterPoint
-- 0 None 1 Heal 2 Shells/Bottles 3 Food 4 Expendable 9 Slingers 10 AuthorChoices 11 ItemIDs (table with item id keys)
local RequestType = 0 
local RequestItemID = -1
local RequestCount = 0
local RequestPouchType = 1 -- 1 Box 0 Pouch
local RequestItemIDs = nil

local function HandleItemID(id, num, pouch)
    if id < 0 then return end

    if pouch == 0 then
        ChangePouchItemCount(id, num)
    else
        ChangeItemBoxItemCount(id, num)
    end
end

local function HandleItemType(type, num)
    local itemIds
    if type == 1 then
        itemIds = HealItemIDs
    elseif type == 2 then
        itemIds = ShellItemIDs
    elseif type == 3 then
        itemIds = FoodItemIDs
    elseif type == 4 then
        itemIds = ExpendableIDs
    elseif type == 5 then
        BasicParamUtil:StaticCall("addMoney(System.Int32, System.Boolean)", num, true)
    elseif type == 6 then
        BasicParamUtil:StaticCall("addPoint(System.Int32, System.Boolean)", num, true)
    elseif type == 7 then
        BasicParamUtil:StaticCall("addTicket(System.Int32)", num)
    elseif type == 8 then
        BasicParamUtil:StaticCall("addHunterPoint(System.Int32)", num)
    elseif type == 9 then
        itemIds = SlingerIDs
    elseif type == 10 then
        itemIds = AuthorChoiceItemIDs
    elseif type == 11 then
        itemIds = RequestItemIDs        
        RequestItemIDs = nil
    end

    if itemIds then
        for id, _ in pairs(itemIds) do
            HandleItemID(id, num)
        end
    end
end

mod.HookFunc("app.GUIManager", "update()", function ()
    if RequestCount == 0 then
        return
    end

    local type = RequestType
    local id = RequestItemID
    local num = RequestCount
    local pouch = RequestPouchType

    RequestType = 0
    RequestItemID = -1
    RequestCount = 0
    RequestPouchType = 1

    if type == 0 then
        HandleItemID(id, num, pouch)
    else
        HandleItemType(type, num)
    end
end)

if mod.Config.EditorConf == nil then
    mod.Config.EditorConf = {
        FilterID = 1,
        TypeID = 0,
        RareLv = 0,
        PropID = 0,
        IconType = 0,
        PouchType = 0,
        SlingerType = 0,

        ItemIDIndex = 0,

        AccessoryID = 0,
    }
end

local AccessoryIDMap = Core.GetEnumMap("app.EquipDef.ACCESSORY_ID")
local AccessoryIDNameMap = Core.GetAccessoryNameMap()

local AccFilterType = {
    "All (no filter)",
    "Rarity",
    "Slot Level",
}

local AllAccTable = NewItemTable()

---@type table<app.ItemDef.RARE, EditorItemTable>
local AccRarityTables = {}

---@type table<app.EquipDef.SlotLevel, EditorItemTable>
local AccSlotLevelTables = {}

local AccInited = false
local Get_AccessoryRarity = Core.TypeMethod("app.EquipDef", "Rare(app.EquipDef.ACCESSORY_ID)")
local Get_AccessorySlot = Core.TypeMethod("app.EquipDef", "SlotLevelAcc(app.EquipDef.ACCESSORY_ID)")
local Get_AccessorySort = Core.TypeMethod("app.EquipDef", "SortId(app.EquipDef.ACCESSORY_ID)")

local AccSlotNames = Core.GetEnumMap("app.EquipDef.SlotLevel")

local function InitAccessoryNames()
    if AccInited then
        return
    end

    for id, name in pairs(AccessoryIDNameMap) do
        local rarity = Get_AccessoryRarity:call(nil, id)
        local slot = Get_AccessorySlot:call(nil, id)

        local sort = Get_AccessorySort:call(nil, id)

        local itemData = {
            ID = id,
            RawName = name,
            Name = name,
            SortID = sort,
        }

        -- no filter
        AllAccTable.DataMap[id] = itemData

        -- item type
        if AccRarityTables[rarity] == nil then
            AccRarityTables[rarity] = NewItemTable()
        end
        AccRarityTables[rarity].DataMap[id] = itemData

        -- acc Level
        if AccSlotLevelTables[slot] == nil then
            AccSlotLevelTables[slot] = NewItemTable()
        end
        AccSlotLevelTables[slot].DataMap[id] = itemData
    end

    -- sort items by sort id
    local function _build_tables(itemTables)
        for _, itemTable in pairs(itemTables) do
            BuildSortedItemTable(itemTable)    
        end
    end

    BuildSortedItemTable(AllAccTable)
    _build_tables(AccRarityTables)
    _build_tables(AccSlotLevelTables)

    inited = true
    mod.SaveConfig()

    AccInited = true
end

local function AddAccessory(box, id, num)
    if box == nil or id == nil or id < 0 then
        return
    end

    if num == nil then
        num = 1
    end

    local done = false

    Core.ForEach(box, function (work)
        if work.ID == id then
            work.Num = work.Num + 1
            done = true
            return Core.ForEachBreak
        end
    end)

    if not done then
        Core.ForEach(box, function (work)
            if work.Num == 0 then
                work.ID = id
                work.Num = num
                done = true
                return Core.ForEachBreak
            end
        end)
    end
end

local function GetAccessoryNum(box, id)
    local num = 0

    Core.ForEach(box, function (work)
        if work.ID == id then
            num = work.Num
            return Core.ForEachBreak
        end
    end)

    return num    
end

local function AccessoryEditor()
    local mgr = Core.GetSaveDataManager()
    if not mgr then
        return false
    end
	local configChanged = false
    local changed = false
    local box = mgr:getCurrentUserSaveData()._Equip._AccessoryBox

    InitAccessoryNames()

    imgui.text("")
    imgui.text("Decoration Box Editor")

    Imgui.Rect(function ()
        changed, mod.Config.EditorConf.AccFilterID = imgui.combo("Filter Type##AccFilter", mod.Config.EditorConf.AccFilterID, AccFilterType)
        configChanged = configChanged or changed
    
        ---@type EditorItemTable
        local itemTable
        if mod.Config.EditorConf.AccFilterID == 1 then
            itemTable = AllAccTable
        elseif mod.Config.EditorConf.AccFilterID == 2 then
            changed, mod.Config.EditorConf.AccRarityLv = imgui.combo("Rarity##AccRare", mod.Config.EditorConf.AccRarityLv, ItemRareNames)
            configChanged = configChanged or changed
    
            itemTable = AccRarityTables[mod.Config.EditorConf.AccRarityLv]
        elseif mod.Config.EditorConf.AccFilterID == 3 then
            changed, mod.Config.EditorConf.AccSlotLv = imgui.combo("Slot Level##AccSlotLevel", mod.Config.EditorConf.AccSlotLv, AccSlotNames)
            configChanged = configChanged or changed
    
            itemTable = AccSlotLevelTables[mod.Config.EditorConf.AccSlotLv]
        end

        if itemTable == nil or #itemTable.SortedItemNameArray == 0 then
            imgui.text("This filter has no items")
        else
            changed, mod.Config.EditorConf.AccessoryIDIndex = imgui.combo("Decoration List", mod.Config.EditorConf.AccessoryIDIndex, itemTable.SortedItemNameArray)
            configChanged = configChanged or changed
            
            local selectedAccId = itemTable.SortedItemIDArray[mod.Config.EditorConf.AccessoryIDIndex]

            if selectedAccId then
                local num = GetAccessoryNum(box, selectedAccId)
                imgui.text(string.format("Num: %d", num))

                imgui.same_line()
                if imgui.button("+1##DecoPlus1") then
                    AddAccessory(box, selectedAccId, 1)
                end
                imgui.same_line()
                if imgui.button("+3##DecoPlus3") then
                    AddAccessory(box, selectedAccId, 3)
                end
            end
        end

        imgui.text("")
        Imgui.Tree("Decoration Box", function ()
            Core.ForEach(box, function (work)
                local num = work.Num
                if num <= 0 then
                    return
                end

                local id = work.ID
                local name = AccessoryIDNameMap[id]
                if not name then
                    name = AccessoryIDMap[id]
                end

                imgui.text(string.format("%s: %d", name, num))
                imgui.same_line()
                Imgui.Button(string.format("+1##AddAcc%d", id), function ()
                    work.Num = num + 1
                end)
            end)
        end)
    end)

    return configChanged
end

local numStrItemID = "100"
local numStrBatchAdd = "100"
local numStrMoney = "10000"
local numStrPoint = "10000"
local numStrTicket = "10"
local numStrHunterPoint = "1000"

local STANDALONE_MENU_ENABLED = false

local function DrawItemEditorMenu()
	local configChanged = false
    local changed = false

    -- UI state (search/filter helpers)
    mod.Config.EditorConf = mod.Config.EditorConf or {}
    if mod.Config.EditorConf.SearchText == nil then
        mod.Config.EditorConf.SearchText = ""
    end
    if mod.Config.EditorConf.ListSearchText == nil then
        mod.Config.EditorConf.ListSearchText = ""
    end
    if mod.Config.EditorConf.ListOnlyNonZero == nil then
        mod.Config.EditorConf.ListOnlyNonZero = false
    end
    if mod.Config.EditorConf.ListMaxRows == nil then
        mod.Config.EditorConf.ListMaxRows = 200
    end

    imgui.text("")
    imgui.text("Stats Add")

    imgui.text(string.format("Money: %d", BasicParamUtil:StaticCall("getMoney()")))
    if imgui.button("Add Money") then
        local num = tonumber(numStrMoney)
        if num then
            RequestType = 5
            RequestCount = num
        end
    end
    imgui.same_line()
    _, numStrMoney = imgui.input_text("Add Number##AddMoney", numStrMoney)
    
    imgui.text(string.format("Point: %d", BasicParamUtil:StaticCall("getPoint()")))
    if imgui.button("Add Point") then
        local num = tonumber(numStrPoint)
        if num then
            RequestType = 6
            RequestCount = num
        end
    end
    imgui.same_line()
    _, numStrPoint = imgui.input_text("Add Number##AddPoint", numStrPoint)

    imgui.text(string.format("Ticket: %d", BasicParamUtil:StaticCall("getTicketNum()")))
    if imgui.button("Add Ticket") then
        local num = tonumber(numStrTicket)
        if num then
            RequestType = 7
            RequestCount = num
        end
    end
    imgui.same_line()
    _, numStrTicket = imgui.input_text("Add Number##AddTicket", numStrTicket)

    imgui.text(string.format("HR: %d, HunterPoint: %d", BasicParamUtil:StaticCall("getHunterRank()"), BasicParamUtil:StaticCall("getHunterPoint()")))
    if imgui.button("Add HunterPoint") then
        local num = tonumber(numStrHunterPoint)
        if num then
            RequestType = 8
            RequestCount = num
        end
    end
    imgui.same_line()
    _, numStrHunterPoint = imgui.input_text("Add Number##AddHunterPoint", numStrHunterPoint)
    
    imgui.text("")
    imgui.text("Item Add")

    InitItemNames()

    -- for _, name in pairs(names) do
    --     imgui.text(tostring(name))
    -- end

    changed, mod.Config.EditorConf.FilterID = imgui.combo("Filter Type##ItemFilterType", mod.Config.EditorConf.FilterID, FilterType)
    configChanged = configChanged or changed

    -- Search within the currently selected filter (works around huge combo lists)
    imgui.push_item_width(260)
    changed, mod.Config.EditorConf.SearchText = imgui.input_text("Search (name/id)##ItemSearch", mod.Config.EditorConf.SearchText)
    imgui.pop_item_width()
    configChanged = configChanged or changed
    imgui.same_line()
    if imgui.button("Clear##ClearItemSearch") then
        mod.Config.EditorConf.SearchText = ""
        configChanged = true
    end

    ---@type EditorItemTable
    local itemTable
    if mod.Config.EditorConf.FilterID == 1 then
        itemTable = AllItemTable
    elseif mod.Config.EditorConf.FilterID == 2 then
        changed, mod.Config.EditorConf.TypeID = imgui.combo("Category##ItemCate", mod.Config.EditorConf.TypeID, ItemTypeNames)
        configChanged = configChanged or changed

        itemTable = ItemTypeTables[mod.Config.EditorConf.TypeID]
    elseif mod.Config.EditorConf.FilterID == 3 then
        changed, mod.Config.EditorConf.RareLv = imgui.combo("Rarity##ItemRare", mod.Config.EditorConf.RareLv, ItemRareNames)
        configChanged = configChanged or changed

        itemTable = ItemRarityTables[mod.Config.EditorConf.RareLv]
    elseif mod.Config.EditorConf.FilterID == 4 then
        changed, mod.Config.EditorConf.PropID = imgui.combo("Property##ItemProp", mod.Config.EditorConf.PropID, Properties)
        configChanged = configChanged or changed

        itemTable = ItemPropertyTables[Properties[mod.Config.EditorConf.PropID]]
    elseif mod.Config.EditorConf.FilterID == 5 then
        changed, mod.Config.EditorConf.IconType = imgui.combo("Extra Icon Type##ItemIconType", mod.Config.EditorConf.IconType, NonNilIconNames)
        configChanged = configChanged or changed

        itemTable = ItemExtraIconTables[mod.Config.EditorConf.IconType]
    elseif mod.Config.EditorConf.FilterID == 6 then
        changed, mod.Config.EditorConf.PouchType = imgui.combo("Pouch Type##ItemPouchType", mod.Config.EditorConf.PouchType, PouchTypeNames)
        configChanged = configChanged or changed

        itemTable = ItemPouchTypeTables[mod.Config.EditorConf.PouchType]
    elseif mod.Config.EditorConf.FilterID == 7 then
        itemTable = SlingerItemTable
    elseif mod.Config.EditorConf.FilterID == 8 then
        itemTable = AuthorChoiceItemTable
    end

    local selectedItemID = nil
    if itemTable then
        local nameArray = itemTable.SortedItemNameArray
        local idArray = itemTable.SortedItemIDArray

        local searchText = tostring(mod.Config.EditorConf.SearchText or "")
        if searchText ~= "" then
            local q = searchText:lower()
            local filteredNames = {}
            local filteredIds = {}
            for i = 1, #nameArray do
                local n = tostring(nameArray[i])
                local id = idArray[i]
                if n:lower():find(q, 1, true) or tostring(id):find(searchText, 1, true) then
                    filteredNames[#filteredNames + 1] = nameArray[i]
                    filteredIds[#filteredIds + 1] = id
                end
            end
            nameArray = filteredNames
            idArray = filteredIds
        end

        if #nameArray == 0 then
            imgui.text("This filter has no items")
            selectedItemID = nil
        else
            if mod.Config.EditorConf.ItemIDIndex == nil or mod.Config.EditorConf.ItemIDIndex < 1 then
                mod.Config.EditorConf.ItemIDIndex = 1
            end
            if mod.Config.EditorConf.ItemIDIndex > #nameArray then
                mod.Config.EditorConf.ItemIDIndex = 1
            end

            changed, mod.Config.EditorConf.ItemIDIndex = imgui.combo("Item", mod.Config.EditorConf.ItemIDIndex, nameArray)
            configChanged = configChanged or changed

            selectedItemID = idArray[mod.Config.EditorConf.ItemIDIndex]
        end
    else
        imgui.text("This filter has no items")
        selectedItemID = nil
    end

    if selectedItemID == nil then
        imgui.text("No Item Selected")
    else
        local itemName = itemTable.DataMap[selectedItemID].RawName

        local isInf = IsInfinity(selectedItemID) 
        if isInf then
            imgui.text("Is Infinity")
            
            local editData = mod.Config.ItemConfEditList[tostring(selectedItemID)]
            local makeInfinity = true
            if editData ~= nil then
                makeInfinity = editData.Infinity
            end
            imgui.same_line()
            changed, makeInfinity = imgui.checkbox("Make Infinity", makeInfinity)
            if changed then
                if editData == nil then
                    editData = {}
                end
                editData.Infinity = makeInfinity
                mod.Config.ItemConfEditList[tostring(selectedItemID)] = editData
                ApplyItemEdits()
                configChanged = true
            end
        end
        if not isInf or mod.Config.Debug then
            local num = GetItemBoxItemCount(selectedItemID)
            local capactiy = GetItemBoxItemCapacity(selectedItemID)
        
            local pouchNum = GetPouchItemCount(selectedItemID)
            local pouchCapactiy = GetPouchItemCapacity(selectedItemID)
        
            Imgui.Rect(function ()
                imgui.text("Item Box Edit")
                    
                imgui.text(string.format("%s Num: %d/%d", itemName, num, (num+capactiy)))
    
                imgui.same_line()
                if imgui.button("+1##ItemPlus1") then
                    RequestItemID = selectedItemID
                    RequestCount = 1
                end
    
                imgui.same_line()
                if imgui.button("+5##ItemPlus5") then
                    RequestItemID = selectedItemID
                    RequestCount = 5
                end
    
                imgui.same_line()
                if imgui.button("+50##ItemPlus50") then
                    RequestItemID = selectedItemID
                    RequestCount = 50
                end
    
                imgui.same_line()
                if imgui.button("+100##ItemPlus100") then
                    RequestItemID = selectedItemID
                    RequestCount = 100
                end
    
                imgui.same_line()
                if imgui.button("Add to max##AddItemBoxToMax") then
                    RequestItemID = selectedItemID
                    RequestCount = capactiy
                end
    
                imgui.same_line()
    
                local editData = mod.Config.ItemConfEditList[tostring(selectedItemID)]
                local makeInfinity = false
                if editData ~= nil then
                    makeInfinity = editData.Infinity
                end
                changed, makeInfinity = imgui.checkbox("Make Infinity", makeInfinity)
                if changed then
                    if editData == nil then
                        editData = {}
                    end
                    editData.Infinity = makeInfinity
                    mod.Config.ItemConfEditList[tostring(selectedItemID)] = editData
                    ApplyItemEdits()
                    configChanged = true
                end
    
                if imgui.button("Add##AddItemWithNum") then
                    local num = tonumber(numStrItemID)
                    if num then
                        RequestItemID = selectedItemID
                        RequestCount = num
                    end
                end
                imgui.same_line()
                _, numStrItemID = imgui.input_text("Add Number##AddNumToItemID", numStrItemID)
            end)
    
            Imgui.Rect(function ()
                imgui.text("Pouch Edit")
                    
                imgui.text(string.format("%s Num: %d/%d", itemName, pouchNum, (pouchNum+pouchCapactiy)))
    
                imgui.same_line()
    
                if imgui.button("Add to max##AddPouchToMax") then
                    RequestPouchType = 0
                    RequestItemID = selectedItemID
                    RequestCount = pouchCapactiy
                end
    
                local editData = mod.Config.ItemConfEditList[tostring(selectedItemID)]
                local maxCount = pouchNum+pouchCapactiy
                if editData ~= nil then
                    if editData.MaxCount == nil then
                        editData.MaxCount = maxCount
                    end
                    maxCount = editData.MaxCount
                end
                changed, maxCount = imgui.slider_int("Max Count##CurrentItemMaxCount", maxCount, 1, 9999)
                if changed then
                    if editData == nil then
                        editData = {}
                    end
                    editData.MaxCount = maxCount
                    mod.Config.ItemConfEditList[tostring(selectedItemID)] = editData
                    ApplyItemEdits()
                    configChanged = true
                end
            end)
        end
    end

    if itemTable then
        Imgui.Tree("Show All Filtered Items in Item Box", function ()
            imgui.push_item_width(260)
            changed, mod.Config.EditorConf.ListSearchText = imgui.input_text("Search in list##ListSearch", mod.Config.EditorConf.ListSearchText)
            imgui.pop_item_width()
            configChanged = configChanged or changed
            imgui.same_line()
            if imgui.button("Clear##ClearListSearch") then
                mod.Config.EditorConf.ListSearchText = ""
                configChanged = true
            end

            changed, mod.Config.EditorConf.ListOnlyNonZero = imgui.checkbox("Only show items you have", mod.Config.EditorConf.ListOnlyNonZero)
            configChanged = configChanged or changed

            changed, mod.Config.EditorConf.ListMaxRows = imgui.slider_int("Max rows##ListMaxRows", mod.Config.EditorConf.ListMaxRows, 50, 1000)
            configChanged = configChanged or changed

            local clicked = imgui.button("Add to All Listed Items")
            imgui.same_line()
            _, numStrBatchAdd = imgui.input_text("Batch Add Number", numStrBatchAdd)
    
            if clicked then
                local num = tonumber(numStrBatchAdd)
                if num then
                    RequestType = 11
                    RequestCount = num
                    RequestItemIDs = itemTable.DataMap
                end
            end
    
            local q = tostring(mod.Config.EditorConf.ListSearchText or "")
            local qLower = q:lower()
            local shown = 0
            local maxRows = tonumber(mod.Config.EditorConf.ListMaxRows) or 200
            for _, id in pairs(itemTable.SortedItemIDArray)  do
                if shown >= maxRows then
                    imgui.text(string.format("Showing first %d rows. Refine search to see more.", maxRows))
                    break
                end
                local data = itemTable.DataMap[id]
                if data then
                    local num = GetItemBoxItemCount(id)
                    local capactiy = GetItemBoxItemCapacity(id)
                    local max = num + capactiy
                
                    local isInf = IsInfinity(id) 

                    if mod.Config.EditorConf.ListOnlyNonZero and num <= 0 and not isInf then
                        goto continue_list
                    end

                    if q ~= "" then
                        local raw = tostring(data.RawName or "")
                        if (not raw:lower():find(qLower, 1, true)) and (not tostring(id):find(q, 1, true)) then
                            goto continue_list
                        end
                    end

                    imgui.text(string.format("%s", data.RawName))

                    if isInf then
                        imgui.same_line()
                        imgui.text("Is Inf")
                    end

                    imgui.same_line()
                    local changed, newNum = imgui.slider_int(string.format("Num##%d",id), num, 0, max)
                    if changed then
                        local delta = newNum - num
                        RequestItemID = id
                        RequestCount = delta
                    end

                    shown = shown + 1
                end

                ::continue_list::
            end
        end)
    end

    -- imgui.text("")
    -- Imgui.Rect(function ()
    --     imgui.text("Item Box Batch Item Add")

    --     _, numStrBatchAdd = imgui.input_text("Batch Add Number", numStrBatchAdd)

    --     if imgui.button("Add to All Heal Items") then
    --         local num = tonumber(numStrBatchAdd)
    --         if num then
    --             RequestType = 1
    --             RequestCount = num
    --         end
    --     end

    --     imgui.same_line()
    --     if imgui.button("Add to All Expendables") then
    --         local num = tonumber(numStrBatchAdd)
    --         if num then
    --             RequestType = 4
    --             RequestCount = num
    --         end
    --     end

    --     imgui.same_line()
    --     if imgui.button("Add to All Shells") then
    --         local num = tonumber(numStrBatchAdd)
    --         if num then
    --             RequestType = 2
    --             RequestCount = num
    --         end
    --     end

    --     imgui.same_line()
    --     if imgui.button("Add to All Food") then
    --         local num = tonumber(numStrBatchAdd)
    --         if num then
    --             RequestType = 3
    --             RequestCount = num
    --         end
    --     end

    --     imgui.same_line()
    --     if imgui.button("Add to All Slingers") then
    --         local num = tonumber(numStrBatchAdd)
    --         if num then
    --             RequestType = 9
    --             RequestCount = num
    --         end
    --     end

    --     imgui.same_line()
    --     if imgui.button("Add to All Mod Author Choices") then
    --         local num = tonumber(numStrBatchAdd)
    --         if num then
    --             RequestType = 10
    --             RequestCount = num
    --         end
    --     end
    -- end)

    if mod.Config.Debug and itemTable then
        for id, name in pairs(itemTable) do
            imgui.text(string.format("%s - %d", name, GetItemBoxItemCount(id)))
        end        
    end
    -- local db = Core.GetVariousDataManager()
    -- -- db._Setting._Item._Values

    changed = AccessoryEditor()
    configChanged = configChanged or changed

    return configChanged

end

_G.__MHWS_EDITOR_SUITE = _G.__MHWS_EDITOR_SUITE or {}
_G.__MHWS_EDITOR_SUITE.draw_item_editor = DrawItemEditorMenu

if STANDALONE_MENU_ENABLED then
    mod.Menu(DrawItemEditorMenu)
end
