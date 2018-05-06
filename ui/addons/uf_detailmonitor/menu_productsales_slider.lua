-- section == cSmallshiptrader_selectamount
-- param == { 0, 0, entity, ware }


local menu = {
	name = "UF_ProductSalesSliderMenu",
	transparent = { r = 0, g = 0, b = 0, a = 0 },
	white = { r = 255, g = 255, b = 255, a = 100 },
	red = { r = 255, g = 0, b = 0, a = 100 }
}

local function init()
	Menus = Menus or { }
	table.insert(Menus, menu)
	if Helper then
		Helper.registerMenu(menu)
	end
end

function menu.cleanup()
	menu.title = nil
	menu.entity = nil
	menu.container = nil
	menu.ware = nil
	menu.cargo = {}
	menu.unitspace = nil
	menu.pilot_pro_price = nil
	menu.pilot_pro_hire = nil
	
	menu.infotable = nil
	menu.selecttable = nil
end

-- Menu member functions

function menu.checkBoxPilotHire()
	menu.pilot_pro_hire = not menu.pilot_pro_hire
	-- TODO Set config / remember settings.
	menu.update(true)
end

function menu.buttonOK()
	value1, value2, value3, value4 = GetSliderValue(menu.slider)

	if menu.unitspace > 0 then
		Helper.closeMenuForSubSection(menu, false, "cSmallshiptrader_selectdrones", { 0, 0, menu.entity, menu.ware, nil, value1, menu.pilot_pro_hire, menu.pilot_pro_price })
	else
		local playerMoney = GetPlayerMoney()
		local unitprice = GetContainerWarePrice(menu.container, menu.ware, false)
		if menu.pilot_pro_hire and menu.pilot_pro_price > 0 then
			unitprice = unitprice + menu.pilot_pro_price
		end
		local price = RoundTotalTradePrice(value1 * unitprice)
		if playerMoney < price then
			value1 = GetNumAffordableTradeItems(playerMoney, unitprice)
			price = RoundTotalTradePrice(value1 * unitprice)
		end
		TransferPlayerMoneyTo(price, menu.entity)
		Helper.closeMenuForSubSection(menu, false, "cSmallshiptrader_spawnships", { 0, 0, menu.ware, value1, nil, menu.pilot_pro_hire and menu.pilot_pro_price})
	end
	menu.cleanup()
end

