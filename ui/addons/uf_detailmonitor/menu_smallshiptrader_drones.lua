-- section == cSmallshiptrader_selectdrones
-- param == { 0, 0, trader, ware, object, amount, pilot_pro_hire, pilot_pro_price }
-- param2 == droneplan

local menu = {
	name = "UF_SmallShipTraderDronesMenu",
	transparent = { r = 0, g = 0, b = 0, a = 0 },
	white = { r = 255, g = 255, b = 255, a = 100 },
	red = { r = 255, g = 0, b = 0, a = 100 },
	green = { r = 0, g = 255, b = 0, a = 100 }
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
	menu.units = {}
	menu.capacity = nil
	menu.cargo = {}
	menu.ware = nil
	menu.object = nil
	menu.amount = nil
	menu.shipprice = nil
	menu.pilot_pro_price = nil
	menu.pilot_pro_hire = nil

	menu.infotable = nil
	menu.selecttable = nil
end

-- Menu member functions

function menu.buttonSelect()
	if menu.rowDataMap and menu.rowDataMap[Helper.currentDefaultTableRow] then
		local ware = menu.rowDataMap[Helper.currentDefaultTableRow]
		local macro
		local amount, totalamount = 0, 0
		for _, entry in ipairs(menu.droneplan) do
			totalamount = totalamount + entry[2]
			if entry[3] == ware then
				amount = entry[2]
				macro = entry[1]
			end
		end
		Helper.closeMenuForSubSection(menu, false, "cSmallshiptrader_selectdronesamount", {0, 0, menu.entity, ware, menu.droneplan, menu.capacity - totalamount, menu.cargo[ware] and menu.cargo[ware] - menu.amount * amount + menu.findUnitAmount(macro) or 0, menu.amount, menu.shipprice, menu.capacity})
		menu.droneplan = {}
		menu.cleanup()
	end
end

function menu.buttonEncyclopedia()
	if menu.rowDataMap and menu.rowDataMap[Helper.currentDefaultTableRow] then
		local ware = menu.rowDataMap[Helper.currentDefaultTableRow]
		local macro
		for _, entry in ipairs(menu.droneplan) do
			if entry[3] == ware then
				macro = entry[1]
			end
		end
		Helper.closeMenuForSubSection(menu, false, "gEncyclopedia_object", {0, 0, "shiptypes_xs", macro, false})
		menu.cleanup()
	end
end

function menu.buttonOK()
	local droneprice = 0
	for _, entry in ipairs(menu.droneplan) do
		entry[2] = entry[2] - menu.findUnitAmount(entry[1])
		droneprice = droneprice + entry[2] * GetContainerWarePrice(menu.container, entry[3], false)
	end
	local playerMoney = GetPlayerMoney()
	local price = menu.shipprice + menu.amount * droneprice
	if playerMoney < RoundTotalTradePrice(price) then
		local unitprice = price / menu.amount
		menu.amount = GetNumAffordableTradeItems(playerMoney, unitprice)
		price = menu.amount * unitprice
	end
	if menu.pilot_pro_hire and menu.pilot_pro_price then
		price = price + menu.amount * menu.pilot_pro_price
	end
	-- TODO Seems like this is not the way stock handles prices underflows.
	if playerMoney >= RoundTotalTradePrice(price) then
		TransferPlayerMoneyTo(RoundTotalTradePrice(price), menu.entity)
		if menu.object then
			Helper.closeMenuForSubSection(menu, false, "cSmallshiptrader_drones", { 0, 0, menu.object, menu.droneplan })
		else
			Helper.closeMenuForSubSection(menu, false, "cSmallshiptrader_spawnships", { 0, 0, menu.ware, menu.amount, menu.droneplan, menu.pilot_pro_hire, menu.pilot_pro_price })
		end
		menu.droneplan = {}
	end
	menu.cleanup()
end

function menu.onShowMenu()
	menu.entity = menu.param[3]
	menu.container = GetContextByClass(menu.entity, "container")
	menu.ware = menu.param[4]
	menu.object = menu.param[5]
	menu.amount = menu.param[6]
	menu.pilot_pro_hire = menu.param[7] and menu.param[7] > 0 and true
	menu.pilot_pro_price = menu.param[8] or 0
	menu.droneplan = menu.param2 or ((menu.droneplan and next(menu.droneplan)) and menu.droneplan or {})
	menu.title = ReadText(1001, 4500)
	menu.dronewares = {}
	if menu.ware then
		menu.shipprice = RoundTotalTradePrice(menu.amount * GetContainerWarePrice(menu.container, menu.ware, false))
	else
		menu.shipprice = 0
	end

	-- Title line as one TableView (Entity running the shop)
	local setup = Helper.createTableSetup(menu)

	local name, typestring, typeicon, typename, ownericon = GetComponentData(menu.entity, "name", "typestring", "typeicon", "typename", "ownericon")
	setup:addTitleRow{
		Helper.createIcon(typeicon, false, 255, 255, 255, 100, 0, 0, Helper.headerCharacterIconSize, Helper.headerCharacterIconSize),
		Helper.createFontString(typename .. " " .. name, false, "left", 255, 255, 255, 100, Helper.headerRow1Font, Helper.headerRow1FontSize),
		Helper.createIcon(ownericon, false, 255, 255, 255, 100, 0, 0, Helper.headerCharacterIconSize, Helper.headerCharacterIconSize)	-- text depends on selection
	}
	
	setup:addTitleRow({
		Helper.getEmptyCellDescriptor()
	}, nil, {3})

	local infodesc = setup:createCustomWidthTable({ Helper.scaleX(Helper.headerCharacterIconSize), 0, Helper.scaleX(Helper.headerCharacterIconSize) + 37 }, false, true)
	
	-- Second TableView, rest of the menu (ware list)
	setup = Helper.createTableSetup(menu)

	if menu.ware then
		menu.dronemacros = GetMiningUnitMacros(GetWareData(menu.ware, "component"))
	else
		menu.dronemacros = GetMiningUnitMacros(GetComponentData(menu.object, "macro"))
	end
	for i, k in ipairs(menu.dronemacros) do
		table.insert(menu.dronewares, GetMacroData(k, "ware"))
	end
	
	menu.cargo = GetComponentData(menu.container, "cargo")
	menu.units = {}
	if menu.object then
		menu.units = GetUnitStorageData(menu.object)
		menu.capacity = menu.units.capacity
		for _, entry in ipairs(menu.units) do
			for _, ware in ipairs(menu.dronewares) do
				if entry.macro == GetWareData(ware, "component") then
					entry.ware = ware
					break
				end
			end
			entry.ordered = 0
		end
		if not next(menu.droneplan) then
			for _, entry in ipairs(menu.units) do
				if entry.ware then
					table.insert(menu.droneplan, { entry.macro, entry.amount + entry.ordered, entry.ware })
				end
			end
		end
	else
		if not next(menu.droneplan) then
			local standarddrones = GetStandardUnitMacros(GetWareData(menu.ware, "component"))
			for _, macro in ipairs(standarddrones) do
				for _, ware in ipairs(menu.dronewares) do
					if macro == GetWareData(ware, "component") and (menu.cargo[ware] or 0) >= menu.amount then
						table.insert(menu.droneplan, {macro, 1, ware })
						break
					end
				end
			end
		end
		menu.capacity = GetMacroUnitStorageCapacity(GetWareData(menu.ware, "component"), "", 0, false)
	end
	
	local total = 0
	for _, entry in ipairs(menu.droneplan) do
		total = total + entry[2]
	end

	local selectdesc
	setup:addHeaderRow({ 
		Helper.createFontString(menu.title, false, "left", 255, 255, 255, 100, Helper.headerRow1Font, Helper.headerCharacterRow2FontSize, false, 0, 0, Helper.headerCharacterRow2Height) 
	}, nil, {5})
	setup:addHeaderRow({ 
		ReadText(1001, 8), 
		ReadText(1001, 2935), 
		ReadText(1001, 20), 
		string.format(ReadText(1001, 4503), total, menu.capacity),
		ReadText(1001, 2637)
	})

	local hasdrones = false

	for _, ware in ipairs(menu.dronewares) do
		local name, component = GetWareData(ware, "name", "component")
		local stock = menu.cargo[ware] or 0
		local planned = menu.findDronePlanned(ware)
		local oldamount = menu.findUnitAmount(component)
		local price
		if (planned - oldamount) < 0 then
			price = GetContainerWarePrice(menu.container, ware, true) * 0.8
		else
			price = GetContainerWarePrice(menu.container, ware, false) * 1.0
		end
		local primarypurposename = GetMacroData(component, "primarypurposename")
		if stock > 0 or planned > 0 then
			hasdrones = true
			setup:addSimpleRow({ 
				name .. " [" .. primarypurposename .. "]", 
				Helper.createFontString(ConvertMoneyString(price, false, true, 5, true) .. " " .. ReadText(1001, 101), false, "right"),
				Helper.createFontString(stock - menu.amount * planned + oldamount, false, "right"), 
				Helper.createFontString(planned, false, "right"),
				Helper.createFontString(planned * menu.amount, false, "right")
			}, ware)
			AddKnownItem("shiptypes_xs", component)
		end
	end

	setup:addFillRows(11)
	
	selectdesc = setup:createCustomWidthTable({ 0, 125, 100, 175, 100 }, false, false, true, 1, 0, 0, Helper.tableCharacterOffsety, 500)
	
	-- button table
	setup = Helper.createTableSetup(menu)

	local playerMoney = GetPlayerMoney()

	setup:addTitleRow({
		ReadText(1001, 2003),
		Helper.createFontString(ConvertMoneyString(playerMoney, false, true, nil, true) .. " " .. ReadText(1001, 101), false, "right")
	}, nil, {5, 4})

	local color = menu.white
	local pilot_pro_text = ""
	local pilot_pro_price_total = 0
	
	if menu.ware then
		if menu.shipprice > 0 then
			color = menu.red
		end

		setup:addTitleRow({
			menu.amount .. "x " .. GetWareData(menu.ware, "name"),
			Helper.createFontString(ConvertMoneyString(menu.shipprice, false, true, nil, true) .. " " .. ReadText(1001, 101), false, "right", color.r, color.g, color.b, color.a)
		}, nil, {5, 4})

		if menu.pilot_pro_hire and menu.pilot_pro_price then
			pilot_pro_text = menu.amount .. "x " .. ReadText(80001, 6)
			pilot_pro_price_total = RoundTotalTradePrice(menu.amount * menu.pilot_pro_price)
			color = menu.red
		else
			pilot_pro_text = menu.amount .. "x " .. ReadText(80001, 7)
			color = menu.white
		end

		setup:addTitleRow({
			pilot_pro_text,
			Helper.createFontString(ConvertMoneyString(pilot_pro_price_total, false, true, nil, true) .. " " .. ReadText(1001, 101), false, "right", color.r, color.g, color.b, color.a)
		}, nil, {5, 4})
	end
	
	local droneprice = 0
	local haschanges = false
	for _, entry in ipairs(menu.droneplan) do
		local amount = menu.amount * (entry[2] - menu.findUnitAmount(entry[1]))
		if amount ~= 0 then
			haschanges = true
		end
		droneprice = droneprice + amount * GetContainerWarePrice(menu.container, entry[3], false)
	end

	color = menu.white
	if droneprice > 0 then
		color = menu.red
	elseif droneprice < 0 then
		color = menu.green
	end

	setup:addTitleRow({
		ReadText(1001, 8),
		Helper.createFontString(ConvertMoneyString(droneprice, false, true, nil, true) .. " " .. ReadText(1001, 101), false, "right", color.r, color.g, color.b, color.a)
	}, nil, {5, 4})
	
	setup:addTitleRow({
		ReadText(1001, 2004),
		Helper.createFontString(ConvertMoneyString(playerMoney - menu.shipprice - droneprice - pilot_pro_price_total, false, true, nil, true) .. " " .. ReadText(1001, 101), false, "right")
	}, nil, {5, 4})

	setup:addSimpleRow({ 
		Helper.getEmptyCellDescriptor(),
		Helper.createButton(Helper.createButtonText(ReadText(1001, 2669), "center", Helper.standardFont, 11, 255, 255, 255, 100), nil, false, true, 0, 0, 150, 25, nil, Helper.createButtonHotkey("INPUT_STATE_DETAILMONITOR_B", true)),
		Helper.getEmptyCellDescriptor(),
		Helper.createButton(Helper.createButtonText(ReadText(1001, 2400), "center", Helper.standardFont, 11, 255, 255, 255, 100), nil, false, hasdrones, 0, 0, 150, 25, nil, Helper.createButtonHotkey("INPUT_STATE_DETAILMONITOR_BACK", true)),
		Helper.getEmptyCellDescriptor(),
		Helper.createButton(Helper.createButtonText(ReadText(1001, 3105), "center", Helper.standardFont, 11, 255, 255, 255, 100), nil, false, hasdrones, 0, 0, 150, 25, nil, Helper.createButtonHotkey("INPUT_STATE_DETAILMONITOR_Y", true)),
		Helper.getEmptyCellDescriptor(),
		Helper.createButton(Helper.createButtonText(ReadText(1001, 2701), "center", Helper.standardFont, 11, 255, 255, 255, 100), nil, false, (not menu.object) or haschanges, 0, 0, 150, 25, nil, Helper.createButtonHotkey("INPUT_STATE_DETAILMONITOR_X", true)),
		Helper.getEmptyCellDescriptor()
	}, nil, nil, false, menu.transparent)
	local buttondesc = setup:createCustomWidthTable({48, 150, 48, 150, 0, 150, 48, 150, 48}, false, false, true, 2, menu.ware and 6 or 4, 0, menu.ware and 420 or 470, 0, false)
	
	-- create tableview
	menu.infotable, menu.selecttable, menu.buttontable = Helper.displayThreeTableView(menu, infodesc, selectdesc, buttondesc, false)

	-- set button scripts
	local nooflines = 3

	Helper.setButtonScript(menu, nil, menu.buttontable, menu.ware and 6 or 4, 2, function () return menu.onCloseElement("back") end)
	Helper.setButtonScript(menu, nil, menu.buttontable, menu.ware and 6 or 4, 4, menu.buttonEncyclopedia)
	Helper.setButtonScript(menu, nil, menu.buttontable, menu.ware and 6 or 4, 6, menu.buttonSelect)
	Helper.setButtonScript(menu, nil, menu.buttontable, menu.ware and 6 or 4, 8, menu.buttonOK)

	-- clear descriptors again
	Helper.releaseDescriptors()
end

-- menu.updateInterval = 2.0

function menu.onUpdate()
end

function menu.onRowChanged(row, rowdata)
end

function menu.onSelectElement()
end

function menu.onCloseElement(dueToClose)
	if dueToClose == "close" then
		Helper.closeMenuAndCancel(menu)
		menu.droneplan = {}
		menu.cleanup()
	else
		Helper.closeMenuAndReturn(menu)
		menu.droneplan = {}
		menu.cleanup()
	end
end

function menu.findDronePlanned(ware)
	local component = GetWareData(ware, "component")
	for _, entry in ipairs(menu.droneplan) do
		if entry[1] == component then
			return entry[2]
		end
	end
	table.insert(menu.droneplan, { component, 0, ware })
	return 0
end

function menu.findUnitAmount(macro)
	for _, entry in ipairs(menu.units) do
		if entry.macro == macro then
			return entry.amount + entry.ordered
		end
	end
	return 0
end

init()