function menu.onShowMenu()
	menu.title = ReadText(1001, 1900)
	menu.entity = menu.param[3]
	menu.container = GetContextByClass(menu.entity, "container")
	menu.ware = menu.param[4]
	menu.unitspace = GetMacroUnitStorageCapacity(GetWareData(menu.ware, "component"), "", 0, false)
	-- TODO Get price from some sort of configuration storage?
	--		Or better yet, make it a percentage.
	menu.pilot_pro_price = 250000
	-- TODO Remember setting?
	menu.pilot_pro_hire = false

	-- Title line as one TableView
	local setup = Helper.createTableSetup(menu)

	local name, typestring, typeicon, typename, ownericon, skills, skillsvisible, experienceprogress, neededexperience
		= GetComponentData(menu.entity, "name", "typestring", "typeicon", "typename", "ownericon")
	setup:addTitleRow({
		Helper.createIcon(typeicon, false, 255, 255, 255, 100, 0, 0, Helper.headerCharacterIconSize, Helper.headerCharacterIconSize),
		Helper.createFontString(typename .. " " .. name, false, "left", 255, 255, 255, 100, Helper.headerRow1Font, Helper.headerRow1FontSize),
		Helper.createIcon(ownericon, false, 255, 255, 255, 100, 0, 0, Helper.headerCharacterIconSize, Helper.headerCharacterIconSize)	-- text depends on selection
	}, nil, {1, 3, 1})

	setup:addTitleRow({
		Helper.getEmptyCellDescriptor()
	}, nil, {5})
	
	local selectdesc = setup:createCustomWidthTable({ Helper.scaleX(Helper.headerCharacterIconSize), 0, 200, 200 - Helper.scaleX(Helper.headerCharacterIconSize) - 32, Helper.scaleX(Helper.headerCharacterIconSize) + 37 }, false, true, true, 0, 0, 0, 0)

	-- slider
	local playerMoney = GetPlayerMoney()
	menu.cargo = GetComponentData(menu.container, "cargo")
	local maxamount = menu.cargo[menu.ware] or 0

	local sliderinfo = {
		["background"] = "tradesellbuy_blur", 
		["captionLeft"] = ReadText(1001, 20), 
		["captionCenter"] = GetWareData(menu.ware, "name"), 
		["min"]= 0, 
		["max"] = maxamount,
		["minSelectable"] = 0,
		["maxSelectable"] = math.min(maxamount, GetNumAffordableTradeItems(playerMoney, GetContainerWarePrice(menu.container, menu.ware, false))),
		["zero"] = 0,
		["start"] = 0
	}
	local scale1info = {
		["left"] = maxamount,
		["center"] = true,
		["inverted"] = false,
		["suffix"] = nil
	}
	local scale2info = nil
	local sliderdesc = Helper.createSlider(sliderinfo, scale1info, nil, 1, Helper.sliderOffsetx, Helper.tableCharacterOffsety, ReadText(1026, 1835))

	-- button table
	setup = Helper.createTableSetup(menu)

	-- pilot experience buy option
	local cost_per_hire = ConvertMoneyString(menu.pilot_pro_price, false, true, nil, true) .. " " .. ReadText(1001, 101)
	setup:addSimpleRow({
		Helper.createFontString(string.format(ReadText(80001, 3), cost_per_hire), false, "left"),
		Helper.createCheckBox(menu.pilot_pro_hire, false, nil, true, 71, 2, Helper.standardTextHeight - 4, Helper.standardTextHeight - 4, ReadText(80001, 5))
	}, nil, {7, 2}, false, menu.transparent)

	setup:addTitleRow({
		Helper.createFontString(ReadText(1001, 2003), false, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, ReadText(1026, 1830)),
		Helper.createFontString(ConvertMoneyString(playerMoney, false, true, nil, true) .. " " .. ReadText(1001, 101), false, "right")
	}, nil, {5, 4})
	
	setup:addTitleRow({
		Helper.createFontString(ReadText(1001, 2005), false, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, ReadText(1026, 1836)),
		Helper.createFontString(ConvertMoneyString(0, false, true, nil, true) .. " " .. ReadText(1001, 101), false, "right")
	}, nil, {5, 4})
	
	setup:addTitleRow({
		Helper.createFontString(ReadText(1001, 2004), false, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, ReadText(1026, 1837)),
		Helper.createFontString(ConvertMoneyString(playerMoney, false, true, nil, true) .. " " .. ReadText(1001, 101), false, "right")
	}, nil, {5, 4})

	setup:addSimpleRow({ 
		Helper.getEmptyCellDescriptor(),
		Helper.createButton(Helper.createButtonText(ReadText(1001, 2669), "center", Helper.standardFont, 11, 255, 255, 255, 100), nil, false, true, 0, 0, 150, 25, nil, Helper.createButtonHotkey("INPUT_STATE_DETAILMONITOR_B", true)),
		Helper.getEmptyCellDescriptor(),
		Helper.getEmptyCellDescriptor(),
		Helper.getEmptyCellDescriptor(),
		Helper.getEmptyCellDescriptor(),
		Helper.getEmptyCellDescriptor(),
		Helper.createButton(Helper.createButtonText(menu.unitspace > 0 and ReadText(1001, 2962) or ReadText(1001, 14), "center", Helper.standardFont, 11, 255, 255, 255, 100), nil, false, false, 0, 0, 150, 25, nil, Helper.createButtonHotkey("INPUT_STATE_DETAILMONITOR_A", true), nil, ReadText(1026, 1838)),
		Helper.getEmptyCellDescriptor()
	}, nil, nil, false, menu.transparent)

	local buttondesc = setup:createCustomWidthTable({48, 150, 48, 150, 0, 150, 48, 150, 48}, false, false, true, 2, 5, 0, 440, 0, false)
	
	-- create tableview
	menu.selecttable, menu.buttontable, menu.slider = Helper.displayTwoTableSliderView(menu, selectdesc, buttondesc, sliderdesc, false)

	-- set checkbox scripts
	Helper.setCheckBoxScript(menu, nil, menu.buttontable, 1, 8, menu.checkBoxPilotHire)

	-- set button scripts
	Helper.setButtonScript(menu, nil, menu.buttontable, 5, 2, function () return menu.onCloseElement("back") end)
	Helper.setButtonScript(menu, nil, menu.buttontable, 5, 8, menu.buttonOK)

	-- clear descriptors again
	Helper.releaseDescriptors()
end

-- menu.updateInterval = 1.0

function menu.onUpdate()
	menu.update()
end

function menu.update(forced)
	value1, value2, value3, value4 = GetSliderValue(menu.slider)

	if value1 ~= menu.value or forced then
		menu.value = value1
		if value1 > 0 then
			Helper.removeButtonScripts(menu, menu.buttontable, 5, 8)
			SetCellContent(menu.buttontable, Helper.createButton(Helper.createButtonText(menu.unitspace > 0 and ReadText(1001, 2962) or ReadText(1001, 14), "center", Helper.standardFont, 11, 255, 255, 255, 100), nil, false, true, 0, 0, 150, 25, nil, Helper.createButtonHotkey("INPUT_STATE_DETAILMONITOR_A", true), nil, ReadText(1026, 1838)), 5, 8)
			Helper.setButtonScript(menu, nil, menu.buttontable, 5, 8, menu.buttonOK)
		else
			Helper.removeButtonScripts(menu, menu.buttontable, 5, 8)
			SetCellContent(menu.buttontable, Helper.createButton(Helper.createButtonText(menu.unitspace > 0 and ReadText(1001, 2962) or ReadText(1001, 14), "center", Helper.standardFont, 11, 255, 255, 255, 100), nil, false, false, 0, 0, 150, 25, nil, Helper.createButtonHotkey("INPUT_STATE_DETAILMONITOR_A", true), nil, ReadText(1026, 1838)), 5, 8)
			Helper.setButtonScript(menu, nil, menu.buttontable, 5, 8, menu.buttonOK)
		end
		local playerMoney = GetPlayerMoney()
		Helper.updateCellText(menu.buttontable, 2, 6, ConvertMoneyString(playerMoney, false, true, nil, true) .. " " .. ReadText(1001, 101))
		local totalCost = value1 * GetContainerWarePrice(menu.container, menu.ware, false)
		if menu.pilot_pro_hire and menu.pilot_pro_price > 0 then
			totalCost = totalCost + (value1 * menu.pilot_pro_price)
			Helper.updateCellText(menu.buttontable, 3, 1, ReadText(1001, 2005) .. ReadText(80001, 4))
		else
			Helper.updateCellText(menu.buttontable, 3, 1, ReadText(1001, 2005))
		end
		Helper.updateCellText(menu.buttontable, 3, 6, ConvertMoneyString(totalCost, false, true, nil, true) .. " " .. ReadText(1001, 101), value1 > 0 and menu.red or menu.white)
		Helper.updateCellText(menu.buttontable, 4, 6, ConvertMoneyString(playerMoney - totalCost, false, true, nil, true) .. " " .. ReadText(1001, 101))
	end
end

function menu.onRowChanged(row, rowdata)
end

function menu.onSelectElement()
	menu.buttonOK()
end

function menu.onCloseElement(dueToClose)
	if dueToClose == "close" then
		Helper.closeMenuAndCancel(menu)
		menu.cleanup()
	else
		Helper.closeMenuAndReturn(menu)
		menu.cleanup()
	end
end

init()
