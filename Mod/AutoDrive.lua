
AutoDrive = {};
--
local modItem = ModsUtil.findModItemByModName(g_currentModName);
AutoDrive.Version = (modItem and modItem.version) and modItem.version or "0.0.0";
--
AutoDrive.config_changed = false;
AutoDrive.directory = g_currentModDirectory;

--
function AutoDrive:prerequisitesPresent(specializations)
	return true;
end;

function AutoDrive:delete()
end;

function AutoDrive:MarkChanged()
	AutoDrive.config_changed = true;
	g_currentMission.AutoDrive.handledRecalculation = false;
end;

function AutoDrive:GetChanged()
	return AutoDrive.config_changed;
end;

function AutoDrive:loadMap(name)
	if Steerable.load ~= nil then
		local aNameSearch = {"vehicle.name." .. g_languageShort, "vehicle.name.en", "vehicle.name", "vehicle.storeData.name", "vehicle#type"};
		local orgSteerableLoad = Steerable.load
		Steerable.load = function(self,xmlFile)
			orgSteerableLoad(self,xmlFile)
			for _, sXMLPath in pairs(aNameSearch) do
				self.name = getXMLString(self.xmlFile, sXMLPath);
				if self.name ~= nil then
					break;
				end;
			end;
			if self.name == nil then
				self.name = g_i18n:getText("UNKNOWN")
			end;
		end
	end;

	if g_currentMission.AutoDrive_printedDebug ~= true then
		--DebugUtil.printTableRecursively(g_currentMission, "	:	",0,2);
		print("Map title: " .. g_currentMission.missionInfo.map.title);
		if g_currentMission.missionInfo.savegameDirectory ~= nil then
			print("Savegame location: " .. g_currentMission.missionInfo.savegameDirectory);
		else
			if g_currentMission.missionInfo.savegameIndex ~= nil then
				print("Savegame location via index: " .. getUserProfileAppPath() .. "savegame" .. g_currentMission.missionInfo.savegameIndex);
			else
				print("No savegame located");
			end;
		end;
	end;

	self.loadedMap = g_currentMission.missionInfo.map.title;
	self.loadedMap = string.gsub(self.loadedMap, " ", "_");
	self.loadedMap = string.gsub(self.loadedMap, "%.", "_");
	g_currentMission.autoLoadedMap = self.loadedMap;

	print("map " .. self.loadedMap .. " was loaded");
end;

function AutoDrive.writeWaypointsAndMarkers(adXml, tagName)
	local idFullTable = {};
	local xTable = {};
	local yTable = {};
	local zTable = {};
	local outTable = {};
	local incomingTable = {};
	local out_costTable = {};
	local markerNamesTable = {};
	local markerIDsTable = {};

	for i,wp in pairs(g_currentMission.AutoDrive.mapWayPoints) do
		idFullTable[i] = wp.id;

		xTable[i] = ("%.2f"):format(wp.x);
		yTable[i] = ("%.2f"):format(wp.y);
		zTable[i] = ("%.2f"):format(wp.z);

		outTable[i] = table.concat(wp.out, ",");
		out_costTable[i] = table.concat(wp.out_cost, ",");

		local innerIncomingTable = {};
		local innerIncomingCounter = 1;
		for _, p2 in pairs(g_currentMission.AutoDrive.mapWayPoints) do
			for _, out2 in pairs(p2.out) do
				if out2 == wp.id then
					innerIncomingTable[innerIncomingCounter] = p2.id;
					innerIncomingCounter = innerIncomingCounter + 1;
				end;
			end;
		end;
		incomingTable[i] = table.concat(innerIncomingTable, ",")

		local markerCounter = 1
		local innerMarkerNamesTable = {}
		local innerMarkerIDsTable = {}
		for i2,marker in pairs(wp.marker) do
			innerMarkerIDsTable[markerCounter] = marker
			innerMarkerNamesTable[markerCounter] = i2
			markerCounter = markerCounter + 1
		end
		markerNamesTable[i] = table.concat(innerMarkerNamesTable, ",")
		markerIDsTable[i] = table.concat(innerMarkerIDsTable, ",")
	end

	if idFullTable[1] ~= nil then
		local tagName2 = tagName .. ".waypoints"
		setXMLString(adXml, tagName2 .. ".id" , table.concat(idFullTable, ",") );
		setXMLString(adXml, tagName2 .. ".x" , table.concat(xTable, ","));
		setXMLString(adXml, tagName2 .. ".y" , table.concat(yTable, ","));
		setXMLString(adXml, tagName2 .. ".z" , table.concat(zTable, ","));
		setXMLString(adXml, tagName2 .. ".out" , table.concat(outTable, ";"));
		setXMLString(adXml, tagName2 .. ".incoming" , table.concat(incomingTable, ";") );
		setXMLString(adXml, tagName2 .. ".out_cost" , table.concat(out_costTable, ";"));
		if markerIDsTable[1] ~= nil then
			setXMLString(adXml, tagName2 .. ".markerID" , table.concat(markerIDsTable, ";"));
			setXMLString(adXml, tagName2 .. ".markerNames" , table.concat(markerNamesTable, ";"));
		end;
	end;

	local tagName2 = tagName .. ".mapmarker"
	for i,mm in pairs(g_currentMission.AutoDrive.mapMarker) do
		setXMLInt(   adXml, tagName2 .. ".mm".. i ..".id",   mm.id);
		setXMLString(adXml, tagName2 .. ".mm".. i ..".name", mm.name);
	end;
end

function AutoDrive.readWaypointsAndMarkers(adXml, tagName)
	local tagName2 = tagName ".waypoints"

	local idTable = Utils.splitString("," , getXMLString(adXml, tagName2 .. ".id"))
	local xTable  = Utils.splitString("," , getXMLString(adXml, tagName2 .. ".x"))
	local yTable  = Utils.splitString("," , getXMLString(adXml, tagName2 .. ".y"))
	local zTable  = Utils.splitString("," , getXMLString(adXml, tagName2 .. ".z"))

	local function splitIntoArrays(wholeText)
		local splitted = {}
		for i, part in pairs(Utils.splitString(";" , wholeText) do
			splitted[i] = Utils.splitString("," , part)
		end;
		return splitted
	end

	local outSplitted         = splitIntoArrays( getXMLString(adXml, tagName2 .. ".out") )
	local incomingSplitted    = splitIntoArrays( getXMLString(adXml, tagName2 .. ".incoming") )
	local out_costSplitted    = splitIntoArrays( getXMLString(adXml, tagName2 .. ".out_cost") )
	local markerIDSplitted    = splitIntoArrays( getXMLString(adXml, tagName2 .. ".markerID") )
	local markerNamesSplitted = splitIntoArrays( getXMLString(adXml, tagName2 .. ".markerNames") )

	local wp_counter = 0;
	for i, id in pairs(idTable) do
		if id ~= "" then
			local out = {}
			for i2,outString in pairs(outSplitted[i]) do
				out[i2] = tonumber(outString)
			end

			local incoming = {}
			local incoming_counter = 1
			for i2, incomingID in pairs(incomingSplitted[i]) do
				if incomingID ~= "" then
					incoming[incoming_counter] = tonumber(incomingID)
				end
				incoming_counter = incoming_counter +1
			end

			local out_cost = {}
			for i2,out_costString in pairs(out_costSplitted[i]) do
				out_cost[i2] = tonumber(out_costString)
			end

			local marker = {}
			for i2, markerName in pairs(markerNamesSplitted[i]) do
				if markerName ~= "" then
					marker[markerName] = tonumber(markerIDSplitted[i][i2])
				end
			end

			local wp = {
				id = tonumber(id)
				,x = tonumber(xTable[i])
				,y = tonumber(yTable[i])
				,z = tonumber(zTable[i])
				,out = out
				,incoming = incoming
				,out_cost = out_cost
				,marker = marker
			}
			wp_counter = wp_counter + 1
			g_currentMission.AutoDrive.mapWayPoints[wp_counter] = wp
		end
	end

	if g_currentMission.AutoDrive.mapWayPoints[wp_counter] ~= nil then
		print("AD: Loaded Waypoints: " .. wp_counter);
		g_currentMission.AutoDrive.mapWayPointsCounter = wp_counter;
	else
		g_currentMission.AutoDrive.mapWayPointsCounter = 0;
	end;

	--
	local tagName3 = tagName .. ".mapmarker"
	local mapMarkerCounter = 0
	while true do
		local mapMarker = {}
		mapMarker.id   = getXMLFloat( adXml, tagName3 .. ".mm"..mapMarkerCounter..".id");
		mapMarker.name = getXMLString(adXml, tagName3 .. ".mm"..mapMarkerCounter..".name");
		if mapMarker.id == nil or mapMarker.name == nil then
			break
		end

		mapMarker.node = createTransformGroup(mapMarker.name);
		local wp = g_currentMission.AutoDrive.mapWayPoints[mapMarker.id]
		setTranslation(mapMarker.node, wp.x, wp.y + 4, wp.z);

		mapMarkerCounter = mapMarkerCounter + 1;
		g_currentMission.AutoDrive.mapMarker[mapMarkerCounter] = mapMarker;
	end;
	g_currentMission.AutoDrive.mapMarkerCounter = mapMarkerCounter
end

function AutoDrive:deleteMap()
	if AutoDrive:GetChanged() == true and g_server ~= nil then
		if g_currentMission.AutoDrive.adXml ~= nil then
			local adXml = g_currentMission.AutoDrive.adXml;

			setXMLString(adXml, "AutoDrive.Version", AutoDrive.Version);
			setXMLBool(  adXml, "AutoDrive.Recalculation", not g_currentMission.AutoDrive.handledRecalculation)

			local tagName = "AutoDrive." .. self.loadedMap
			AutoDrive.writeWaypointsAndMarkers(adXml, tagName)

			saveXMLFile(adXml);
		end;
	end;
end;

function AutoDrive:load(xmlFile)
	if g_currentMission.AutoDrive == nil then
		--print("not present");
		g_currentMission.AutoDrive = {};
		g_currentMission.AutoDrive.mapWayPoints = {};
		g_currentMission.AutoDrive.mapWayPointsCounter = 1;
		g_currentMission.AutoDrive.mapMarker = {};
		g_currentMission.AutoDrive.mapMarkerCounter = 0;
		g_currentMission.AutoDrive.showMouse = false;

		--loading savefile
		local adXml;
		local path = g_currentMission.missionInfo.savegameDirectory --getUserProfileAppPath();
		local file = "";
		if path ~= nil then
			file = path .."/AutoDrive_config.xml";
		else
			file = getUserProfileAppPath() .. "savegame" .. g_currentMission.missionInfo.savegameIndex  .. "/AutoDrive_config.xml";
		end;
		local tempXml = nil;

		if fileExists(file) then
			print("AD: Loading xml file from " .. file);
			g_currentMission.AutoDrive.xmlSaveFile = file;
			adXml = loadXMLFile("AutoDrive_XML", file);--, "AutoDrive");

			local VersionCheck = getXMLString(adXml, "AutoDrive.version");
			local MapCheck = hasXMLProperty(adXml, "AutoDrive." .. g_currentMission.autoLoadedMap );
			if VersionCheck == nil or MapCheck == false then --or VersionCheck ~= AutoDrive.Version
				print("AD: Version Check or Map check failed - Loading init config");
				--[[
				print("AD: Saving your config as backup_config");

				infile = io.open(file, "r")
				instr = infile:read("*a")
				infile:close()

				if path ~= nil then
					file = path .."/AutoDrive_config.xml";
				else
					file = getUserProfileAppPath() .. "savegame" .. g_currentMission.missionInfo.savegameIndex  .. "/AutoDrive_backup_config.xml";
				end;

				outfile = io.open(file, "w")
				outfile:write(instr)
				outfile:close()
				--]]

				path = getUserProfileAppPath();
				file = path .. "/mods/FS17_AutoDrive/AutoDrive_init_config.xml";

				tempXml = loadXMLFile("AutoDrive_XML_temp", file);--, "AutoDrive");
				local MapCheckInit= hasXMLProperty(tempXml, "AutoDrive." .. g_currentMission.autoLoadedMap );
				if MapCheckInit == false then
					print("AD: Init config does not contain any information for this map. Existing Config will not be overwritten");
					tempXml = nil;
				end;

				--local tempstring = saveXMLFileToMemory(tempXml);
				--adXml = loadXMLFileFromMemory("AutoDrive_XML", tempstring);
				print("AD: Finished loading xml from memory");

				--AutoDrive:MarkChanged();
			end;

			--print("Finished loading xml");

		else --create std file instead:
			path = getUserProfileAppPath();
			file = path .. "/mods/FS17_AutoDrive/AutoDrive_init_config.xml";

			print("AD: Loading xml file from init config");
			tempXml = loadXMLFile("AutoDrive_XML_temp", file);--, "AutoDrive");
			--local tempstring = saveXMLFileToMemory(tempXml);
			--adXml = loadXMLFileFromMemory("AutoDrive_XML", tempstring);
			print("AD: Finished loading xml from memory");

			AutoDrive:MarkChanged();

			path = g_currentMission.missionInfo.savegameDirectory -- getUserProfileAppPath();
			if path ~= nil then
				file = path .."/AutoDrive_config.xml";
			else
				file = getUserProfileAppPath() .. "savegame" .. g_currentMission.missionInfo.savegameIndex  .. "/AutoDrive_config.xml";
			end;
			print("AD: creating xml file at " .. file);
			adXml = createXMLFile("AutoDrive_XML", file, "AutoDrive");

			saveXMLFile(adXml);
			g_currentMission.AutoDrive.xmlSaveFile = file;
		end;

		local backupXml = false;
		if adXml ~= nil then
			--print("Loading waypoints");
			if tempXml ~= nil then
				print("Loading from init file");
				backupXml = true;
				path = getUserProfileAppPath();
				file = path .. "/mods/FS17_AutoDrive/AutoDrive_init_config.xml";
				adXml = loadXMLFile("AutoDrive_XML_temp", file);--, "AutoDrive");
			end;
			g_currentMission.AutoDrive.adXml = adXml;
			--print("retrieving waypoints");
			--print("map " .. g_currentMission.autoLoadedMap .. " waypoints are loaded");
			self.loadedMap = g_currentMission.autoLoadedMap;
			if self.loadedMap ~= nil then
				local tagName = "AutoDrive." .. self.loadedMap
				AutoDrive.readWaypointsAndMarkers(adXml, tagName)
			end;

			local recalculate = getXMLBool(adXml, "AutoDrive.Recalculation");

			if recalculate == true then
				for _, point in pairs(g_currentMission.AutoDrive.mapWayPoints) do
					point.marker = {};
				end;

				print("AD: recalculating routes");
				for _, marker in pairs(g_currentMission.AutoDrive.mapMarker) do
					local tempAD = AutoDrive:dijkstra(g_currentMission.AutoDrive.mapWayPoints, marker.id, "incoming");
					for _, point in pairs(g_currentMission.AutoDrive.mapWayPoints) do
						point.marker[marker.name] = tempAD.pre[point.id];
					end;
				end;

				setXMLBool(adXml, "AutoDrive.Recalculation", false);
				AutoDrive:MarkChanged();
				g_currentMission.AutoDrive.handledRecalculation = true;
			else
				print("AD: Routes are already calculated");
			end;

			if backupXml == true then
				--print("Switching back to correct xml");
				path = g_currentMission.missionInfo.savegameDirectory --getUserProfileAppPath();
				local file = "";
				if path ~= nil then
					file = path .."/AutoDrive_config.xml";
					adXml = loadXMLFile("AutoDrive_XML", file);--, "AutoDrive");
				else
					file = getUserProfileAppPath() .. "savegame" .. g_currentMission.missionInfo.savegameIndex  .. "/AutoDrive_config.xml";
					print("AD: creating xml file at " .. file);
					adXml = createXMLFile("AutoDrive_XML", file, "AutoDrive");

					saveXMLFile(adXml);
				end;
				g_currentMission.AutoDrive.adXml = adXml;
			end;

		end;
		AutoDrive:loadHud();
	end;

	--
	AutoDrive.Triggers = {};
	AutoDrive.Triggers.tipTriggers = {};
	AutoDrive.Triggers.siloTriggers = {};

	for _,trigger in pairs(g_currentMission.tipTriggers) do
		local triggerLocation = {};
		local x,y,z = getWorldTranslation(trigger.rootNode);
		triggerLocation.x = x;
		triggerLocation.y = y;
		triggerLocation.z = z;
		--print("trigger: " .. trigger.stationName .. " pos: " .. x .. "/" .. y .. "/" .. z);
	end;
end;

function AutoDrive:loadHud()

	if VehicleCamera.AutoDriveInserted == nil then
		VehicleCamera.mouseEvent = Utils.overwrittenFunction(VehicleCamera.mouseEvent, AutoDrive.newMouseEvent);
		print("AutoDrive mod inserted into Vehicle Camera")
		VehicleCamera.AutoDriveInserted = true;
	end;


	AutoDrive.Hud = {};
	AutoDrive.Hud.Speed = "40";
	AutoDrive.Hud.Target = "Not Ready"
	AutoDrive.Hud.showHud = true;
	if g_currentMission.AutoDrive.mapMarker[1] ~= nil then
		AutoDrive.Hud.Target = g_currentMission.AutoDrive.mapMarker[1].name;
	end;


	AutoDrive.Hud.Background = {};
	AutoDrive.Hud.Buttons = {};
	AutoDrive.Hud.buttonCounter = 0;
	AutoDrive.Hud.rows = 1;
	AutoDrive.Hud.rowCurrent = 1;
	AutoDrive.Hud.cols = 9;
	AutoDrive.Hud.colCurrent = 1;

	local uiScale = g_gameSettings:getValue("uiScale")
	local numButtons = 9
	local buttonSize = 22
	local gapSize = 3
	AutoDrive.Hud.borderX,      AutoDrive.Hud.borderY       = getNormalizedScreenValues(uiScale * gapSize,    uiScale * gapSize)
	AutoDrive.Hud.buttonWidth,  AutoDrive.Hud.buttonHeight  = getNormalizedScreenValues(uiScale * buttonSize, uiScale * buttonSize)
	AutoDrive.Hud.width,        AutoDrive.Hud.height        = getNormalizedScreenValues((numButtons * (gapSize+buttonSize) + gapSize)*uiScale, 120*uiScale)
	AutoDrive.Hud.posX   = (g_currentMission.vehicleHudBg.x + g_currentMission.vehicleHudBg.width)  - AutoDrive.Hud.width
	AutoDrive.Hud.posY   = (g_currentMission.vehicleHudBg.y + g_currentMission.vehicleHudBg.height) + AutoDrive.Hud.buttonHeight

	local img1 = Utils.getNoNil("img/Background.dds", "empty.dds" )
	local state, result = pcall( Utils.getFilename, img1, AutoDrive.directory )
	if not state then
		print("ERROR: "..tostring(result).." (img1: "..tostring(img1)..")")
		return
	end
	AutoDrive.Hud.Background.img = result;
	AutoDrive.Hud.Background.ov = Overlay:new(nil, result, AutoDrive.Hud.posX, AutoDrive.Hud.posY , AutoDrive.Hud.width, AutoDrive.Hud.height);
	AutoDrive.Hud.Background.posX = AutoDrive.Hud.posX;
	AutoDrive.Hud.Background.posY = AutoDrive.Hud.posY;
	AutoDrive.Hud.Background.width = AutoDrive.Hud.width;
	AutoDrive.Hud.Background.height = AutoDrive.Hud.height;

	local img_tipper = Utils.getNoNil("img/tipper_overlay.dds", "empty.dds" )
	local state_tipper, result_tipper = pcall( Utils.getFilename, img_tipper, AutoDrive.directory )
	if not state_tipper then
		print("ERROR: "..tostring(result_tipper).." (img_tipper: "..tostring(img_tipper)..")")
		return
	end
	AutoDrive.Hud.Background.unloadOverlay = {};
	AutoDrive.Hud.Background.unloadOverlay.posX = AutoDrive.Hud.posX + 0.0025;
	AutoDrive.Hud.Background.unloadOverlay.posY = AutoDrive.Hud.posY + AutoDrive.Hud.height - 0.074;
	AutoDrive.Hud.Background.unloadOverlay.width = 0.015;
	AutoDrive.Hud.Background.unloadOverlay.height = AutoDrive.Hud.Background.unloadOverlay.width * (g_screenWidth / g_screenHeight);
	AutoDrive.Hud.Background.unloadOverlay.img = result_tipper;
	AutoDrive.Hud.Background.unloadOverlay.ov = Overlay:new(nil , AutoDrive.Hud.Background.unloadOverlay.img, AutoDrive.Hud.Background.unloadOverlay.posX,	AutoDrive.Hud.Background.unloadOverlay.posY , AutoDrive.Hud.Background.unloadOverlay.width, AutoDrive.Hud.Background.unloadOverlay.height);

	local img1 = Utils.getNoNil("img/Header.dds", "empty.dds" )
	local state, result = pcall( Utils.getFilename, img1, AutoDrive.directory )
	if not state then
		print("ERROR: "..tostring(result).." (img1: "..tostring(img1)..")")
		return
	end
	AutoDrive.Hud.Background.Header = {};
	AutoDrive.Hud.Background.Header.img = result;
	AutoDrive.Hud.Background.Header.width = AutoDrive.Hud.width;
	AutoDrive.Hud.Background.Header.height = 0.016;
	AutoDrive.Hud.Background.Header.posX = AutoDrive.Hud.posX;
	AutoDrive.Hud.Background.Header.posY = AutoDrive.Hud.posY + AutoDrive.Hud.height - AutoDrive.Hud.Background.Header.height;
	AutoDrive.Hud.Background.Header.ov = Overlay:new(nil, result, AutoDrive.Hud.Background.Header.posX, AutoDrive.Hud.Background.Header.posY ,	AutoDrive.Hud.Background.Header.width, AutoDrive.Hud.Background.Header.height);

	local img1 = Utils.getNoNil("img/destination.dds", "empty.dds" )
	local state, result = pcall( Utils.getFilename, img1, AutoDrive.directory )
	if not state then
		print("ERROR: "..tostring(result).." (img1: "..tostring(img1)..")")
		return
	end
	AutoDrive.Hud.Background.destination = {};
	AutoDrive.Hud.Background.destination.img = result;
	AutoDrive.Hud.Background.destination.width = 0.018;
	AutoDrive.Hud.Background.destination.height = AutoDrive.Hud.Background.destination.width * (g_screenWidth / g_screenHeight);
	AutoDrive.Hud.Background.destination.posX = AutoDrive.Hud.posX;
	AutoDrive.Hud.Background.destination.posY = AutoDrive.Hud.posY + AutoDrive.Hud.height - AutoDrive.Hud.Background.Header.height -	AutoDrive.Hud.Background.destination.height - 0.001;
	AutoDrive.Hud.Background.destination.ov = Overlay:new(nil, result, AutoDrive.Hud.Background.destination.posX, AutoDrive.Hud.Background.destination.posY ,	AutoDrive.Hud.Background.destination.width, AutoDrive.Hud.Background.destination.height);

	local img1 = Utils.getNoNil("img/speedmeter.dds", "empty.dds" )
	local state, result = pcall( Utils.getFilename, img1, AutoDrive.directory )
	if not state then
		print("ERROR: "..tostring(result).." (img1: "..tostring(img1)..")")
		return
	end
	AutoDrive.Hud.Background.speedmeter = {};
	AutoDrive.Hud.Background.speedmeter.img = result;
	AutoDrive.Hud.Background.speedmeter.width = 0.019;
	AutoDrive.Hud.Background.speedmeter.height = AutoDrive.Hud.Background.speedmeter.width * (g_screenWidth / g_screenHeight);
	AutoDrive.Hud.Background.speedmeter.posX = AutoDrive.Hud.posX + AutoDrive.Hud.width - 0.04;
	AutoDrive.Hud.Background.speedmeter.posY = AutoDrive.Hud.posY + AutoDrive.Hud.height - AutoDrive.Hud.Background.Header.height -	AutoDrive.Hud.Background.speedmeter.height + 0.001;
	AutoDrive.Hud.Background.speedmeter.ov = Overlay:new(nil, result, AutoDrive.Hud.Background.speedmeter.posX, AutoDrive.Hud.Background.speedmeter.posY ,	AutoDrive.Hud.Background.speedmeter.width, AutoDrive.Hud.Background.speedmeter.height);

	local img1 = Utils.getNoNil("img/close_small.dds", "empty.dds" )
	local state, result = pcall( Utils.getFilename, img1, AutoDrive.directory )
	if not state then
		print("ERROR: "..tostring(result).." (img1: "..tostring(img1)..")")
		return
	end
	AutoDrive.Hud.Background.close_small = {};
	AutoDrive.Hud.Background.close_small.img = result;
	AutoDrive.Hud.Background.close_small.width = 0.01;
	AutoDrive.Hud.Background.close_small.height = AutoDrive.Hud.Background.close_small.width * (g_screenWidth / g_screenHeight);
	AutoDrive.Hud.Background.close_small.posX = AutoDrive.Hud.posX + AutoDrive.Hud.width - 0.0101;
	AutoDrive.Hud.Background.close_small.posY = AutoDrive.Hud.posY + AutoDrive.Hud.height - 0.0101* (g_screenWidth / g_screenHeight);
	AutoDrive.Hud.Background.close_small.ov = Overlay:new(nil, result, AutoDrive.Hud.Background.close_small.posX, AutoDrive.Hud.Background.close_small.posY ,	AutoDrive.Hud.Background.close_small.width, AutoDrive.Hud.Background.close_small.height);

	local img1 = Utils.getNoNil("img/divider.dds", "empty.dds" )
	local state, result = pcall( Utils.getFilename, img1, AutoDrive.directory )
	if not state then
		print("ERROR: "..tostring(result).." (img1: "..tostring(img1)..")")
		return
	end
	AutoDrive.Hud.Background.divider = {};
	AutoDrive.Hud.Background.divider.img = result;
	AutoDrive.Hud.Background.divider.width = AutoDrive.Hud.width;
	AutoDrive.Hud.Background.divider.height = 0.001
	AutoDrive.Hud.Background.divider.posX = AutoDrive.Hud.posX;
	AutoDrive.Hud.Background.divider.posY = AutoDrive.Hud.posY + AutoDrive.Hud.Background.height - 0.045;
	AutoDrive.Hud.Background.divider.ov = Overlay:new(nil, result, AutoDrive.Hud.Background.divider.posX, AutoDrive.Hud.Background.divider.posY ,	AutoDrive.Hud.Background.divider.width, AutoDrive.Hud.Background.divider.height);

	--[[
	AutoDrive.Hud.Background.target = {};
	img1 = Utils.getNoNil("img/ADHud_new.dds", "empty.dds" )
	state, result = pcall( Utils.getFilename, img1, AutoDrive.directory )
	if not state then
		print("ERROR: "..tostring(result).." (img1: "..tostring(img1)..")")
		return
	end
	AutoDrive.Hud.Background.target.ov = Overlay:new(nil, result, AutoDrive.Hud.posX, AutoDrive.Hud.posY , AutoDrive.Hud.width, AutoDrive.Hud.height);
	AutoDrive.Hud.Background.target.posX = AutoDrive.Hud.posX;
	AutoDrive.Hud.Background.target.posY = AutoDrive.Hud.posY;
	AutoDrive.Hud.Background.target.width = AutoDrive.Hud.width;
	AutoDrive.Hud.Background.height = AutoDrive.Hud.height;
	AutoDrive.Hud.Background.img = result;
	--]]

	AutoDrive:AddButton("input_start_stop", "on.dds", "off.dds", "input_ADEnDisable", false, true);
	AutoDrive:AddButton("input_previousTarget", "previousTarget.dds", "previousTarget.dds", "input_ADSelectPreviousTarget", true, true);
	AutoDrive:AddButton("input_nextTarget", "nextTarget.dds", "nextTarget.dds","input_ADSelectTarget", true, true);
	AutoDrive:AddButton("input_record", "record_on.dds", "record_off.dds","input_ADRecord", false, true);
	AutoDrive:AddButton("input_silomode", "silomode_on.dds", "silomode_off.dds","input_ADSilomode", false, true);
	AutoDrive:AddButton("input_decreaseSpeed", "decreaseSpeed.dds", "decreaseSpeed.dds","input_AD_Speed_down", true, true);
	AutoDrive:AddButton("input_increaseSpeed", "increaseSpeed.dds", "increaseSpeed.dds","input_AD_Speed_up", true, true);
	AutoDrive:AddButton("input_continue", "continue.dds", "continue.dds","input_AD_continue", true, true);
	AutoDrive:AddButton("input_debug", "debug_on.dds", "debug_off.dds","input_ADActivateDebug", false, true);

	--AutoDrive:AddButton("input_showClosest", "showClosest_on.dds", "showClosest_off.dds", false, false);
	AutoDrive:AddButton("input_recalculate", "recalculate.dds", "recalculate_on.dds","input_ADDebugForceUpdate", true, false);
	AutoDrive:AddButton("input_previousTarget_Unload", "previousTarget_Unload.dds", "previousTarget_Unload.dds", "input_ADSelectTargetUnload", true, true);
	AutoDrive:AddButton("input_nextTarget_Unload", "nextTarget_Unload.dds", "nextTarget_Unload.dds","input_ADSelectPreviousTargetUnload", true, true);
	AutoDrive:AddButton("input_showNeighbor", "showNeighbor_on.dds", "showNeighbor_off.dds","input_ADDebugSelectNeighbor", false, false);
	AutoDrive:AddButton("input_nextNeighbor", "nextNeighbor.dds", "nextNeighbor.dds","input_ADDebugChangeNeighbor", true, false);
	AutoDrive:AddButton("input_toggleConnection", "toggleConnection.dds", "toggleConnection.dds","input_ADDebugCreateConnection", true, false);
	AutoDrive:AddButton("input_createMapMarker", "createMapMarker.dds", "createMapMarker.dds","input_ADDebugCreateMapMarker", true, false);
	AutoDrive:AddButton("input_removeWaypoint", "deleteWaypoint.dds", "deleteWaypoint.dds","input_ADDebugDeleteWayPoint", true, false);
	AutoDrive:AddButton("input_exportRoutes", "save_symbol.dds", "save_symbol.dds","input_AD_export_routes", true, false);
	--AutoDrive:AddButton("input_toggleHud", "close.dds", "close.dds", true, true);

end;

function AutoDrive:AddButton(name, img, img2, toolTip, on, visible)

	AutoDrive.Hud.buttonCounter = AutoDrive.Hud.buttonCounter + 1;
	AutoDrive.Hud.colCurrent = AutoDrive.Hud.buttonCounter % AutoDrive.Hud.cols;
	if AutoDrive.Hud.colCurrent == 0 then
		AutoDrive.Hud.colCurrent = AutoDrive.Hud.cols;
	end;
	AutoDrive.Hud.rowCurrent = math.ceil(AutoDrive.Hud.buttonCounter / AutoDrive.Hud.cols);

	--
	local btn = {};

	local buttonImg = Utils.getNoNil("img/" .. img, "empty.dds" )
	local state, result = pcall( Utils.getFilename, buttonImg, AutoDrive.directory )
	if not state then
		print("ERROR: "..tostring(result).." (buttinImg: "..tostring(buttinImg)..")")
		return
	end
	btn.posX = AutoDrive.Hud.posX + AutoDrive.Hud.colCurrent * AutoDrive.Hud.borderX + (AutoDrive.Hud.colCurrent - 1) * AutoDrive.Hud.buttonWidth;
	btn.posY = AutoDrive.Hud.posY + AutoDrive.Hud.rowCurrent * AutoDrive.Hud.borderY + (AutoDrive.Hud.rowCurrent - 1) * AutoDrive.Hud.buttonHeight;
	btn.width = AutoDrive.Hud.buttonWidth;
	btn.height = AutoDrive.Hud.buttonHeight;
	btn.name = name;
	btn.img_on = result;
	btn.isVisible = visible;
	btn.toolTip = string.sub(g_i18n:getText(toolTip),4,string.len(g_i18n:getText(toolTip)))

	if img2 ~= nil then
		buttonImg = Utils.getNoNil("img/" .. img2, "empty.dds" )
		state, result = pcall( Utils.getFilename, buttonImg, AutoDrive.directory )
		if not state then
			print("ERROR: "..tostring(result).." (buttinImg: "..tostring(buttinImg)..")")
			return
		end
		btn.img_off = result;
	else
		btn.img_off = nil;
	end;

	if name == "input_silomode" then
		buttonImg = Utils.getNoNil("img/" .. "unload.dds", "empty.dds" )
		state, result = pcall( Utils.getFilename, buttonImg, AutoDrive.directory )
		if not state then
			print("ERROR: "..tostring(result).." (buttinImg: "..tostring(buttinImg)..")")
			return
		end
		btn.img_3 = result;
	end;
	if name == "input_record" then
		buttonImg = Utils.getNoNil("img/" .. "record_dual.dds", "empty.dds" )
		state, result = pcall( Utils.getFilename, buttonImg, AutoDrive.directory )
		if not state then
			print("ERROR: "..tostring(result).." (buttinImg: "..tostring(buttinImg)..")")
			return
		end
		btn.img_dual = result;
	end;

	if on then
		btn.img_active = btn.img_on;
	else
		btn.img_active = btn.img_off;
	end;

	btn.ov = Overlay:new(name, btn.img_active, btn.posX,btn.posY, AutoDrive.Hud.buttonWidth, AutoDrive.Hud.buttonHeight);

	--
	AutoDrive.Hud.Buttons[AutoDrive.Hud.buttonCounter] = btn
end;

function AutoDrive:InputHandling(vehicle, input)

	vehicle.currentInput = input;

	if g_server ~= nil then
		--print("received event in InputHandling. event: " .. input);
	else
		--print("Not the server - sending event to server " .. input);
		AutoDriveInputEvent:sendEvent(vehicle);
	end;

	if input ~= nil then
		if input == "input_silomode" then
			if vehicle.bTargetMode == true and vehicle.bUnloadAtTrigger == false then
				if g_server ~= nil and g_dedicatedServerInfo == nil then
					vehicle.bReverseTrack = true;
					vehicle.bDrivingForward = true;
					vehicle.bTargetMode = false;
					vehicle.bRoundTrip = false;
					vehicle.savedSpeed = vehicle.nSpeed;
					vehicle.nSpeed = 15;
					vehicle.bUnloadAtTrigger = false;
				else
					vehicle.bReverseTrack = false;
					vehicle.bDrivingForward = true;
					vehicle.bTargetMode = true;
					vehicle.bRoundTrip = false;
					vehicle.bUnloadAtTrigger = true;

					if vehicle.savedSpeed ~= nil then
						vehicle.nSpeed = vehicle.savedSpeed;
						vehicle.savedSpeed = nil;
					end;
				end;
			else
				if vehicle.bReverseTrack == true then
					vehicle.bReverseTrack = false;
					vehicle.bDrivingForward = true;
					vehicle.bTargetMode = true;
					vehicle.bRoundTrip = false;
					vehicle.bUnloadAtTrigger = true;

					if vehicle.savedSpeed ~= nil then
						vehicle.nSpeed = vehicle.savedSpeed;
						vehicle.savedSpeed = nil;
					end;
				else
					if vehicle.bTargetMode == true and vehicle.bUnloadAtTrigger == true then
						vehicle.bReverseTrack = false;
						vehicle.bDrivingForward = true;
						vehicle.bTargetMode = true;
						vehicle.bRoundTrip = false;
						vehicle.bUnloadAtTrigger = false;
						if vehicle.savedSpeed ~= nil then
							vehicle.nSpeed = vehicle.savedSpeed;
							vehicle.savedSpeed = nil;
						end;
					end;
				end;
			end;
		end;

		if input == "input_roundtrip" then
			vehicle.bRoundTrip = not vehicle.bRoundTrip
			if vehicle.bRoundTrip then
				vehicle.nSpeed = 40;
				vehicle.bTargetMode = false;
				vehicle.bReverseTrack = false;
				vehicle.printMessage = g_i18n:getText("AD_Roundtrip_on");
			else
				vehicle.printMessage = g_i18n:getText("AD_Roundtrip_off");
			end;
			vehicle.nPrintTime = 3000;
		end;

		if input == "input_start_stop" then
			--print("executing input_start_stop");
			if vehicle.bActive == false then
				vehicle.bActive = true;
				vehicle.bcreateMode = false;
				--vehicle.onStartAiVehicle();
				--vehicle.isHired = true;
				vehicle.forceIsActive = true;
				vehicle.stopMotorOnLeave = false;
				vehicle.disableCharacterOnLeave = true;
				--vehicle.isControlled = true;

				local trailer = nil;
				if vehicle.attachedImplements ~= nil then
					for _, implement in pairs(vehicle.attachedImplements) do
						if implement.object ~= nil then
							if implement.object.typeDesc == g_i18n:getText("typeDesc_tipper") then -- "tipper" then

								trailer = implement.object;
							end;
						end;
					end;
				end;
				if vehicle.bUnloadAtTrigger == true and trailer ~= nil then
					local fillTable = trailer:getCurrentFillTypes();
					if fillTable[1] ~= nil then
						vehicle.unloadType = fillTable[1];
					end;
				end;

				--vehicle.printMessage = g_i18n:getText("AD_Activated");
				vehicle.nPrintTime = 3000;
			else
				vehicle.nCurrentWayPoint = 0;
				vehicle.bDrivingForward = true;
				vehicle.bActive = false;
				vehicle.bStopAD = true;
				vehicle.bUnloading = false;
				vehicle.bLoading = false;
				--AutoDrive:deactivate(vehicle,false);
			end;

			for _,button in pairs(AutoDrive.Hud.Buttons) do
				if button.name == "input_start_stop" then
					if vehicle.bActive == true then
						button.img_active = button.img_on;
					else
						button.img_active = button.img_off;
					end;
					--button.ov = Overlay:new(nil, button.img_active,button.posX ,button.posY , AutoDrive.Hud.buttonWidth, AutoDrive.Hud.buttonHeight);
					button.ov:setImage(button.img_active)
				end;
			end;

		end;

		if input == "input_nextTarget"
		or input == "input_previousTarget"
		then
			local ad = g_currentMission.AutoDrive
			if ad.mapMarker[1] ~= nil and ad.mapWayPoints[1] ~= nil then
				if input == "input_nextTarget" then
					vehicle.nMapMarkerSelected = (vehicle.nMapMarkerSelected % ad.mapMarkerCounter) + 1
				else
					vehicle.nMapMarkerSelected = ((vehicle.nMapMarkerSelected + ad.mapMarkerCounter-1) % ad.mapMarkerCounter) + 1
				end

				vehicle.ntargetSelected = ad.mapMarker[vehicle.nMapMarkerSelected].id;
				vehicle.sTargetSelected = ad.mapMarker[vehicle.nMapMarkerSelected].name;
				--vehicle.sTargetSelected = AutoDrive:translate(vehicle.sTargetSelected);

				if vehicle.nSpeed == 15 then
					vehicle.nSpeed = 40;
				end;
				vehicle.bTargetMode = true;
				vehicle.bRoundTrip = false;
				vehicle.bReverseTrack = false;
				vehicle.bDrivingForward = true;
			end;
		end;

		if input == "input_debug" then
			vehicle.bCreateMapPoints = not vehicle.bCreateMapPoints

			for _,button in pairs(AutoDrive.Hud.Buttons) do
				if button.name == "input_debug" then
					if vehicle.bCreateMapPoints == true then
						button.img_active = button.img_on;
					else
						button.img_active = button.img_off;
					end;
					--button.ov = Overlay:new(nil, button.img_active,button.posX ,button.posY , AutoDrive.Hud.buttonWidth, AutoDrive.Hud.buttonHeight);
					button.ov:setImage(button.img_active)
				end;
			end;

		end;

		if input == "input_record" and g_server ~= nil and g_dedicatedServerInfo == nil then
			if vehicle.bcreateMode == false then
				vehicle.bcreateMode = true;
				vehicle.bcreateModeDual = false;
				vehicle.nCurrentWayPoint = 0;
				vehicle.bActive = false;
				vehicle.ad.wayPoints = {};
				vehicle.bTargetMode = false;
				--vehicle.printMessage = g_i18n:getText("AD_Recording_on");
				--vehicle.nPrintTime = 3000;
			else
				if vehicle.bcreateModeDual == false then
					vehicle.bcreateModeDual = true;
				else
					vehicle.bcreateMode = false;
					vehicle.bcreateModeDual = false;
					input = "input_nextTarget";
				end;
					--vehicle.printMessage = g_i18n:getText("AD_Recording_off");
				--vehicle.nPrintTime = 3000;
			end;

			for _,button in pairs(AutoDrive.Hud.Buttons) do
				if button.name == "input_record" then
					if vehicle.bcreateMode == true then
						button.img_active = button.img_on;
					else
						button.img_active = button.img_off;
					end;
					--button.ov = Overlay:new(nil, button.img_active,button.posX ,button.posY , AutoDrive.Hud.buttonWidth, AutoDrive.Hud.buttonHeight);
					button.ov:setImage(button.img_active)
				end;
			end;

		end;

		if input == "input_showClosest" and g_server ~= nil and g_dedicatedServerInfo == nil then
			vehicle.bShowDebugMapMarker = not vehicle.bShowDebugMapMarker

			for _,button in pairs(AutoDrive.Hud.Buttons) do
				if button.name == "input_showClosest" then
					if vehicle.bShowDebugMapMarker == true then
						button.img_active = button.img_on;
					else
						button.img_active = button.img_off;
					end;
					--button.ov = Overlay:new(nil, button.img_active,button.posX ,button.posY , AutoDrive.Hud.buttonWidth, AutoDrive.Hud.buttonHeight);
					button.ov:setImage(button.img_active)
				end;
			end;

		end;

		if input == "input_showNeighbor" and g_server ~= nil and g_dedicatedServerInfo == nil then
			vehicle.bShowSelectedDebugPoint = not vehicle.bShowSelectedDebugPoint
			if vehicle.bShowSelectedDebugPoint == true then
				-- Locate the adjacent waypoints, within a certain radius of vehicle
				local foundWithDistance = {}
				local x1,y1,z1 = getWorldTranslation(vehicle.components[1].node);
				for i,point in pairs(g_currentMission.AutoDrive.mapWayPoints) do
					local distance = getDistance(point.x,point.z,x1,z1);
					if distance < 15 then
						table.insert(foundWithDistance, {wpId=i, distance=distance})
					end;
				end;
				-- Sort so very-nearest waypoint becomes first in list
				table.sort(foundWithDistance, function(a,b) return a.distance < b.distance; end);
				-- Fill the 'neighbouring waypoints' table
				vehicle.DebugPointsIterated = {}
				for _,elem in pairs(foundWithDistance) do
					table.insert(vehicle.DebugPointsIterated, g_currentMission.AutoDrive.mapWayPoints[elem.wpId])
				end
				vehicle.nSelectedDebugPoint = 1
			end

			for _,button in pairs(AutoDrive.Hud.Buttons) do
				if button.name == "input_showNeighbor" then
					if vehicle.bShowSelectedDebugPoint == true then
						button.img_active = button.img_on;
					else
						button.img_active = button.img_off;
					end;
					--button.ov = Overlay:new(nil, button.img_active,button.posX ,button.posY , AutoDrive.Hud.buttonWidth, AutoDrive.Hud.buttonHeight);
					button.ov:setImage(button.img_active)
				end;
			end;

		end;

		if input == "input_toggleConnection" and g_server ~= nil and g_dedicatedServerInfo == nil then
			vehicle.bChangeSelectedDebugPoint = not vehicle.bChangeSelectedDebugPoint
		end

		if input == "input_nextNeighbor" then
			vehicle.bChangeSelectedDebugPointSelection = not vehicle.bChangeSelectedDebugPointSelection
		end;

		if input == "input_createMapMarker" and g_server ~= nil and g_dedicatedServerInfo == nil then
			if vehicle.bShowDebugMapMarker == true then
				vehicle.bCreateMapMarker = not vehicle.bCreateMapMarker

				vehicle.sEnteredMapMarkerString = "";
				vehicle.bEnteringMapMarker = vehicle.bCreateMapMarker
				g_currentMission.isPlayerFrozen = vehicle.bCreateMapMarker
				vehicle.isBroken = vehicle.bCreateMapMarker
			end;
		end;

		if input == "input_increaseSpeed" then
			vehicle.nSpeed = Utils.clamp(vehicle.nSpeed + 1, 1, 100)
		end;

		if input == "input_decreaseSpeed" then
			vehicle.nSpeed = Utils.clamp(vehicle.nSpeed - 1, 2, 100)
		end;

		if input == "input_toggleHud" then
			AutoDrive.Hud.showHud = not AutoDrive.Hud.showHud
			if AutoDrive.Hud.showHud then
				g_currentMission.AutoDrive.showMouse = not g_currentMission.AutoDrive.showMouse
				InputBinding.setShowMouseCursor(g_currentMission.AutoDrive.showMouse)
			end
		end

		if input == "input_toggleMouse" then
			if AutoDrive.Hud.showHud then
				g_currentMission.AutoDrive.showMouse = not g_currentMission.AutoDrive.showMouse
				InputBinding.setShowMouseCursor(g_currentMission.AutoDrive.showMouse)
			end
		end

		if input == "input_removeWaypoint" and g_server ~= nil and g_dedicatedServerInfo == nil then

			if vehicle.bShowDebugMapMarker == true and g_currentMission.AutoDrive.mapWayPoints[1] ~= nil then
				local closest = AutoDrive:findClosestWayPoint(vehicle)
				print("removing waypoint with id: " .. closest);
				AutoDrive:removeMapWayPoint( g_currentMission.AutoDrive.mapWayPoints[closest] );
			end;

		end;

		if input == "input_removeDestination" and g_server ~= nil and g_dedicatedServerInfo == nil then

			if vehicle.bShowDebugMapMarker == true and g_currentMission.AutoDrive.mapWayPoints[1] ~= nil then
				local closest = AutoDrive:findClosestWayPoint(vehicle)
				print("removing destination with node id: " .. closest);
				AutoDrive:removeMapMarker( g_currentMission.AutoDrive.mapWayPoints[closest] );
			end;

		end;

		if input == "input_recalculate" and g_server ~= nil and g_dedicatedServerInfo == nil then
			print(("%s - Recalculation starting"):format(getDate("%H:%M:%S")))
			AutoDrive:ContiniousRecalculation();
		end;

		if input == "input_exportRoutes" then
			AutoDrive:ExportRoutes();
		end;

		if input == "input_importRoutes" then
			AutoDrive:ImportRoutes();
		end;

		if input == "input_nextTarget_Unload"
		or input == "input_previousTarget_Unload"
		then
			if  g_currentMission.AutoDrive.mapMarker[1] ~= nil and g_currentMission.AutoDrive.mapWayPoints[1] ~= nil then
				if input == "input_nextTarget_Unload" then
					vehicle.nMapMarkerSelected_Unload = (vehicle.nMapMarkerSelected_Unload % g_currentMission.AutoDrive.mapMarkerCounter) + 1
				else
					vehicle.nMapMarkerSelected_Unload = ((vehicle.nMapMarkerSelected_Unload+g_currentMission.AutoDrive.mapMarkerCounter-1) % g_currentMission.AutoDrive.mapMarkerCounter) + 1
				end

				vehicle.ntargetSelected_Unload = g_currentMission.AutoDrive.mapMarker[vehicle.nMapMarkerSelected_Unload].id;
				vehicle.sTargetSelected_Unload = g_currentMission.AutoDrive.mapMarker[vehicle.nMapMarkerSelected_Unload].name;
				--vehicle.sTargetSelected_Unload = AutoDrive:translate(vehicle.sTargetSelected_Unload);
			end;

		end;

		if input == "input_continue" then
			vehicle.bPaused = not vehicle.bPaused
		end

		if input == "input_frontLoaderCam" then
			vehicle.ad.cam = not vehicle.ad.cam
		end
	end
	vehicle.currentInput = "";

end;

function AutoDrive:ContiniousRecalculation()

	local adRecalc = g_currentMission.AutoDrive.Recalculation

	if adRecalc.continue == true then
		if adRecalc.initializedWaypoints == false then
			for i2,point in pairs(g_currentMission.AutoDrive.mapWayPoints) do
				point.marker = {};
			end;
			adRecalc.initializedWaypoints = true;
			return 10;
		end;

		local markerFinished = false;
		for i, marker in pairs(g_currentMission.AutoDrive.mapMarker) do
			if markerFinished == false then
				if i == adRecalc.nextMarker then
					print(("%s - Recalculating: %s"):format(getDate("%H:%M:%S"), marker.name))

					local tempAD = AutoDrive:dijkstra(g_currentMission.AutoDrive.mapWayPoints, marker.id,"incoming");

					for i2,point in pairs(g_currentMission.AutoDrive.mapWayPoints) do
						point.marker[marker.name] = tempAD.pre[point.id];
					end;

					markerFinished = true;
				end;
			else
				adRecalc.nextMarker = i;
				adRecalc.handledMarkers = adRecalc.handledMarkers + 1;
				return 10 + math.ceil((adRecalc.handledMarkers/g_currentMission.AutoDrive.mapMarkerCounter) * 90)
			end;

		end;
		print(("%s - Recalculation finished"):format(getDate("%H:%M:%S")))

		if g_currentMission.AutoDrive.adXml ~= nil then
			setXMLBool(g_currentMission.AutoDrive.adXml, "AutoDrive.Recalculation", false);
			AutoDrive:MarkChanged();
			g_currentMission.AutoDrive.handledRecalculation = true;
		end;

		adRecalc.continue = false;
		return 100;
	else
		adRecalc = {};
		adRecalc.continue = true;
		adRecalc.initializedWaypoints = false;
		adRecalc.nextMarker = ""
		for i, marker in pairs(g_currentMission.AutoDrive.mapMarker) do
			if adRecalc.nextMarker == "" then
				adRecalc.nextMarker = i;
			end;
		end;
		adRecalc.handledMarkers = 0;
		adRecalc.nextCalculationSkipFrames = 6;

		g_currentMission.AutoDrive.Recalculation = adRecalc

		return 5;
	end;
end

function AutoDrive:dijkstra(graph, start, setToUse)

	-- Init and copy graph. Its elements are not modified, so no need to deep-copy it.
	local workGraph = {}
	local newPaths = { distance = {}, pre = {} }
	for id, wp in pairs(graph) do
        newPaths.distance[id] = math.huge
		newPaths.pre[id] = -1
		workGraph[id] = wp
	end

	newPaths.distance[start] = 0

	-- Walk the graph
	while next(workGraph, nil) ~= nil do
		local shortest_dist = math.huge
		local shortest_id = -1

		for _, wp in pairs(workGraph) do
			if shortest_dist > newPaths.distance[wp.id] then
				shortest_dist = newPaths.distance[wp.id]
				shortest_id = wp.id
			end
		end

		if shortest_id == -1 then
			workGraph = {}
		else
			local x1,z1 = workGraph[shortest_id].x, workGraph[shortest_id].z
			for _, id in pairs(workGraph[shortest_id][setToUse]) do
				local wp = workGraph[id]
				if nil ~= wp then
					local alternative = shortest_dist + getDistance(x1,z1, wp.x,wp.z)
					if alternative < newPaths.distance[id] then
						newPaths.distance[id] = alternative
						newPaths.pre[id] = shortest_id
					end
				end
			end

			workGraph[shortest_id] = nil
		end
	end

	return newPaths

end

function AutoDrive:graphcopy(Graph)
	local Q = {};
	--print("Graphcopy");
	for i in pairs(Graph) do
		--print ("i = " .. i );
		local id = Graph[i]["id"];
		--print ("id = " .. id );
		local out = {};
		local incoming = {};
		local out_cost = {};
		local marker = {};

		--print ("out:");
		for i2 in pairs(Graph[i]["out"]) do
			out[i2] = Graph[i]["out"][i2];
			--print(""..i2 .. " : " .. out[i2]);
		end;
		--print("incoming");
		for i3 in pairs(Graph[i]["incoming"]) do
			incoming[i3] = Graph[i]["incoming"][i3];
		end;
		for i4 in pairs(Graph[i]["out_cost"]) do
			out_cost[i4] = Graph[i]["out_cost"][i4];
		end;


		for i5 in pairs(Graph[i]["marker"]) do
			marker[i5] = Graph[i]["marker"][i5];
		end;


		Q[i] = createNode(id,out,incoming,out_cost, marker);

		Q[i].x = Graph[i].x;
		Q[i].y = Graph[i].y;
		Q[i].z = Graph[i].z;

	end;

	return Q;
end;

function createNode(id,out,incoming,out_cost, marker)
	local p = {};
	p["id"] = id;
	p["out"] = out;
	p["incoming"] = incoming;
	p["out_cost"] = out_cost;
	p["marker"] = marker;
	--p["coords"] = coords;

	return p;
end

function AutoDrive:FastShortestPath(Graph,start,markerName, markerID)
	local wp = {};
	local count = 1;
	local id = start;

	while id ~= -1 and id ~= nil do
		wp[count] = Graph[id];
		count = count+1;
		if id == markerID then
			id = nil;
		else
			id = g_currentMission.AutoDrive.mapWayPoints[id].marker[markerName];
		end;
	end;

	local wp_copy = AutoDrive:graphcopy(wp);

	return wp_copy;
end;

function AutoDrive:shortestPath(Graph,distance,pre,start,endNode)
	local wp = {};
	local count = 1;
	local id = Graph[endNode]["id"];

	while self.ad.pre[id] ~= -1 do
		for i in pairs(Graph) do
			if Graph[i]["id"] == id then
				wp[count] = Graph[i];  --todo: maybe create copy
			end;
		end;
		count = count+1;
		id = self.ad.pre[id];
	end;

	local wp_reversed = {};
	for i in pairs(wp) do
		wp_reversed[count-i] = wp[i];
	end;

	local wp_copy = AutoDrive:graphcopy(wp_reversed);

	return wp_copy;
end;

function init(self)
	self.bDisplay = 1;
	if self.ad == nil then
		self.ad = {};
	end;

	self.bLongFormat = 0;
	self.nSubStringLength = 40;
	self.bDarkColor = 0;
	self.nDebugOutput = 0;
	self.bActive = false;
	self.bRoundTrip = false;
	self.bReverseTrack = false;
	self.bDrivingForward = true;
	self.nTargetX = 0;
	self.nTargetZ = 0;
	self.bInitialized = false;
	self.ad.wayPoints = {};
	self.bcreateMode = false;
	self.bcreateModeDual = false;
	self.nCurrentWayPoint = 0;
	self.nlastLogged = 0;
	self.nloggingInterval = 500;
	self.logMessage = "";
	self.nPrintTime = 3000;
	self.ntargetSelected = -1;
	self.nMapMarkerSelected = -1;
	self.sTargetSelected = "";
	if g_currentMission.AutoDrive ~= nil then
		if g_currentMission.AutoDrive.mapMarker[1] ~= nil then
			self.ntargetSelected = g_currentMission.AutoDrive.mapMarker[1].id;
			self.nMapMarkerSelected = 1;
			self.sTargetSelected = g_currentMission.AutoDrive.mapMarker[1].name;
			--self.sTargetSelected = AutoDrive:translate(self.sTargetSelected);
		end;
	end;
	self.bTargetMode = true;
	self.nSpeed = 40;
	self.bCreateMapPoints = false;
	self.bShowDebugMapMarker = true;
	self.nSelectedDebugPoint = -1;
	self.bShowSelectedDebugPoint = false;
	self.bChangeSelectedDebugPoint = false;
	self.DebugPointsIterated = {};
	self.bDeadLock = false;
	self.nTimeToDeadLock = 15000;
	self.bDeadLockRepairCounter = 4;

	self.bStopAD = false;
	self.bCreateMapMarker = false;
	self.bEnteringMapMarker = false;
	self.sEnteredMapMarkerString = "";

	if Steerable.load ~= nil then
		local aNameSearch = {"vehicle.name." .. g_languageShort, "vehicle.name.en", "vehicle.name", "vehicle.storeData.name", "vehicle#type"};
		local orgSteerableLoad = Steerable.load
		Steerable.load = function(self,xmlFile)
			orgSteerableLoad(self,xmlFile)
			for nIndex,sXMLPath in pairs(aNameSearch) do
				self.name = getXMLString(self.xmlFile, sXMLPath);
				if self.name ~= nil then
					break;
				end;
			end;
			if self.name == nil then
				self.name = g_i18n:getText("UNKNOWN")
			end;
		end

	end;
	self.moduleInitialized = true;
	self.currentInput = "";
	self.previousSpeed = self.nSpeed;
	self.speed_override = nil;

	self.requestWayPointTimer = 10000;

	self.bUnloadAtTrigger = false;
	self.bUnloading = false;
	self.bPaused = false;
	self.bUnloadSwitch = false;
	self.unloadType = -1;
	self.bLoading = false;
	self.trailertipping = -1;

	g_currentMission.AutoDrive.Recalculation = {};

	self.ntargetSelected_Unload = -1;
	self.nMapMarkerSelected_Unload = -1;
	self.sTargetSelected_Unload = "";
	if g_currentMission.AutoDrive ~= nil then
		if g_currentMission.AutoDrive.mapMarker[1] ~= nil then
			self.ntargetSelected_Unload = g_currentMission.AutoDrive.mapMarker[1].id;
			self.nMapMarkerSelected_Unload = 1;
			self.sTargetSelected_Unload = g_currentMission.AutoDrive.mapMarker[1].name;
			--self.sTargetSelected_Unload = AutoDrive:translate(self.sTargetSelected_Unload);
		end;
	end;

	self.nPauseTimer = 5000;
	self.ad.nToolTipWait = 300;
	self.ad.nToolTipTimer = 6000;
	self.ad.sToolTip = "";

	--init traffic detection:
	--[[
	self.coliTrigger = AutoDrive.adOnTrafficCollisionTrigger;
	self.ad.trafficCollisionTriggers = {};
	self.ad.collisions = {};
	if self.aiTrafficCollisionTrigger ~= nil then

		addTrigger(self.aiTrafficCollisionTrigger, 'coliTrigger', self);

	end;
	--]]

	if self.frontloaderAttacher ~= nil or self.typeDesc == "telehandler" then
		if self.frontLoaderCam == nil then
			self.frontLoaderCam = createCamera("frontLoaderCam",  60, 0.02, 200);
			local node = self.components[1].node -- self.frontloaderAttacher.attacherJoint.rootNode;
			local nodeTool = nil;
			for _, impl in pairs(self.attachedImplements) do
				if impl.object ~= nil then
					if impl.object.typeName == "attachableFrontloader" then
						--print("Selected frontloader attachment as root node");
						nodeTool = impl.object.attacherJoints[1].jointTransform;
					end;
				end;
			end;
			if self.typeDesc == "telehandler" then
				nodeTool = self.attacherJoints[1].jointTransform;
			end;
			if nodeTool == nil then
				nodeTool = node;
			end;

			link(node, self.frontLoaderCam);
			rotate(self.frontLoaderCam,0,math.pi*0.84,0);

			local xW,yW,zW = getWorldTranslation(node);
			local xTool,yTool,zTool = getWorldTranslation(nodeTool);
			local xCam,yCam,zCam = getWorldTranslation(self.frontLoaderCam);

			self.frontLoaderCamOffsetX = self.sizeWidth/2; -- + 0.8;
			self.frontLoaderCamOffsetZ = self.sizeLength/2 + 1.0; -- -1.0
			--DebugUtil.drawDebugNode(node, "node");
			local x,y,z = worldToLocal(node,xW+self.frontLoaderCamOffsetX,yTool+0.5,zW+self.frontLoaderCamOffsetZ) --+self.ad.frontLoaderCamShift
			setTranslation(self.frontLoaderCam,x,y,z);
			--rotate(self.frontLoaderCam,self.ad.frontLoaderCamShiftAngle ,-self.ad.frontLoaderCamShiftSide,0);
			--setCamera(self.frontLoaderCam);
			self.ad.cam = false;
		end;
	end;

	self.bChoosingDestination = false;
	self.sChosenDestination = "";
	self.sEnteredChosenDestination = "";

	self.trafficVehicle = nil;
end;

--function AutoDrive:translate(text)
--
--	if text == "Hof" then
--		return g_i18n:getText("AD_Hof");
--	end;
--	if text == "Kuhstall" then
--		return g_i18n:getText("AD_Kuhstall");
--	end;
--	if text == "Schweinestall" then
--		return g_i18n:getText("AD_Schweinestall");
--	end;
--	if text == "Schafsweide" then
--		return g_i18n:getText("AD_Schafsweide");
--	end;
--	if text == "Tankstelle" then
--		return g_i18n:getText("AD_Tankstelle");
--	end;
--	if text == "Viehhandel" then
--		return g_i18n:getText("AD_Viehhandel");
--	end;
--
--	return text;
--
--end;

function AutoDrive:newMouseEvent(superFunc, posX, posY, isDown, isUp, button)
	if g_currentMission.AutoDrive.showMouse then
		local x = InputBinding.mouseMovementX;
		local y = InputBinding.mouseMovementY;
		InputBinding.mouseMovementX = 0;
		InputBinding.mouseMovementY = 0;
		superFunc(self, posX, posY, isDown, isUp, button)
		InputBinding.mouseMovementX = x;
		InputBinding.mouseMovementY = y;
	else
		superFunc(self, posX, posY, isDown, isUp, button)
	end;
end;

function AutoDrive:mouseEvent(posX, posY, isDown, isUp, button)
	if self == g_currentMission.controlledVehicle
	and g_currentMission.AutoDrive.showMouse
	and AutoDrive.Hud.showHud == true
	then
		local buttonHovered = false;
		for _, button in pairs(AutoDrive.Hud.Buttons) do
			if  button.isVisible
			and posX > (button.posX)
			and posX < (button.posX + button.width)
			and posY > (button.posY)
			and posY < (button.posY + button.height)
			then
				if self.ad.sToolTip ~= button.toolTip then
					self.ad.sToolTip = button.toolTip;
					self.ad.nToolTipTimer = 6000;
					self.ad.nToolTipWait = 300;
				end;
				buttonHovered = true;

				if button == 1 and isDown then
					--print("Clicked button " .. button.name);
					AutoDrive:InputHandling(self, button.name);
				end
				break
			end;
		end;
		if not buttonHovered then
			self.ad.sToolTip = "";
		end;

		if button == 1 and isDown then
--			for _,button in pairs(AutoDrive.Hud.Buttons) do
--
--				if posX > button.posX and posX < (button.posX + button.width) and posY > button.posY and posY < (button.posY + button.height) and	button.isVisible then
--					--print("Clicked button " .. button.name);
--					AutoDrive:InputHandling(self, button.name);
--				end;
--
--			end;

			local button = AutoDrive.Hud.Background.close_small
			if  posX > (button.posX)
			and posX < (button.posX + button.width)
			and posY > (button.posY)
			and posY < (button.posY + button.height)
			then
				AutoDrive:InputHandling(self, "input_toggleHud")
--				if AutoDrive.Hud.showHud == false then
--					AutoDrive.Hud.showHud = true;
--				else
--					AutoDrive.Hud.showHud = false;
--					if g_currentMission.AutoDrive.showMouse == false then
--						--g_mouseControlsHelp.active = false
--						g_currentMission.AutoDrive.showMouse = true;
--						InputBinding.setShowMouseCursor(true);
--					else
--						--g_mouseControlsHelp.active = true
--						InputBinding.setShowMouseCursor(false);
--						g_currentMission.AutoDrive.showMouse = false;
--					end;
--				end;
			end;

			local adPosX = AutoDrive.Hud.posX + AutoDrive.Hud.Background.destination.width; -- + AutoDrive.Hud.borderX; --0.03 + g_currentMission.helpBoxWidth
			local adPosY = AutoDrive.Hud.posY + 0.04 + (AutoDrive.Hud.borderY + AutoDrive.Hud.buttonHeight) * AutoDrive.Hud.rowCurrent; --+ 0.003; --0.975;
			local height = 0.015;
			local width = 0.05;
			if posX > (adPosX) and posX < (adPosX + width) and posY > (adPosY) and posY < (adPosY + height) then
				if self.bChoosingDestination == false then
					self.bChoosingDestination = true
					self.isBroken = false;
					g_currentMission.isPlayerFrozen = true;
					self.isBroken = true;
				else
					self.bChoosingDestination = false;
					g_currentMission.isPlayerFrozen = false;
					self.isBroken = false;
				end;
			end;
		end;
	end;
end;

function AutoDrive:onLeave()
	g_currentMission.AutoDrive.showMouse = false;
	InputBinding.setShowMouseCursor(g_currentMission.AutoDrive.showMouse);
end;

function AutoDrive:keyEvent(unicode, sym, modifier, isDown)
	if self == g_currentMission.controlledVehicle
	and isDown
	then
		--print("Unicode: " .. unicode .. " sym: " .. sym);
		if self.bEnteringMapMarker then
			if sym == 13 then
				-- Enter
				self.bEnteringMapMarker = false;
				self.isBroken = false;
			elseif sym == 8 then
				-- Backspace
				self.sEnteredMapMarkerString = string.sub(self.sEnteredMapMarkerString,1,string.len(self.sEnteredMapMarkerString)-1)
			elseif unicode ~= 0 then
				-- 'character'
				self.sEnteredMapMarkerString = self.sEnteredMapMarkerString .. string.char(unicode);
			end;
		elseif self.bChoosingDestination then
			if sym == 13 then
				-- Enter
				self.bChoosingDestination = false;
				self.sChosenDestination = "";
				self.sEnteredChosenDestination = "";
				self.isBroken = false;
				g_currentMission.isPlayerFrozen = false;
			elseif sym == 8 then
				-- Backspace
				self.sEnteredChosenDestination = string.sub(self.sEnteredChosenDestination,1,string.len(self.sEnteredChosenDestination)-1)
			elseif sym == 9 then
				-- Tab
				local foundMatch = false;
				local behindCurrent = false;
				local markerID = -1;
				local markerIndex = -1;
				if self.sChosenDestination == "" then
					behindCurrent = true;
				end;
				for i, marker in pairs(g_currentMission.AutoDrive.mapMarker) do
					local tempName = self.sChosenDestination;
					if string.find(marker.name, self.sEnteredChosenDestination) == 1 and behindCurrent and not foundMatch then
						self.sChosenDestination = marker.name;
						markerID = marker.id;
						markerIndex = i;
						foundMatch = true;
					end;
					if tempName == marker.name then
						behindCurrent = true;
					end;
				end;
				if behindCurrent == true and foundMatch == false then
					for i, marker in pairs(g_currentMission.AutoDrive.mapMarker) do
						if string.find(marker.name, self.sEnteredChosenDestination) == 1 and then
							self.sChosenDestination = marker.name;
							markerID = marker.id;
							markerIndex = i;
							break
						end;
					end;
				end;
				if self.sChosenDestination ~= "" then
					self.nMapMarkerSelected = markerIndex;
					self.ntargetSelected = g_currentMission.AutoDrive.mapMarker[self.nMapMarkerSelected].id;
					self.sTargetSelected = g_currentMission.AutoDrive.mapMarker[self.nMapMarkerSelected].name;
					--self.sTargetSelected = AutoDrive:translate(self.sTargetSelected);
				end;
			elseif unicode ~= 0 then
				-- 'character'
				self.sEnteredChosenDestination = self.sEnteredChosenDestination .. string.char(unicode);
			end;
		end;
	end;
end;

function AutoDrive:deactivate(self,stopVehicle)
	--[[
	if stopVehicle == true then
		local x,y,z = getWorldTranslation( self.components[1].node );
		local xl,yl,zl = worldToLocal(self.components[1].node, self.nTargetX,y,self.nTargetZ);
		AIVehicleUtil.driveToPoint(self, dt, 0, true, self.bDrivingForward, xl, zl, 0, false );
		self:setCruiseControlState(Drivable.CRUISECONTROL_STATE_OFF);
	end;
	--]]
	self.bActive = false;
	self.forceIsActive = false;
	self.stopMotorOnLeave = true;
	self.disableCharacterOnLeave = true;

	self.bInitialized = false;
	self.nCurrentWayPoint = 0;
	self.bDrivingForward = true;
	self.previousSpeed = 10;
	if self.steeringEnabled == false then
		self.steeringEnabled = true;
	end
	self:setCruiseControlState(Drivable.CRUISECONTROL_STATE_OFF);

	--self.isControlled = false;

	--self.printMessage = g_i18n:getText("AD_Deactivated");
	--self.nPrintTime = 3000;
end;

function AutoDrive:update(dt)

	if self.moduleInitialized == nil then
		init(self);
	end;

	if self == g_currentMission.controlledVehicle then
		if InputBinding.hasEvent(InputBinding.ADSilomode)             then AutoDrive:InputHandling(self, "input_silomode") end
		if InputBinding.hasEvent(InputBinding.ADRoundtrip)            then AutoDrive:InputHandling(self, "input_roundtrip") end
		if InputBinding.hasEvent(InputBinding.ADRecord)               then AutoDrive:InputHandling(self, "input_record") end
		if InputBinding.hasEvent(InputBinding.ADEnDisable)            then AutoDrive:InputHandling(self, "input_start_stop") end
		if InputBinding.hasEvent(InputBinding.ADSelectTarget)         then AutoDrive:InputHandling(self, "input_nextTarget") end
		if InputBinding.hasEvent(InputBinding.ADSelectPreviousTarget) then AutoDrive:InputHandling(self, "input_previousTarget") end
		if g_currentMission.AutoDrive.showMouse then
			if InputBinding.hasEvent(InputBinding.ADSelectTargetMouseWheel)         then AutoDrive:InputHandling(self, "input_nextTarget") end
			if InputBinding.hasEvent(InputBinding.ADSelectPreviousTargetMouseWheel) then AutoDrive:InputHandling(self, "input_previousTarget") end
		end
		if InputBinding.hasEvent(InputBinding.ADActivateDebug)         then AutoDrive:InputHandling(self, "input_debug") end
		if InputBinding.hasEvent(InputBinding.ADDebugShowClosest)      then AutoDrive:InputHandling(self, "input_showNeighbor") end
		if InputBinding.hasEvent(InputBinding.ADDebugSelectNeighbor)   then AutoDrive:InputHandling(self, "input_showNeighbor") end
		if InputBinding.hasEvent(InputBinding.ADDebugCreateConnection) then AutoDrive:InputHandling(self, "input_toggleConnection") end
		if InputBinding.hasEvent(InputBinding.ADDebugChangeNeighbor)   then AutoDrive:InputHandling(self, "input_nextNeighbor") end
		if InputBinding.hasEvent(InputBinding.ADDebugCreateMapMarker)  then AutoDrive:InputHandling(self, "input_createMapMarker") end

		if InputBinding.hasEvent(InputBinding.AD_Speed_up)   then AutoDrive:InputHandling(self, "input_increaseSpeed") end
		if InputBinding.hasEvent(InputBinding.AD_Speed_down) then AutoDrive:InputHandling(self, "input_decreaseSpeed") end

		if InputBinding.hasEvent(InputBinding.ADToggleHud)      then AutoDrive:InputHandling(self, "input_toggleHud") end
		if InputBinding.hasEvent(InputBinding.ADToggleMouse)    then AutoDrive:InputHandling(self, "input_toggleMouse") end
		if InputBinding.hasEvent(InputBinding.ADFrontLoaderCam) then AutoDrive:InputHandling(self, "input_frontLoaderCam") end

		if InputBinding.hasEvent(InputBinding.AD_export_routes) then AutoDrive:InputHandling(self, "input_exportRoutes") end
		if InputBinding.hasEvent(InputBinding.AD_import_routes) then AutoDrive:InputHandling(self, "input_importRoutes") end

		if InputBinding.hasEvent(InputBinding.ADDebugDeleteWayPoint)    then AutoDrive:InputHandling(self, "input_removeWaypoint") end
		if InputBinding.hasEvent(InputBinding.ADDebugDeleteDestination) then AutoDrive:InputHandling(self, "input_removeDestination") end
	end;

	local adRecalc = g_currentMission.AutoDrive.Recalculation
	if adRecalc ~= nil and adRecalc.continue == true then
		adRecalc.nextCalculationSkipFrames = adRecalc.nextCalculationSkipFrames - 1;
		if adRecalc.nextCalculationSkipFrames <= 0 then
			adRecalc.nextCalculationSkipFrames = 6;
			local recalculationPercentage = AutoDrive:ContiniousRecalculation();
			AutoDrive.printMessage = g_i18n:getText("AD_Recalculationg_routes_status") .. " " .. recalculationPercentage .. "%";
			AutoDrive.nPrintTime = 10000;
		end;
	end;

	if self.requestWayPointTimer >= 0 then
		self.requestWayPointTimer = self.requestWayPointTimer - dt;
	end;

	if g_currentMission.AutoDrive ~= nil then
		if g_server == nil and g_currentMission.AutoDrive.requestedWaypoints ~= true and self.requestWayPointTimer < 0 and networkGetObjectId(self) ~= nil then
			AutoDriveMapEvent:sendEvent(self);
			g_currentMission.AutoDrive.requestedWaypoints = true;
		end;
	end;

	--if self.currentInput ~= "" and self.isServer then
	--	--print("I am the server and start input handling. lets see if they think so too");
	--	AutoDrive:InputHandling(self, self.currentInput);
	--end;

	if self.bActive == true and self.isServer then
		self.forceIsActive = true;
		self.stopMotorOnLeave = false;
		self.disableCharacterOnLeave = true;
		--self.isControlled = true;
		if self.isMotorStarted == false then
			self:startMotor();
		end;

		self.nTimeToDeadLock = self.nTimeToDeadLock - dt;
		if self.nTimeToDeadLock < 0 and self.nTimeToDeadLock ~= -1 then
			--print("Deadlock reached due to timer");
			self.bDeadLock = true;
		end;
	else
		self.bDeadLock = false;
		self.nTimeToDeadLock = 15000;
		self.bDeadLockRepairCounter = 4;
		--self.forceIsActive = false;
		--self.stopMotorOnLeave = true;
	end;

	if self.printMessage ~= nil then
		self.nPrintTime = self.nPrintTime - dt;
		if self.nPrintTime < 0 then
			self.nPrintTime = 3000;
			self.printMessage = nil;
		end;
	end;

	if self == g_currentMission.controlledVehicle then
		if AutoDrive.printMessage ~= nil then
			AutoDrive.nPrintTime = AutoDrive.nPrintTime - dt;
			if AutoDrive.nPrintTime < 0 then
				AutoDrive.nPrintTime = 3000;
				AutoDrive.printMessage = nil;
			end;
		end;

		if self.ad.sToolTip ~= "" then
			if self.ad.nToolTipWait <= 0 then
				if self.ad.nToolTipTimer > 0 then
					self.ad.nToolTipTimer = self.ad.nToolTipTimer - dt;
				else
					self.ad.sToolTip = "";
				end;
			else
				self.ad.nToolTipWait = self.ad.nToolTipWait - dt;
			end;
		end;

		if self.frontLoaderCam ~= nil then

			local inputW = InputBinding.getDigitalInputAxis(InputBinding.AXIS_FRONTLOADER_ARM) + InputBinding.getAnalogInputAxi	(InputBinding.AXIS_FRONTLOADER_ARM); --InputBinding.getDigitalInputAxis(InputBinding.AXIS_LOOK_UPDOWN_VEHICLE)+InputBinding.getAnalogInputAxs	(InputBinding.AXIS_LOOK_UPDOWN_VEHICLE);

			--self.ad.frontLoaderCamShift = Utils.getNoNil(self.ad.frontLoaderCamShift,0) + inputW*8e-4*dt;
			--self.ad.frontLoaderCamShift = Utils.clamp(self.ad.frontLoaderCamShift,-1,2);

			if self.ad.cam == true then

				local node = self.components[1].node --self.frontloaderAttacher.attacherJoint.rootNode;
				local nodeTool = node;
				for _,impl in pairs(self.attachedImplements) do
					if impl.object ~= nil then
						if impl.object.typeName == "attachableFrontloader" then
							--print("Selected frontloader tool as root node");
							nodeTool = impl.object.attacherJoints[1].jointTransform;
						end;
					end;
				end;
				if self.typeDesc == "telehandler" then
					nodeTool = self.attacherJoints[1].jointTransform;
				end;
				local xW,yW,zW = getWorldTranslation(node);
				local xTool,yTool,zTool = getWorldTranslation(node);
				local xCam,yCam,zCam = getWorldTranslation(self.frontLoaderCam);
				if nodeTool == nil then
					nodeTool = node;
					self.frontLoaderCamOffsetX = self.sizeWidth/2; -- + 0.8;
					self.frontLoaderCamOffsetZ = self.sizeLength/2 + 1.0; -- -1.0
				else
					xTool,yTool,zTool = getWorldTranslation(nodeTool);
					local tempToolX,tempToolY,tempToolZ = worldToLocal(node,xTool,yTool,zTool);
					local tempCamX,tempCamY,tempCamZ = worldToLocal(node,xCam,yCam,zCam);
					self.frontLoaderCamOffsetX = (tempToolX-tempCamX)*0.5; -- + 0.8;
					self.frontLoaderCamOffsetZ = (tempToolZ-tempCamZ)*0.5; -- -1.0
				end;

				local inputW = InputBinding.getDigitalInputAxis(InputBinding.AXIS_LOOK_UPDOWN_VEHICLE)+InputBinding.getAnalogInputAxi	(InputBinding.AXIS_LOOK_UPDOWN_VEHICLE);

				self.ad.frontLoaderCamShiftAngle = Utils.getNoNil(inputW*6e-3*dt,0);
				self.ad.frontLoaderCamShiftAngle = Utils.clamp(self.ad.frontLoaderCamShiftAngle,-math.pi,math.pi);

				local inputW = InputBinding.getDigitalInputAxis(InputBinding.AXIS_LOOK_LEFTRIGHT_VEHICLE)+InputBinding.getAnalogInputAxi	(InputBinding.AXIS_LOOK_LEFTRIGHT_VEHICLE);

				self.ad.frontLoaderCamShift = Utils.getNoNil(self.ad.frontLoaderCamShift,0) + inputW*3.5e-3*dt;
				self.ad.frontLoaderCamShift = Utils.clamp(self.ad.frontLoaderCamShift,-5,10);

				local x,y,z = worldToLocal(node,xW,yTool+0,zW) --+self.ad.frontLoaderCamShift
				setTranslation(self.frontLoaderCam,x+self.frontLoaderCamOffsetX - self.ad.frontLoaderCamShift,y,z+self.frontLoaderCamOffsetZ);

				xTool,yTool,zTool = getWorldTranslation(nodeTool);
				xCam,yCam,zCam = getWorldTranslation(self.frontLoaderCam);
				local tempToolX,tempToolY,tempToolZ = worldToLocal(node,xTool,yTool,zTool);
				local tempCamX,tempCamY,tempCamZ = worldToLocal(node,xCam,yCam,zCam);
				local camToTool = (math.asin( (tempToolX-tempCamX) / math.sqrt( math.pow((tempToolX-tempCamX),2)+ math.pow((tempToolZ-tempCamZ+1.5),2) )) +	math.pi);
				local before = camToTool;
				if camToTool >= math.pi then
					camToTool = -2*math.pi+camToTool;
				end;
				local rx,ry,rz = getRotation( self.frontLoaderCam);
				local wrx,wry,wrz = localDirectionToLocal(self.frontLoaderCam,node, rx,ry,rz ) ;
				self.ad.frontLoaderCamShiftSide = (camToTool-ry)*0.98;

				rotate(self.frontLoaderCam,self.ad.frontLoaderCamShiftAngle ,self.ad.frontLoaderCamShiftSide,0);

				setCamera(self.frontLoaderCam);

			end;
		end;
	end;

	--set target waypoint and create route
	--follow next waypoint until close enough (0.5m?), then select next waypoint
	--stop vehicle on arrival


	local veh = self;

	--follow waypoints on route:

	if self.bStopAD == true and self.isServer then
		AutoDrive:deactivate(self,false);
		self.bStopAD = false;
		self.bPaused = false;
	end;

	if self.components ~= nil and self.isServer then

		local x,y,z = getWorldTranslation( self.components[1].node );
		local xl,yl,zl = worldToLocal(veh.components[1].node, x,y,z);

		if self.bActive == true and self.bPaused == false then
			if self.steeringEnabled then
				self.steeringEnabled = false;
			end

			if self.bInitialized == false then
				self.nTimeToDeadLock = 15000;
				if self.bTargetMode == true then
					local closest = AutoDrive:findMatchingWayPoint(veh) --AutoDrive:findClosestWayPoint(veh);
					self.ad.wayPoints = AutoDrive:FastShortestPath(g_currentMission.AutoDrive.mapWayPoints, closest, g_currentMission.AutoDrive.mapMarke	[self.nMapMarkerSelected].name, self.ntargetSelected);
					if self.ad.wayPoints[2] ~= nil then
						self.nCurrentWayPoint = 2;
					else
						self.nCurrentWayPoint = 1;
					end;
				else
					self.nCurrentWayPoint = 1;
				end;

				if self.ad.wayPoints[self.nCurrentWayPoint] ~= nil then
					self.nTargetX = self.ad.wayPoints[self.nCurrentWayPoint].x;
					self.nTargetZ = self.ad.wayPoints[self.nCurrentWayPoint].z;
					self.bInitialized = true;
					self.bDrivingForward = true;

				else
					--print("Autodrive hat ein Problem festgestellt");
					print("Autodrive hat ein Problem beim Initialisieren festgestellt");
					AutoDrive:deactivate(self,true);
				end;
			else
				local min_distance = 1.8;
				if self.typeDesc == "combine" or  self.typeDesc == "harvester" then
					min_distance = 6;
				end;
				if self.typeDesc == "telehandler" then
					min_distance = 3;
				end;

				if getDistance(x,z, self.nTargetX, self.nTargetZ) < min_distance then
					self.previousSpeed = self.speed_override;
					self.nTimeToDeadLock = 15000;

					if self.ad.wayPoints[self.nCurrentWayPoint+1] ~= nil then
						self.nCurrentWayPoint = self.nCurrentWayPoint + 1;
						self.nTargetX = self.ad.wayPoints[self.nCurrentWayPoint].x;
						self.nTargetZ = self.ad.wayPoints[self.nCurrentWayPoint].z;
					else
						--print("Last waypoint reached");
						if self.bUnloadAtTrigger == false then
							if self.bRoundTrip == false then
								--print("No Roundtrip");
								if self.bReverseTrack == true then
									--print("Starting reverse track");
									--reverse driving direction
									if self.bDrivingForward == true then
										self.bDrivingForward = false;
									else
										self.bDrivingForward = true;
									end;
									--reverse waypoints
									local reverseWaypoints = {};
									local _counterWayPoints = 0;
									for n in pairs(self.ad.wayPoints) do
										_counterWayPoints = _counterWayPoints + 1;
									end;
									for n in pairs(self.ad.wayPoints) do
										reverseWaypoints[_counterWayPoints] = self.ad.wayPoints[n];
										_counterWayPoints = _counterWayPoints - 1;
									end;
									for n in pairs(reverseWaypoints) do
										self.ad.wayPoints[n] = reverseWaypoints[n];
									end;
									--start again:
									self.nCurrentWayPoint = 1
									self.nTargetX = self.ad.wayPoints[self.nCurrentWayPoint].x;
									self.nTargetZ = self.ad.wayPoints[self.nCurrentWayPoint].z;

								else
									--print("Shutting down");
									AutoDrive.printMessage = g_i18n:getText("AD_Driver_of") .. " " .. self.name .. " " .. g_i18n:getText("AD_has_reached") .. "	" .. self.sTargetSelected;
									AutoDrive.nPrintTime = 6000;

									if self.isServer == true then
										xl,yl,zl = worldToLocal(veh.components[1].node, self.nTargetX,y,self.nTargetZ);
										AIVehicleUtil.driveToPoint(self, dt, 0, true, self.bDrivingForward, xl, zl, 0, false );
										veh:setCruiseControlState(Drivable.CRUISECONTROL_STATE_OFF);
									end;

									veh:setCruiseControlState(Drivable.CRUISECONTROL_STATE_OFF);
									AutoDrive:deactivate(self,true);
								end;
							else
								--print("Going into next round");
								self.nCurrentWayPoint = 1
								if self.ad.wayPoints[self.nCurrentWayPoint] ~= nil then
									self.nTargetX = self.ad.wayPoints[self.nCurrentWayPoint].x;
									self.nTargetZ = self.ad.wayPoints[self.nCurrentWayPoint].z;
								else
									print("Autodrive hat ein Problem beim Rundkurs festgestellt");
									AutoDrive:deactivate(self,true);
								end;
							end;
						else
							if self.bUnloadSwitch == true then
								self.nTimeToDeadLock = 15000;

								local closest = self.ad.wayPoints[self.nCurrentWayPoint].id;
								self.ad.wayPoints = AutoDrive:FastShortestPath(g_currentMission.AutoDrive.mapWayPoints, closest,	g_currentMission.AutoDrive.mapMarker[self.nMapMarkerSelected].name, self.ntargetSelected);
								self.nCurrentWayPoint = 1;

								self.nTargetX = self.ad.wayPoints[self.nCurrentWayPoint].x;
								self.nTargetZ = self.ad.wayPoints[self.nCurrentWayPoint].z;

								self.bUnloadSwitch = false;
							else
								self.nTimeToDeadLock = 15000;

								local closest = self.ad.wayPoints[self.nCurrentWayPoint].id;
								self.ad.wayPoints = AutoDrive:FastShortestPath(g_currentMission.AutoDrive.mapWayPoints, closest,	g_currentMission.AutoDrive.mapMarker[self.nMapMarkerSelected_Unload].name, g_currentMission.AutoDrive.mapMarkr	[self.nMapMarkerSelected_Unload].id);
								self.nCurrentWayPoint = 1;

								self.nTargetX = self.ad.wayPoints[self.nCurrentWayPoint].x;
								self.nTargetZ = self.ad.wayPoints[self.nCurrentWayPoint].z;

								self.bPaused = true;
								self.bUnloadSwitch = true;
							end;
						end;
					end;
				end;
			end;


			if self.bActive == true then
				if self.isServer == true then

					local traffic = AutoDrive:detectTraffic(self,self.ad.wayPoints[self.nCurrentWayPoint]);
					local oneWayTraffic = false;
					if self.bReverseTrack == false then
						oneWayTraffic = AutoDrive:detectAdTrafficOnRoute(self);
					end;

					if self.ad.wayPoints[self.nCurrentWayPoint+1] ~= nil then
						--AutoDrive:addlog("Issuing Drive Request");
						xl,yl,zl = worldToLocal(veh.components[1].node, self.nTargetX,y,self.nTargetZ);

						self.speed_override = -1;
						if self.ad.wayPoints[self.nCurrentWayPoint-1] ~= nil and self.ad.wayPoints[self.nCurrentWayPoint+1] ~= nil then
							local wp_ahead = self.ad.wayPoints[self.nCurrentWayPoint+1];
							local wp_current = self.ad.wayPoints[self.nCurrentWayPoint];
							local wp_ref = self.ad.wayPoints[self.nCurrentWayPoint-1];
							local angle = AutoDrive:angleBetween( 	{x=	wp_ahead.x	-	wp_ref.x, z = wp_ahead.z - wp_ref.z },
																	{x=	wp_current.x-	wp_ref.x, z = wp_current.z - wp_ref.z } )

							if angle < 3 then self.speed_override = self.nSpeed;
							elseif angle >= 3 and angle < 5 then self.speed_override = 38;
							elseif angle >= 5 and angle < 8 then self.speed_override = 32;
							elseif angle >= 8 and angle < 12 then self.speed_override = 25;
							elseif angle >= 12 and angle < 15 then self.speed_override = 15;
							elseif angle >= 15 and angle < 20 then self.speed_override = 14;
							elseif angle >= 20 and angle < 30 then self.speed_override = 9;
							elseif angle >= 30 and angle < 90 then self.speed_override = 4;
							end;

							local distance_wps = getDistance(wp_ref.x,wp_ref.z,wp_current.x,wp_current.z);
							local distance_vehicle = getDistance(wp_current.x,wp_current.z,x,z );

							if self.previousSpeed > self.speed_override then
								self.speed_override = self.speed_override + math.min(1,distance_vehicle/distance_wps) * (self.previousSpeed -	self.speed_override);
							else
								self.speed_override = self.speed_override - math.min(1,distance_vehicle/distance_wps) * (self.speed_override -	self.previousSpeed);
							end;
						end;
						if self.speed_override == -1 then self.speed_override = self.nSpeed; end;
						if self.speed_override > self.nSpeed then self.speed_override = self.nSpeed; end;

						local wp_new = nil;

						if wp_new ~= nil then
							xl,yl,zl = worldToLocal(veh.components[1].node, wp_new.x,y,wp_new.z);
						end;

						if self.bUnloadAtTrigger == true then
							local destination = g_currentMission.AutoDrive.mapWayPoints[self.ntargetSelected_Unload];
							local start = g_currentMission.AutoDrive.mapWayPoints[self.ntargetSelected];
							local distance1 = getDistance(x,z, destination.x, destination.z);
							local distance2 = getDistance(x,z, start.x, start.z);
							if distance1 < 20 or distance2 < 20 then
								if self.speed_override > 12 then
									self.speed_override = 12;
								end;
							end;
						end;

						local finalSpeed = self.speed_override;
						local finalAcceleration = true;
						if traffic or oneWayTraffic then
							finalSpeed = 0;
							veh:setCruiseControlState(Drivable.CRUISECONTROL_STATE_OFF);
							finalAcceleration = false;
							self.nTimeToDeadLock = 15000;
						else
							veh:setCruiseControlState(Drivable.CRUISECONTROL_STATE_ACTIVE);
						end;

						AIVehicleUtil.driveToPoint(self, dt, 1, finalAcceleration, self.bDrivingForward, xl, zl, finalSpeed, false );
					else
						--print("Reaching last waypoint - slowing down");
						local finalSpeed = 8;
						local finalAcceleration = true;
						if traffic then
							finalSpeed = 0;
							veh:setCruiseControlState(Drivable.CRUISECONTROL_STATE_OFF);
							finalAcceleration = false;
							self.nTimeToDeadLock = 15000;
						else
							veh:setCruiseControlState(Drivable.CRUISECONTROL_STATE_ACTIVE);
						end;
						xl,yl,zl = worldToLocal(veh.components[1].node, self.nTargetX,y,self.nTargetZ);
						AIVehicleUtil.driveToPoint(self, dt, 1, finalAcceleration, self.bDrivingForward, xl, zl, finalSpeed, false );
					end;
				end;
			end;
		end;

		if self.bPaused == true then
			self.nTimeToDeadLock = 15000;
			if self.nPauseTimer > 0 then
				if self.isServer == true then
					xl,yl,zl = worldToLocal(veh.components[1].node, self.nTargetX,y,self.nTargetZ);
					AIVehicleUtil.driveToPoint(self, dt, 0, false, self.bDrivingForward, xl, zl, 0, false );
					veh:setCruiseControlState(Drivable.CRUISECONTROL_STATE_OFF);
				end;
				self.nPauseTimer = self.nPauseTimer - dt;
			end;
		else
			if self.nPauseTimer < 5000 then
				self.nPauseTimer = 5000;
			end;
		end;

		if self.typeDesc == "combine" or self.typeDesc == "harvester" then
			veh.aiSteeringSpeed = 1;
		else
			veh.aiSteeringSpeed = 0.4;
		end;
		--print(" target: " .. self.nTargetX .. "/" .. self.nTargetZ .. " steeringSpeed: " .. veh.aiSteeringSpeed);
	end;

	if self.bDeadLock == true and self.bActive == true and self.isServer then
		AutoDrive.printMessage = g_i18n:getText("AD_Driver_of") .. " " .. self.name .. " " .. g_i18n:getText("AD_got_stuck");
		AutoDrive.nPrintTime = 10000;

		--deadlock handling
		if self.bDeadLockRepairCounter < 1 then
			AutoDrive.printMessage = g_i18n:getText("AD_Driver_of") .. " " .. self.name .. " " .. g_i18n:getText("AD_got_stuck");
			AutoDrive.nPrintTime = 10000;
			self.bStopAD = true;
			self.bActive = false;
		else
			--print("AD: Trying to recover from deadlock")
			if self.ad.wayPoints[self.nCurrentWayPoint+2] ~= nil then
				self.nCurrentWayPoint = self.nCurrentWayPoint + 1;
				self.nTargetX = self.ad.wayPoints[self.nCurrentWayPoint].x;
				self.nTargetZ = self.ad.wayPoints[self.nCurrentWayPoint].z;

				self.bDeadLock = false;
				self.nTimeToDeadLock = 15000;
				self.bDeadLockRepairCounter = self.bDeadLockRepairCounter - 1;
			end;
		end;
	end;

	if veh == g_currentMission.controlledVehicle
	and veh ~= nil
	and self.bcreateMode == true
	then
		--manually create waypoints in create-mode:
		--record waypoints every 6m
		local i = 0;
		for n in pairs(self.ad.wayPoints) do
			i = i+1;
		end;
		i = i+1;

		--first entry
		if i == 1 then
			local x1,y1,z1 = getWorldTranslation(veh.components[1].node);
			self.ad.wayPoints[i] = createVector(x1,y1,z1);

			if self.bCreateMapPoints == true then
				AutoDrive:MarkChanged();
				local ad = g_currentMission.AutoDrive
				ad.mapWayPointsCounter = ad.mapWayPointsCounter + 1;
				ad.mapWayPoints[ad.mapWayPointsCounter] = createNode(ad.mapWayPointsCounter,{},{},{},{});
				ad.mapWayPoints[ad.mapWayPointsCounter].x = x1;
				ad.mapWayPoints[ad.mapWayPointsCounter].y = y1;
				ad.mapWayPoints[ad.mapWayPointsCounter].z = z1;
				--print("Creating Waypoint #" .. ad.mapWayPointsCounter);
			end;
			i = i+1;
		else
			if i == 2 then
				local x,y,z = getWorldTranslation(veh.components[1].node);
				local wp = self.ad.wayPoints[i-1];
				if getDistance(x,z,wp.x,wp.z) > 3 then
					self.ad.wayPoints[i] = createVector(x,y,z);
					local ad = g_currentMission.AutoDrive
					if self.bCreateMapPoints == true then
						ad.mapWayPointsCounter = ad.mapWayPointsCounter + 1;
						--edit previous point
						ad.mapWayPoints[ad.mapWayPointsCounter-1].out[1] =	ad.mapWayPointsCounter;
						ad.mapWayPoints[ad.mapWayPointsCounter-1].out_cost[1] = 1;
						--edit current point
						--print("Creating Waypoint #" .. ad.mapWayPointsCounter);
						ad.mapWayPoints[ad.mapWayPointsCounter] = createNode(ad.mapWayPointsCounter,{},{},{},{});
						ad.mapWayPoints[ad.mapWayPointsCounter].incoming[1] = ad.mapWayPointsCounter-1;
						ad.mapWayPoints[ad.mapWayPointsCounter].x = x;
						ad.mapWayPoints[ad.mapWayPointsCounter].y = y;
						ad.mapWayPoints[ad.mapWayPointsCounter].z = z;
					end;
					if self.bcreateModeDual == true then
						ad.mapWayPoints[ad.mapWayPointsCounter-1].incoming[1] = ad.mapWayPointsCounter;
						--edit current point
						ad.mapWayPoints[ad.mapWayPointsCounter].out[1] = ad.mapWayPointsCounter-1;
						ad.mapWayPoints[ad.mapWayPointsCounter].out_cost[1] = 1;
					end;

					i = i+1;
				end;
			else
				local x,y,z = getWorldTranslation(veh.components[1].node);
				local wp = self.ad.wayPoints[i-1];
				local wp_ref = self.ad.wayPoints[i-2]
				local angle = AutoDrive:angleBetween( {x=x-wp_ref.x,z=z-wp_ref.z},{x=wp.x-wp_ref.x, z = wp.z - wp_ref.z } )
				--print("Angle between: " .. angle );
				local max_distance = 6;
				if angle < 1 then max_distance = 20; end;
				elseif angle >= 1 and angle < 2 then max_distance = 12;
				elseif angle >= 2 and angle < 3 then max_distance = 9;
				elseif angle >= 3 and angle < 5 then max_distance = 6;
				elseif angle >= 5 and angle < 8 then max_distance = 4;
				elseif angle >= 8 and angle < 12 then max_distance = 2;
				elseif angle >= 12 and angle < 15 then max_distance = 1;
				elseif angle >= 15 and angle < 50 then max_distance = 0.5;
				end

				if getDistance(x,z,wp.x,wp.z) > max_distance then
					self.ad.wayPoints[i] = createVector(x,y,z);
					local ad = g_currentMission.AutoDrive
					if self.bCreateMapPoints == true then
						ad.mapWayPointsCounter = ad.mapWayPointsCounter + 1;
						--edit previous point
						local out_index = 1;
						if ad.mapWayPoints[ad.mapWayPointsCounter-1].out[out_index] ~= nil then	out_index = out_index+1; end;
						ad.mapWayPoints[ad.mapWayPointsCounter-1].out[out_index] =	ad.mapWayPointsCounter;
						ad.mapWayPoints[ad.mapWayPointsCounter-1].out_cost[out_index] = 1;
						--edit current point
						--print("Creating Waypoint #" .. ad.mapWayPointsCounter);
						ad.mapWayPoints[ad.mapWayPointsCounter] = createNode(ad.mapWayPointsCounter,{},{},{},{});
						ad.mapWayPoints[ad.mapWayPointsCounter].incoming[1] = ad.mapWayPointsCounter-1;
						ad.mapWayPoints[ad.mapWayPointsCounter].x = x;
						ad.mapWayPoints[ad.mapWayPointsCounter].y = y;
						ad.mapWayPoints[ad.mapWayPointsCounter].z = z;
					end;
					if self.bcreateModeDual == true then
						ad.mapWayPoints[ad.mapWayPointsCounter-1].incoming[2] = ad.mapWayPointsCounter;
						--edit current point
						ad.mapWayPoints[ad.mapWayPointsCounter].out[1] = ad.mapWayPointsCounter-1;
						ad.mapWayPoints[ad.mapWayPointsCounter].out_cost[1] = 1;
					end;

					i = i+1;
				end;
			end;
		end;
	end;

	if self.bActive == true and self.bUnloadAtTrigger == true and self.isServer == true then
		local trailers = {};
		local trailerCount = 0;
		local trailer = nil;
		if self.attachedImplements ~= nil then
			for _, implement in pairs(self.attachedImplements) do
				if implement.object ~= nil then
					if implement.object.typeDesc == g_i18n:getText("typeDesc_tipper") then
						trailer = implement.object;
						trailers[1] = trailer;
						trailerCount = 1;
						for __,impl in pairs(trailer.attachedImplements) do
							if impl.object ~= nil then
								if impl.object.typeDesc == g_i18n:getText("typeDesc_tipper") then
									trailers[2] = impl.object;
									trailerCount = 2;
									for ___,implement3 in pairs(trailers[2].attachedImplements) do
										if implement3.object ~= nil then
											if implement3.object.typeDesc == g_i18n:getText("typeDesc_tipper") then
												trailers[3] = implement3.object;
												trailerCount = 3;
											end;
										end;
									end;
								end;
							end;
						end;
					end;
				end;
			end;

			--check distance to unloading destination, do not unload too far from it. You never know where the tractor might already drive over an unloading	trigger before that
			local x,y,z = getWorldTranslation(veh.components[1].node);
			local destination = g_currentMission.AutoDrive.mapWayPoints[self.ntargetSelected_Unload];
			local distance = getDistance(x,z, destination.x, destination.z);
			if distance < 40 then
				--check trailer trigger: trailerTipTriggers
				local globalUnload = false;
				for _,trailer in pairs(trailers) do
					if trailer ~= nil then
						for _,trigger in pairs(g_currentMission.tipTriggers) do
							local allowed,minDistance,bestPoint = trigger:getTipInfoForTrailer(trailer, trailer.preferedTipReferencePointIndex);
							--print("Min distance: " .. minDistance);
							if allowed and minDistance == 0 then
								if trailer.tipping ~= true  then
									--print("toggling tip state for " .. trigger.stationName .. " distance: " .. minDistance );
									trailer:toggleTipState(trigger, bestPoint);
									self.bPaused = true;
									self.bUnloading = true;
									trailer.tipping = true;
								end;
							end;

							if trailer.tipState == Trailer.TIPSTATE_CLOSED and self.bUnloading == true and trailer.tipping == true then
								--print("trailer is unloaded. continue");
								trailer.tipping = false;
							end;

							if trailer.tipping == true or self.bPaused == false then
								globalUnload = true;
							end;
						end;
					end;
				end;
				if (globalUnload == false and self.bUnloading == true) or self.bPaused == false then
					self.bPaused = false;
					self.bUnloading = false;
				end;
			end;

			--check distance to unloading destination, do not unload too far from it. You never know where the tractor might already drive over an unloading	trigger before that
			local x,y,z = getWorldTranslation(veh.components[1].node);
			local destination = g_currentMission.AutoDrive.mapWayPoints[self.ntargetSelected];
			local distance = getDistance(x,z, destination.x, destination.z);
			if distance < 40 then
				--print("distance < 40");
				local globalLoading = false;

				for _,trailer in pairs(trailers) do
					if trailer ~= nil and self.unloadType ~= -1 then
						--print("Trailer detected. unloadType = " .. self.unloadType .. " level: " .. trailer:getFillLevel(self.unloadType));
						for _,trigger in pairs(g_currentMission.siloTriggers) do

							local valid = trigger:getIsValidTrailer(trailer);
							local level = trigger:getFillLevel(self.unloadType);
							local activatable = trigger.activeTriggers >=4 --trigger:getIsActivatable()
							local correctTrailer = false;
							if trigger.siloTrailer == trailer then correctTrailer = true; end;

							--print("valid: " .. tostring(valid) .. " level: " ..  tostring(level) .. " activatable: " .. tostring(activatable) .. "	correctTrailer: " .. tostring(correctTrailer) );
							if valid and level > 0 and activatable and correctTrailer and trailer.bLoading ~= true then --
								if	trailer:getFreeCapacity() > 1 then
									--print("Starting to unload into trailer" );
									trigger:startFill(self.unloadType);
									self.bPaused = true;
									self.bLoading = true;
									trailer.bLoading = true;
								end;
							end;

							if (trailer:getFreeCapacity(self.unloadType) <= 0 or self.bPaused == false) and trailer.bLoading == true and correctTrailer == true	then
								--print("trailer is full. continue");
								trigger:stopFill();
								trailer.bLoading = false;
							end;

							if trailer.bLoading == true then
								globalLoading = true;
							end;
						end;
					end;
				end;
				if (globalLoading == false and self.bLoading == true) or self.bPaused == false then
					self.bPaused = false;
					self.bLoading = false;
				end;
			end;
		end;

		if self.bPaused == true and not self.bUnloading and not self.bLoading then
			if trailer == nil or trailer:getFreeCapacity() <= 0 then
				self.bPaused = false;
			end;
		end;
	end;
	--trigger test end

	--if self.isServer == true then
	--	AutoDriveInputEvent:sendEvent(self);
	--	--print("Sending Event as server");
	--end;

	--AutoDrive:log(dt);
end;

function AutoDrive:updateButtons(vehicle)

	for _,button in pairs(AutoDrive.Hud.Buttons) do
		if button.name == "input_silomode" then
			if vehicle.bReverseTrack == true then
				button.img_active = button.img_on;
			else
				if vehicle.bUnloadAtTrigger == true then
					button.img_active = button.img_3;
				else
					button.img_active = button.img_off;
				end;
			end;
			--button.ov = Overlay:new(nil, button.img_active,button.posX ,button.posY , AutoDrive.Hud.buttonWidth, AutoDrive.Hud.buttonHeight);
			button.ov:setImage(button.img_active)
		end;

		if button.name == "input_record" then
			if vehicle.bcreateMode == true then
				button.img_active = button.img_on;
				if vehicle.bcreateModeDual == true then
					button.img_active = button.img_dual;
				end;
			else
				button.img_active = button.img_off;
			end;
			--button.ov = Overlay:new(nil, button.img_active,button.posX ,button.posY , AutoDrive.Hud.buttonWidth, AutoDrive.Hud.buttonHeight);
			button.ov:setImage(button.img_active)
		end;

		if button.name == "input_start_stop" then
			if vehicle.bActive == true then
				button.img_active = button.img_on;
			else
				button.img_active = button.img_off;
			end;
			--button.ov = Overlay:new(nil, button.img_active,button.posX ,button.posY , AutoDrive.Hud.buttonWidth, AutoDrive.Hud.buttonHeight);
			button.ov:setImage(button.img_active)
		end;

		if button.name == "input_debug" then
			if vehicle.bCreateMapPoints == true then
				button.img_active = button.img_on;
			else
				button.img_active = button.img_off;
			end;
			--button.ov = Overlay:new(nil, button.img_active,button.posX ,button.posY , AutoDrive.Hud.buttonWidth, AutoDrive.Hud.buttonHeight);
			button.ov:setImage(button.img_active)
		end;

		--[[
		if button.name == "input_showClosest" then
			if vehicle.bShowDebugMapMarker == true then
				button.img_active = button.img_on;
			else
				button.img_active = button.img_off;
			end;
			--button.ov = Overlay:new(nil, button.img_active,button.posX ,button.posY , AutoDrive.Hud.buttonWidth, AutoDrive.Hud.buttonHeight);
			button.ov:setImage(button.img_active)
		end;
		--]]

		if button.name == "input_showNeighbor" then
			button.isVisible = vehicle.bCreateMapPoints

			if vehicle.bShowSelectedDebugPoint == true then
				button.img_active = button.img_on;
			else
				button.img_active = button.img_off;
			end;
			--button.ov = Overlay:new(nil, button.img_active,button.posX ,button.posY , AutoDrive.Hud.buttonWidth, AutoDrive.Hud.buttonHeight);
			button.ov:setImage(button.img_active)
		end;

		if button.name == "input_toggleConnection"
		or button.name == "input_nextNeighbor"
		or button.name == "input_createMapMarker"
		or button.name == "input_exportRoutes"
		then
			button.isVisible = vehicle.bCreateMapPoints
		end;

		if button.name == "input_recalculate" then
			if AutoDrive:GetChanged() == true then
				button.isVisible = true;
			else
				button.isVisible = false;
			end;

			if g_currentMission.AutoDrive.Recalculation ~= nil then
				if  g_currentMission.AutoDrive.Recalculation.continue == true then
					button.img_active = button.img_off;
				else
					button.img_active = button.img_on;
				end;
			else
				button.img_active = button.img_on;
			end;
			--button.ov = Overlay:new(nil, button.img_active,button.posX ,button.posY , AutoDrive.Hud.buttonWidth, AutoDrive.Hud.buttonHeight);
			button.ov:setImage(button.img_active)
		end;

		if button.name == "input_removeWaypoint" then
			if vehicle.bCreateMapPoints == true then
				button.isVisible = true
				button.img_active = button.img_on;
			else
				button.isVisible = false;
				button.img_active = button.img_off;
			end;
			--button.ov = Overlay:new(nil, button.img_active,button.posX ,button.posY , AutoDrive.Hud.buttonWidth, AutoDrive.Hud.buttonHeight);
			button.ov:setImage(button.img_active)
		end;
		--[[
		if button.name == "input_nextTarget_Unload" then
			if vehicle.bUnloadAtTrigger == true then
				button.isVisible = true;
			else
				button.isVisible = false;
			end;
		end;
		if button.name == "input_previousTarget_Unload" then
			if vehicle.bUnloadAtTrigger == true then
				button.isVisible = true;
			else
				button.isVisible = false;
			end;
		end;

		if button.name == "input_continue" then
			if vehicle.bUnloadAtTrigger == true then
				button.isVisible = true;
			else
				button.isVisible = false;
			end;
		end;
		--]]
	end;
end;

function AutoDrive:log(dt)
	self.nlastLogged = self.nlastLogged + dt;
	if self.nlastLogged >= self.nloggingInterval then
		self.nlastLogged = self.nlastLogged - self.nloggingInterval;
		if self.logMessage ~= "" then
			print(self.logMessage);
			self.logMessage = "";
		end;
	end;
end;

function AutoDrive:addlog(text)
	--[[
	if string.find(self.logMessage, text) == nil then
		self.logMessage = self.logMessage .. text .. "\n";
	end;
	--]]
	self.logMessage = text;
end;

function createVector(x,y,z)
	local table t = {};
	t["x"] = x;
	t["y"] = y;
	t["z"] = z;
	return t;
end;

function getDistance(x1,z1,x2,z2)
	return math.sqrt((x1-x2)*(x1-x2) + (z1-z2)*(z1-z2) );
end;

function readWayPoints()
	--read xmlFile
	--unique for each map
	--waypoints are ordered in a bidirectional graph
end;

function findWay(startWayPointID, targetWayPointID)
	--graph algorithm to find shortest path towards target
	--return list of waypoints
end;

function AutoDrive:findClosestWayPoint(veh)
	--returns waypoint closest to vehicle position
	local x1,_,z1 = getWorldTranslation(veh.components[1].node);
	local closest = 1;
	local dist = math.huge
	for _, wp in pairs(g_currentMission.AutoDrive.mapWayPoints) do
		local dis = getDistance(wp.x,wp.z, x1,z1);
		if dis < dist then
			closest = i;
			dist = dis;
		end;
	end
	return closest;
end;

function AutoDrive:findMatchingWayPoint(veh)
	--returns waypoint closest to vehicle position and with the most suited heading
	local x1,_,z1 = getWorldTranslation(veh.components[1].node);

	local candidates = {};
	for i, wp in pairs(g_currentMission.AutoDrive.mapWayPoints) do
		local dis = getDistance(wp.x,wp.z, x1,z1);
		if dis < 20 and dis > 1 then
			candidates[#candidates+1] = i;
		end;
	end;

	if not next(candidates) then
		return AutoDrive:findClosestWayPoint(veh);
	end;

	local rx,_,rz = localDirectionToWorld(veh.components[1].node, 0,0,1);
	local vehicleVector = {x= math.sin(rx) ,z= math.sin(rz) };

	--drawDebugLine(x1, y1+4, z1, 1,0,0, x1 + math.sin(rx)*2 , y1+4, z1 + math.sin(rz), 1,0,0);

	local closest = -1;
	local distance = -1;
	local angle = -1;
	local mapWayPoints = g_currentMission.AutoDrive.mapWayPoints

	for i,id in pairs(candidates) do
		local point = mapWayPoints[id];
		local nextP = -1;
		if point.out ~= nil then
			if point.out[1] ~= nil then
				nextP = mapWayPoints[point.out[1]];
			end;
		end;
		if nextP ~= -1 then
			local tempVec = {x= nextP.x - point.x, z= nextP.z - point.z};
			local tempVecToVehicle = { x = point.x - x1, z = point.z - z1 };
			local tempAngle = AutoDrive:angleBetween(vehicleVector, tempVec);
			local tempAngleToVehicle = AutoDrive:angleBetween(vehicleVector, tempVecToVehicle);
			local dis = getDistance(point.x,point.z, x1,z1);

			if closest == -1 and math.abs(tempAngle) < 60 and math.abs(tempAngleToVehicle) < 30 then
				closest = point.id;
				distance = dis;
				angle = tempAngle;
				--print("TempAngle to vehicle: " .. tempAngleToVehicle);
			else
				if math.abs(tempAngle) < math.abs(angle) then
					if math.abs(tempAngleToVehicle) < 30 then
						if math.abs(angle) < 20 then
							if dis < distance then
								closest = point.id;
								distance = dis;
								angle = tempAngle;
								--print("TempAngle to vehicle: " .. tempAngleToVehicle);
							end;
						else
							closest = point.id;
							distance = dis;
							angle = tempAngle;
						end;
					end;
				end;
			end;
		end;
	end;

	if closest == -1 then
		return AutoDrive:findClosestWayPoint(veh);
	end;

	--local tempVecToVehicle = { x = g_currentMission.AutoDrive.mapWayPoints[closest].x - x1, z = g_currentMission.AutoDrive.mapWayPoints[closest].z - z1 };
	--drawDebugLine(x1, y1+4, z1, 0,0,1, x1 + tempVecToVehicle.x , y1+4, z1 + tempVecToVehicle.z, 0,0,1);

	return closest;
end;

function AutoDrive:draw()

	if self.moduleInitialized == true then
		local wayPoints = self.ad.wayPoints

		if self.nCurrentWayPoint > 0 then
			local wp1 = wayPoints[self.nCurrentWayPoint]
			local wp2 = wayPoints[self.nCurrentWayPoint+1]
			if wp2 ~= nil then
				drawDebugLine(wp1.x, wp1.y+4, wp1.z, 0,1,1, wp2.x, wp2.y+4, wp2.z, 1,1,1);
			end;
			local wp0 = wayPoints[self.nCurrentWayPoint-1]
			if wp0 ~= nil then
				drawDebugLine(wp0.x, wp0.y+4, wp0.z, 0,1,1, wp1.x, wp1.y+4, wp1.z, 1,1,1);
			end;
		end;

		if self.bcreateMode == true then
			for i, wp1 in pairs(wayPoints) do
				local wp2 = wayPoints[i+1]
				if wp2 ~= nil then
					drawDebugLine(wp1.x, wp1.y+4, wp1.z, 0,1,1, wp2.x, wp2.y+4, wp2.z, 1,1,1);
				else
					drawDebugLine(wp1.x, wp1.y+4, wp1.z, 0,1,1, wp1.x, wp1.y+7, wp1.z, 1,1,1);
				end;
			end;
		end;

		if self.bCreateMapPoints == true then
			if self == g_currentMission.controlledVehicle then
				local mapWayPoints = g_currentMission.AutoDrive.mapWayPoints
				local x1,y1,z1 = getWorldTranslation(self.components[1].node);
				for i,point in pairs(g_currentMission.AutoDrive.mapWayPoints) do
					if point.out ~= nil then
						local distance = getDistance(point.x,point.z, x1,z1);
						if distance < 50 then
							for i2,neighbor in pairs(point.out) do
								local testDual = false;
								for _,incoming in pairs(point.incoming) do
									if incoming == neighbor then
										testDual = true;
										break
									end;
								end;
								local neighbor = mapWayPoints[neighbor]
								if testDual == true then
									drawDebugLine(point.x, point.y+4, point.z, 1,0,0, neighbor.x, neighbor.y+4, neighbor.z, 1,0,0);
								else
									drawDebugLine(point.x, point.y+4, point.z, 0,1,0, neighbor.x, neighbor.y+4, neighbor.z, 1,1,1);
								end;
							end;
						end;

					end;
				end;

				--local x1,y1,z1 = getWorldTranslation(self.components[1].node);
				for markerID,marker in pairs(g_currentMission.AutoDrive.mapMarker) do
					local x2,y2,z2 = getWorldTranslation(marker.node);
					local distance = getDistance(x2,z2, x1,z1);
					if distance < 50 then
						DebugUtil.drawDebugNode(marker.node, marker.name);
					end;
				end;

				--local x1,y1,z1 = getWorldTranslation(self.components[1].node);
				if self.bShowDebugMapMarker == true and mapWayPoints[1] ~= nil then
					local closest = AutoDrive:findClosestWayPoint(self);
					local wp = g_currentMission.AutoDrive.mapWayPoints[closest]
					drawDebugLine(x1, y1, z1, 0,0,1, wp.x, wp.y+4, wp.z, 0,0,1);

					--if self.printMessage == nil or string.find(self.printMessage, g_i18n:getText("AD_Debug_closest")) ~= nil then
					--	--self.printMessage = g_i18n:getText("AD_Debug_closest") .. closest;
					--	--self.nPrintTime = 6000;
					--end;

					if self.bCreateMapMarker == true and self.bEnteringMapMarker == false then
						g_currentMission.AutoDrive.mapMarkerCounter = g_currentMission.AutoDrive.mapMarkerCounter + 1;

						local node = createTransformGroup(self.sEnteredMapMarkerString);
						setTranslation(node, wp.x, wp.y + 4 , wp.z);

						g_currentMission.AutoDrive.mapMarker[g_currentMission.AutoDrive.mapMarkerCounter] = {id=closest, name=self.sEnteredMapMarkerString, node=node};
						self.bCreateMapMarker = false;
						--self.printMessage = g_i18n:getText("AD_Debug_waypoint_created_1") .. closest .. g_i18n:getText("AD_Debug_waypoint_created_2");
						--self.nPrintTime = 30000;
						AutoDrive:MarkChanged();
						g_currentMission.isPlayerFrozen = false;
						self.isBroken = false;
						--g_currentMission.controlPlayer = true;
					end;

					if self.bShowSelectedDebugPoint == true then
						if self.DebugPointsIterated[self.nSelectedDebugPoint] ~= nil then
							local dp = self.DebugPointsIterated[self.nSelectedDebugPoint]
							drawDebugLine(x1, y1, z1, 1,1,1, dp.x, dp.y+4, dp.z, 1,1,1);
						else
							self.nSelectedDebugPoint = 1;
						end;

						if self.bChangeSelectedDebugPoint == true then
							local out_counter = 1;
							local exists = false;
							for i in pairs(mapWayPoints[closest].out) do
								if exists == true then
									--print ("Entry exists "..i.. " out_counter: "..out_counter);
									mapWayPoints[closest].out[out_counter]      = mapWayPoints[closest].out[i];
									mapWayPoints[closest].out_cost[out_counter] = mapWayPoints[closest].out_cost[i];
									out_counter = out_counter +1;
								else
									if mapWayPoints[closest].out[i] == self.DebugPointsIterated[self.nSelectedDebugPoint].id then
										AutoDrive:MarkChanged()
										mapWayPoints[closest].out[i] = nil;
										mapWayPoints[closest].out_cost[i] = nil;

										--if g_currentMission.autoLoadedMap ~= nil and g_currentMission.AutoDrive.adXml ~= nil then
										--	removeXMLProperty(g_currentMission.AutoDrive.adXml, "AutoDrive." .. g_currentMission.autoLoadedMap ..	".waypoints.wp".. closest ..".out" .. i) ;
										--	removeXMLProperty(g_currentMission.AutoDrive.adXml, "AutoDrive." .. g_currentMission.autoLoadedMap ..	".waypoints.wp".. closest ..".out_cost" .. i) ;
										--end;

										local incomingExists = false;
										local sdp = self.nSelectedDebugPoint
										for j, i2 in pairs(mapWayPoints[sdp].incoming) do
											if i2 == closest or incomingExists then
												incomingExists = true;
												if mapWayPoints[sdp].incoming[j + 1] ~= nil then
													mapWayPoints[sdp].incoming[j] = mapWayPoints[sdp].incoming[j + 1];
													mapWayPoints[sdp].incoming[j + 1] = nil;
												else
													mapWayPoints[sdp].incoming[j] = nil;
												end;
											end;
										end;

										exists = true;
									else
										out_counter = out_counter +1;
									end;
								end;
							end;

							if exists == false then
								mapWayPoints[closest].out[out_counter] = self.DebugPointsIterated[self.nSelectedDebugPoint].id;
								mapWayPoints[closest].out_cost[out_counter] = 1;

								local incomingCounter = 1;
								for _,id in pairs(self.DebugPointsIterated[self.nSelectedDebugPoint].incoming) do
									incomingCounter = incomingCounter + 1;
								end;
								self.DebugPointsIterated[self.nSelectedDebugPoint].incoming[incomingCounter] = mapWayPoints[closest].id;

								AutoDrive:MarkChanged()
							end;

							self.bChangeSelectedDebugPoint = false;
						end;

						if self.bChangeSelectedDebugPointSelection == true then
							self.nSelectedDebugPoint = self.nSelectedDebugPoint + 1;
							self.bChangeSelectedDebugPointSelection = false;
						end;
					end;
				end;
			end;

			--Traffic collision debug drawing
			--[[
			if self.aiTrafficCollisionTrigger ~= nil then
				local number = getNumOfChildren(self.aiTrafficCollisionTrigger);
				if number > 3 then
					--print("Number of childrens larger three " .. number);

					local x1,y1,z1 = getWorldTranslation(getChildAt(self.aiTrafficCollisionTrigger, 1));
					local x2,y2,z2 = getWorldTranslation(getChildAt(self.aiTrafficCollisionTrigger, 2));
					local x3,y3,z3 = getWorldTranslation(getChildAt(self.aiTrafficCollisionTrigger, 3));
					local x4,y4,z4 = getWorldTranslation(getChildAt(self.aiTrafficCollisionTrigger, 4));
					drawDebugLine(x1, y1+4, z1, 1,0,0, x2, y2+4, z2, 1,0,0);
					drawDebugLine(x2, y2+4, z2, 1,0,0, x3, y3+4, z3, 1,0,0);
					drawDebugLine(x3, y3+4, z3, 1,0,0, x4, y4+4, z4, 1,0,0);
					drawDebugLine(x4, y4+4, z4, 1,0,0, x1, y1+4, z1, 1,0,0);
				else
					--print("Number of childrens: " .. number);
					local x1,y1,z1 = getWorldTranslation(self.components[1].node);
					local x2,y2,z2 = getWorldTranslation(self.aiTrafficCollisionTrigger);
					drawDebugLine(x1, y1+4, z1, 1,0,0, x2, y2+4, z2, 1,0,0);

					local parent = getParent(self.aiTrafficCollisionTrigger)
					if parent ~= nil then
						local x3,y3,z3 = getWorldTranslation(parent);
						--drawDebugLine(x2, y2+4, z2, 0,0,1, x3, y3+4, z3, 0,0,1);
					end;

				end;

				for _,coli in pairs(self.ad.collisions) do
					local x1,y1,z1 = getWorldTranslation(self.aiTrafficCollisionTrigger);
					local x2,y2,z2 = getWorldTranslation(coli);
					drawDebugLine(x1, y1+4, z1, 0,1,1, x2, y2+4, z2, 0,1,1);
				end;

			end;
			--]]
		end;

		if self == g_currentMission.controlledVehicle then

			if AutoDrive.printMessage ~= nil then
				local adFontSize = 0.014;
				local adPosX = 0.03 + g_currentMission.helpBoxWidth
				local adPosY = 0.975;
				setTextColor(1,1,1,1);
				renderText(adPosX, adPosY, adFontSize, AutoDrive.printMessage);
			elseif self.printMessage ~= nil then
				local adFontSize = 0.014;
				local adPosX = 0.03 + g_currentMission.helpBoxWidth
				local adPosY = 0.975;
				setTextColor(1,1,1,1);
				renderText(adPosX, adPosY, adFontSize, self.printMessage);
			end;
		end;

		if AutoDrive.Hud ~= nil then
			AutoDrive:drawHud(self);
		end;
	end;
end;

function AutoDrive:drawHud(vehicle)
	if vehicle ~= g_currentMission.controlledVehicle
	or false == AutoDrive.Hud.showHud
	then
		return
	end

	AutoDrive:updateButtons(vehicle);

	local ovWidth = AutoDrive.Hud.Background.width;
	local ovHeight = AutoDrive.Hud.Background.height;

	if vehicle.bEnteringMapMarker == true then
		ovHeight = ovHeight + 0.07;
	end;
	if vehicle.bUnloadAtTrigger == true then
		--ovHeight = ovHeight + 0.015;
	end;

	local buttonCounter = 0;
	for _,button in pairs(AutoDrive.Hud.Buttons) do
		buttonCounter = buttonCounter + 1;
		if button.isVisible then
			AutoDrive.Hud.rowCurrent = math.ceil(buttonCounter / AutoDrive.Hud.cols);
		end;
	end;
	ovHeight = ovHeight + (AutoDrive.Hud.rowCurrent-2) * 0.05;

	AutoDrive.Hud.Background.ov = Overlay:new(nil, AutoDrive.Hud.Background.img, AutoDrive.Hud.Background.posX, AutoDrive.Hud.Background.posY , ovWidth,	ovHeight);

	AutoDrive.Hud.Background.Header.posY = AutoDrive.Hud.posY + ovHeight - AutoDrive.Hud.Background.Header.height;
	AutoDrive.Hud.Background.Header.ov = Overlay:new(nil, AutoDrive.Hud.Background.Header.img, AutoDrive.Hud.Background.Header.posX,	AutoDrive.Hud.Background.Header.posY , AutoDrive.Hud.Background.Header.width, AutoDrive.Hud.Background.Header.height);

	AutoDrive.Hud.Background.close_small.posY = AutoDrive.Hud.posY + ovHeight - 0.0101* (g_screenWidth / g_screenHeight);
	AutoDrive.Hud.Background.close_small.ov = Overlay:new(nil, AutoDrive.Hud.Background.close_small.img, AutoDrive.Hud.Background.close_small.posX,	AutoDrive.Hud.Background.close_small.posY , AutoDrive.Hud.Background.close_small.width, AutoDrive.Hud.Background.close_small.height);

	AutoDrive.Hud.Background.ov:render();
	AutoDrive.Hud.Background.destination.ov:render();
	AutoDrive.Hud.Background.Header.ov:render();
	AutoDrive.Hud.Background.speedmeter.ov:render();
	AutoDrive.Hud.Background.divider.ov:render();
	AutoDrive.Hud.Background.close_small.ov:render();
	AutoDrive.Hud.Background.unloadOverlay.ov:render();

	for _,button in pairs(AutoDrive.Hud.Buttons) do
		if button.isVisible then
			button.ov:render();
		end;
	end;

	if true then
		local adFontSize = 0.009;
		local adPosX = AutoDrive.Hud.posX + AutoDrive.Hud.borderX; --0.03 + g_currentMission.helpBoxWidth
		local adPosY = AutoDrive.Hud.posY + ovHeight - adFontSize - 0.002; --+ 0.003; --0.975;

		setTextColor(1,1,1,1);
		renderText(adPosX, adPosY, adFontSize,"AutoDrive");
		if vehicle.ad.sToolTip ~= "" and vehicle.ad.nToolTipWait <= 0 then
			renderText(adPosX + 0.03, adPosY, adFontSize," - " .. vehicle.ad.sToolTip);
		end;
	end;

	if vehicle.sTargetSelected ~= nil then
		local adFontSize = 0.013;
		local adPosX = AutoDrive.Hud.posX + AutoDrive.Hud.Background.destination.width; -- + AutoDrive.Hud.borderX; --0.03 + g_currentMission.helpBoxWidth
		local adPosY = AutoDrive.Hud.posY + 0.04 + (AutoDrive.Hud.borderY + AutoDrive.Hud.buttonHeight) * AutoDrive.Hud.rowCurrent; --+ 0.003; --0.975;

		if vehicle.bChoosingDestination == true then
			if vehicle.sChosenDestination ~= "" then
				setTextColor(1,1,1,1);
				renderText(adPosX, adPosY, adFontSize, vehicle.sTargetSelected);
			end;
			if vehicle.sEnteredChosenDestination ~= "" then
				setTextColor(1,0,0,1);
				renderText(adPosX, adPosY, adFontSize,  vehicle.sEnteredChosenDestination);
			end;
		else
			setTextColor(1,1,1,1);
			renderText(adPosX, adPosY, adFontSize, vehicle.sTargetSelected);
		end;
		setTextColor(1,1,1,1);
		renderText(AutoDrive.Hud.posX - 0.012 + AutoDrive.Hud.width, adPosY, adFontSize, "" .. vehicle.nSpeed);

		--[[
		local img1 = Utils.getNoNil("img/createMapMarker.dds", "empty.dds" )
		local state, result = pcall( Utils.getFilename, img1, AutoDrive.directory )
		if not state then
			print("ERROR: "..tostring(result).." (img1: "..tostring(img1)..")")
			return
		end
		local target_ov = Overlay:new(nil, result, adPosX, adPosY , 0.01, 0.01* (g_screenWidth / g_screenHeight));
		target_ov:render();
		--]]
	end;

	if vehicle.bEnteringMapMarker == true then
		local adFontSize = 0.012;
		local adPosX = AutoDrive.Hud.posX + AutoDrive.Hud.borderX; --0.03 + g_currentMission.helpBoxWidth
		local adPosY = AutoDrive.Hud.posY + 0.085 + (AutoDrive.Hud.borderY + AutoDrive.Hud.buttonHeight) * AutoDrive.Hud.rowCurrent; --+ 0.003; --0.975;
		setTextColor(1,1,1,1);
		renderText(adPosX, adPosY + 0.02, adFontSize, g_i18n:getText("AD_new_marker_helptext"));
		renderText(adPosX, adPosY, adFontSize, g_i18n:getText("AD_new_marker") .. " " .. vehicle.sEnteredMapMarkerString);
	end;

	if vehicle.bUnloadAtTrigger == true then
		local adFontSize = 0.013;
		local adPosX = AutoDrive.Hud.posX + AutoDrive.Hud.Background.destination.width; --0.03 + g_currentMission.helpBoxWidth
		local adPosY = AutoDrive.Hud.posY + 0.008 + (AutoDrive.Hud.borderY + AutoDrive.Hud.buttonHeight) * AutoDrive.Hud.rowCurrent; --+ 0.003; --0.975;
		setTextColor(1,1,1,1);

		AutoDrive.Hud.Background.unloadOverlay.ov:render();
		renderText(adPosX, adPosY, adFontSize, vehicle.sTargetSelected_Unload); --g_i18n:getText("AD_intermediate") ..
	end;
end;

function AutoDrive:removeMapWayPoint(del)
		AutoDrive:MarkChanged();

		--remove node on all out going nodes
		for _, node in pairs(del.out) do
			local mapWaypointNode = g_currentMission.AutoDrive.mapWayPoints[node]
			local deleted = false;
			for j, incoming in pairs(mapWaypointNode.incoming) do
				if incoming == del.id then
					deleted = true
				end
				if deleted then
					if mapWaypointNode.incoming[j + 1] ~= nil then
						mapWaypointNode.incoming[j] = mapWaypointNode.incoming[j + 1];
					else
						mapWaypointNode.incoming[j] = nil;
					end;
				end;

			end;
		end;

		--remove node on all incoming nodes
		for _, node in pairs(g_currentMission.AutoDrive.mapWayPoints) do
			local deleted = false;
			for j,out_id in pairs(node.out) do
				if out_id == del.id then
					deleted = true;
				end;
				if deleted then
					if node.out[j + 1] ~= nil then
						node.out[j] = node.out[j+1];
						node.out_cost[j] = node.out_cost[j+1];
					else
						node.out[j] = nil;
						node.out_cost[j] = nil;
					end;
				end;
			end;
		end;

		--adjust ids for all succesive nodes :(
		local deleted = false;
		for i, node in pairs(g_currentMission.AutoDrive.mapWayPoints) do
			if i > del.id then
				local oldID = node.id;
				--adjust all possible references in nodes that have a connection with this node
				for _, innerNode in pairs(g_currentMission.AutoDrive.mapWayPoints) do
					for k, innerNodeOutID in pairs(innerNode.out) do
						if innerNodeOutID == oldID then
							innerNode.out[k] = oldID - 1;
						end;
					end;
				end;

				for _, outGoingID in pairs(node.out) do
					for k, innerNodeIncoming in pairs(g_currentMission.AutoDrive.mapWayPoints[outGoingID].incoming) do
						if innerNodeIncoming == oldID then
							g_currentMission.AutoDrive.mapWayPoints[outGoingID].incoming[k] = oldID - 1;
						end;
					end;
				end;

				g_currentMission.AutoDrive.mapWayPoints[i - 1] = node;
				node.id = node.id - 1;

				if g_currentMission.AutoDrive.mapWayPoints[i + 1] == nil then
					deleted = true;
					g_currentMission.AutoDrive.mapWayPoints[i] = nil;
					g_currentMission.AutoDrive.mapWayPointsCounter = g_currentMission.AutoDrive.mapWayPointsCounter - 1;
				end;
			end;
		end;

		--must have been last added waypoint that got deleted. handle this here:
		if deleted == false then
			g_currentMission.AutoDrive.mapWayPoints[g_currentMission.AutoDrive.mapWayPointsCounter] = nil;
			g_currentMission.AutoDrive.mapWayPointsCounter = g_currentMission.AutoDrive.mapWayPointsCounter - 1;
		end;

		--adjust all mapmarkers
		local deletedMarker = false;
		for i, marker in pairs(g_currentMission.AutoDrive.mapMarker) do
			if marker.id == del.id then
				deletedMarker = true;
			end;
			if deletedMarker then
				if g_currentMission.AutoDrive.mapMarker[i+1] ~= nil then
					g_currentMission.AutoDrive.mapMarker[i] =  g_currentMission.AutoDrive.mapMarker[i+1];
				else
					g_currentMission.AutoDrive.mapMarker[i] = nil;
				end;
			end;
			if marker.id > del.id then
				marker.id = marker.id -1;
			end;
		end;
end;

function AutoDrive:removeMapMarker(del)
	--adjust all mapmarkers
	local deletedMarker = false;
	for i, marker in pairs(g_currentMission.AutoDrive.mapMarker) do
		if marker.id == del.id then
			deletedMarker = true;
		end;
		if deletedMarker then
			if g_currentMission.AutoDrive.mapMarker[i+1] ~= nil then
				g_currentMission.AutoDrive.mapMarker[i] =  g_currentMission.AutoDrive.mapMarker[i+1];
			else
				g_currentMission.AutoDrive.mapMarker[i] = nil;
			end;
		end;
	end;
	AutoDrive:MarkChanged()
end

--function getFillType_new(fillType, implementTypeName)
--	local sFillType = g_i18n:getText("UNKNOWN");
--
--	if FillUtil.fillTypeIndexToDesc[fillType] ~= nil then
--		output1 =  FillUtil.fillTypeIndexToDesc[fillType].nameI18N
--		if string.find(output1, "Missing") then
--			sFillType = g_i18n:getText("UNKNOWN");
--		else
--			sFillType = output1;
--		end;
--	end;
--
--	return sFillType;
--end;

--function round(num, idp)
--	if Utils.getNoNil(num, 0) > 0 then
--		local mult = 10^(idp or 0);
--		return math.floor(num * mult + 0.5) / mult;
--	else
--		return 0;
--	end;
--end;

--function getPercentage(capacity, level)
--	return level / capacity * 100;
--end;

function AutoDrive:angleBetween(vec1, vec2)
	local scalarproduct_top = vec1.x * vec2.x + vec1.z * vec2.z;
	local scalarproduct_down = math.sqrt(vec1.x * vec1.x + vec1.z*vec1.z) * math.sqrt(vec2.x * vec2.x + vec2.z*vec2.z)
	local scalarproduct = scalarproduct_top / scalarproduct_down;
	return math.deg(math.acos(scalarproduct));
end

function AutoDrive:detectTraffic(vehicle, wp_next)

	local x,y,z = getWorldTranslation( vehicle.components[1].node );
	--create bounding box to check for vehicle
	local width = vehicle.sizeWidth;
	local length = vehicle.sizeLength;
	local vectorToWp = { x = wp_next.x - x, z = wp_next.z - z };
	local ortho = { x=-vectorToWp.z, z=vectorToWp.x };
	local boundingBox = {};
	boundingBox[1] ={ 	x = x + (width/2) * ( ortho.x / (math.abs(ortho.x)+math.abs(ortho.z)) ),
						z = z + (width/2) * ( ortho.z / (math.abs(ortho.x)+math.abs(ortho.z)) ) };
	boundingBox[2] ={ 	x = x - (width/2) * ( ortho.x / (math.abs(ortho.x)+math.abs(ortho.z)) ),
						z = z - (width/2) * ( ortho.z / (math.abs(ortho.x)+math.abs(ortho.z)) ) };
	boundingBox[3] ={ 	x = x - (width/2) * ( ortho.x / (math.abs(ortho.x)+math.abs(ortho.z)) ) +  (length/2 + 6) * (vectorToWp.x/(math.abs(vectorToWp.x) +	math.abs(vectorToWp.z) )),
						z = z - (width/2) * ( ortho.z / (math.abs(ortho.x)+math.abs(ortho.z)) ) +  (length/2 + 6) * (vectorToWp.z/(math.abs(vectorToWp.x) +	math.abs(vectorToWp.z) )) };
	boundingBox[4] ={ 	x = x + (width/2) * ( ortho.x / (math.abs(ortho.x)+math.abs(ortho.z)) ) +  (length/2 + 6) * (vectorToWp.x/(math.abs(vectorToWp.x) +	math.abs(vectorToWp.z) )),
						z = z + (width/2) * ( ortho.z / (math.abs(ortho.x)+math.abs(ortho.z)) ) +  (length/2 + 6) * (vectorToWp.z/(math.abs(vectorToWp.x) +	math.abs(vectorToWp.z) )) };

	--[[
	drawDebugLine(boundingBox[1].x, y+4, boundingBox[1].z, 1,0,0, boundingBox[2].x, y+4, boundingBox[2].z, 1,0,0);
	drawDebugLine(boundingBox[2].x, y+4, boundingBox[2].z, 1,0,0, boundingBox[3].x, y+4, boundingBox[3].z, 1,0,0);
	drawDebugLine(boundingBox[3].x, y+4, boundingBox[3].z, 1,0,0, boundingBox[4].x, y+4, boundingBox[4].z, 1,0,0);
	drawDebugLine(boundingBox[4].x, y+4, boundingBox[4].z, 1,0,0, boundingBox[1].x, y+4, boundingBox[1].z, 1,0,0);
	--]]

	for _,other in pairs(g_currentMission.nodeToVehicle) do --pairs(g_currentMission.vehicles) do
		if other ~= vehicle then
			local isAttachedToMe = false;

			for _i,impl in pairs(vehicle.attachedImplements) do
				if impl.object ~= nil then
					if impl.object == other then isAttachedToMe = true; end;

					if impl.object.attachedImplements ~= nil then

						for _, implement in pairs(impl.object.attachedImplements) do
							if implement.object == other then isAttachedToMe = true; end;
						end;
					end;
				end;
			end;
			if isAttachedToMe == false and other.components ~= nil then
				if other.sizeWidth == nil then
					--print("vehicle " .. other.configFileName .. " has no width");
				else
					if other.sizeLength == nil then
						print("vehicle " .. other.configFileName .. " has no length");
					else
						if other.rootNode == nil then
							print("vehicle " .. other.configFileName .. " has no root node");
						else

							local otherWidth = other.sizeWidth;
							local otherLength = other.sizeLength;
							local otherPos = {};
							otherPos.x,otherPos.y,otherPos.z = getWorldTranslation( other.components[1].node ); --getWorldTranslation(_); --

							local rx,ry,rz = localDirectionToWorld(other.components[1].node, 0, 0, 1);  --localDirectionToWorld(_,0,0,1);

							local otherVectorToWp = {};
							otherVectorToWp.x = rx --math.sin(rx);
							otherVectorToWp.z = rz --math.cos(rx);

							local otherPos2 = {};
							otherPos2.x = otherPos.x + (otherLength/2) * (otherVectorToWp.x/(math.abs(otherVectorToWp.x)+math.abs(otherVectorToWp.z)));
							otherPos2.y = y;
							otherPos2.z = otherPos.z + (otherLength/2) * (otherVectorToWp.z/(math.abs(otherVectorToWp.x)+math.abs(otherVectorToWp.z)));
							--otherPos2.x,otherPos2.y,otherPos2.z = getWorldTranslation( other.components[2].node );
							--local otherVectorToWp = { x = otherPos2.x - otherPos.x, z = otherPos2.z - otherPos.z};
							local otherOrtho = { x=-otherVectorToWp.z, z=otherVectorToWp.x };

							local otherBoundingBox = {};
							otherBoundingBox[1] ={ 	x = otherPos.x + (otherWidth/2) * ( otherOrtho.x / (math.abs(otherOrtho.x)+math.abs(otherOrtho.z))) +	(otherLength/2) * (otherVectorToWp.x/(math.abs(otherVectorToWp.x)+math.abs(otherVectorToWp.z))),
													z = otherPos.z + (otherWidth/2) * ( otherOrtho.z / (math.abs(otherOrtho.x)+math.abs(otherOrtho.z))) +	(otherLength/2) * (otherVectorToWp.z/(math.abs(otherVectorToWp.x)+math.abs(otherVectorToWp.z)))};

							otherBoundingBox[2] ={ 	x = otherPos.x - (otherWidth/2) * ( otherOrtho.x / (math.abs(otherOrtho.x)+math.abs(otherOrtho.z))) +	(otherLength/2) * (otherVectorToWp.x/(math.abs(otherVectorToWp.x)+math.abs(otherVectorToWp.z))),
													z = otherPos.z - (otherWidth/2) * ( otherOrtho.z / (math.abs(otherOrtho.x)+math.abs(otherOrtho.z))) +	(otherLength/2) * (otherVectorToWp.z/(math.abs(otherVectorToWp.x)+math.abs(otherVectorToWp.z)))};
							otherBoundingBox[3] ={ 	x = otherPos.x - (otherWidth/2) * ( otherOrtho.x / (math.abs(otherOrtho.x)+math.abs(otherOrtho.z))) -	(otherLength/2) * (otherVectorToWp.x/(math.abs(otherVectorToWp.x)+math.abs(otherVectorToWp.z))),
													z = otherPos.z - (otherWidth/2) * ( otherOrtho.z / (math.abs(otherOrtho.x)+math.abs(otherOrtho.z))) -	(otherLength/2) * (otherVectorToWp.z/(math.abs(otherVectorToWp.x)+math.abs(otherVectorToWp.z)))};

							otherBoundingBox[4] ={ 	x = otherPos.x + (otherWidth/2) * ( otherOrtho.x / (math.abs(otherOrtho.x)+math.abs(otherOrtho.z))) -	(otherLength/2) * (otherVectorToWp.x/(math.abs(otherVectorToWp.x)+math.abs(otherVectorToWp.z))),
													z = otherPos.z + (otherWidth/2) * ( otherOrtho.z / (math.abs(otherOrtho.x)+math.abs(otherOrtho.z))) -	(otherLength/2) * (otherVectorToWp.z/(math.abs(otherVectorToWp.x)+math.abs(otherVectorToWp.z)))};

							--[[
							drawDebugLine(otherPos.x,y+4,otherPos.z, 1,0,0, otherPos2.x,y+4,otherPos2.z, 1,0,0);
							drawDebugLine(otherBoundingBox[1].x, y+4, otherBoundingBox[1].z, 0,0,1, otherBoundingBox[2].x, y+4, otherBoundingBox[2].z, 0,0,1);
							drawDebugLine(otherBoundingBox[2].x, y+4, otherBoundingBox[2].z, 0,0,1, otherBoundingBox[3].x, y+4, otherBoundingBox[3].z, 0,0,1);
							drawDebugLine(otherBoundingBox[3].x, y+4, otherBoundingBox[3].z, 0,0,1, otherBoundingBox[4].x, y+4, otherBoundingBox[4].z, 0,0,1);
							drawDebugLine(otherBoundingBox[4].x, y+4, otherBoundingBox[4].z, 0,0,1, otherBoundingBox[1].x, y+4, otherBoundingBox[1].z, 0,0,1);
							--]]

							if AutoDrive:BoxesIntersect(boundingBox, otherBoundingBox) == true then
								if other.configFileName ~= nil then
									--print("vehicle " .. vehicle.configFileName .. " has collided with " .. other.configFileName);
								else
									if other.name ~= nil then
										--print("vehicle " .. vehicle.configFileName .. " has collided with " .. other.name);
									else
										--print("vehicle " .. vehicle.configFileName .. " has collided with " .. "unknown");
									end;
								end;
								return true;
							end;

						end;
					end;
				end;
			end;
		end;
	end;

	return false;
end

function AutoDrive:BoxesIntersect(a,b)


		local polygons = {a, b};
		local minA, maxA,minB,maxB;

		for i,polygon in pairs(polygons) do

			-- for each polygon, look at each edge of the polygon, and determine if it separates
			-- the two shapes

			for i1, corners in pairs(polygon) do
				--grab 2 vertices to create an edge
				local i2 = (i1%4 + 1) ;
				local p1 = polygon[i1];
				local p2 = polygon[i2];

				-- find the line perpendicular to this edge
				local normal = { x =  p2.z - p1.z, z = p1.x - p2.x };

				minA = nil;
				maxA = nil;
				-- for each vertex in the first shape, project it onto the line perpendicular to the edge
				-- and keep track of the min and max of these values

				for j,corner in pairs(polygons[1]) do
					local projected = normal.x * corner.x + normal.z * corner.z;
					if minA == nil or projected < minA then
						minA = projected;
					end;
					if maxA == nil or projected > maxA then
						maxA = projected;
					end;
				end;

				--for each vertex in the second shape, project it onto the line perpendicular to the edge
				--and keep track of the min and max of these values
				minB = nil;
				maxB = nil;
				for j, corner in pairs(polygons[2]) do
					projected = normal.x * corner.x + normal.z * corner.z;
					if minB == nil or projected < minB then
						minB = projected;
					end;
					if maxB == nil or projected > maxB then
							maxB = projected;
					end;
				end;
				-- if there is no overlap between the projects, the edge we are looking at separates the two
				-- polygons, and we know there is no overlap
				if maxA < minB or maxB < minA then
					--print("polygons don't intersect!");
					return false;
				end;
			end;
		end;

		--print("polygons intersect!");
		return true;

end

function AutoDrive:adOnTrafficCollisionTrigger(triggerId, otherId, onEnter, onLeave, onStay, otherShapeId)
	if otherId == self.rootNode then
		return
	end;
	if not self.isMotorStarted then return; end;
	if self.aiTrafficCollisionTrigger ~= nil then
		if self.aiTrafficCollisionTrigger == otherId then
			return;
		end;
	end;
	if otherId == Player.rootNode then
		return;
	end;

	if onEnter then
		local alreadyExists = false;
		local counter = 0;
		for _,coli in pairs(self.ad.collisions) do
			if coli == otherId then
				alreadyExists = true;
			end;
			counter = counter + 1;
		end;
		if not alreadyExists then
			self.ad.collisions[counter+1] = otherId;
		end;
	end;
	if onLeave then
		local alreadyExists = false;
		for _,coli in pairs(self.ad.collisions) do
			if coli == otherId then
				alreadyExists = true;
			end;
			if alreadyExists then
				if self.ad.collisions[_+1] ~= nil then
					self.ad.collisions[_] = self.ad.collisions[_+1];
				else
					self.ad.collisions[_] = nil;
				end;
			end;
		end;
	end;

	--adding traffic vehicle to nodeToVehicle List - code from courseplays traffic detection
	-- is this a traffic vehicle?

	local vehicle = g_currentMission.nodeToVehicle[otherId];
	local cm = getCollisionMask(otherId);
	if vehicle == nil then
		print("Vehicle unknown. cm: " .. cm);
	else
		--if vehicle.debuggedmessage ~= true then
			print("vehicle already in list. cm: " .. cm);
			--vehicle.debuggedmessage = true;
		--end;
	end;

	local x,y,z = getWorldTranslation( self.components[1].node );
	local rx,ry,rz = localDirectionToWorld(self.components[1].node, 0, 0, 1);
	local x1,y1,z1 = getWorldTranslation( otherId );
	local rx2,ry2,rz2 = localDirectionToWorld(otherId, 0, 0, 1);

	if getDistance(x,z,x1,z1) < 3 then
		--print("vehicle too close. cm: " .. cm);
		return;
	end;

	if vehicle == nil and (cm == 1056768 or cm == 2105410)  then --bitAND(cm, 2097152) ~= 0 then -- if bit21 is part of the collisionMask then set new vehicle	in GCM.NTV
		print("Adding path vehicle");
		local pathVehicle = {}
		pathVehicle.rootNode = otherId
		pathVehicle.components = {};
		pathVehicle.components[1] = {};
		pathVehicle.components[1].node = otherId;
		pathVehicle.isCpPathvehicle = true
		pathVehicle.name = "PathVehicle"
		pathVehicle.sizeLength = 7
		pathVehicle.sizeWidth = 3
		g_currentMission.nodeToVehicle[otherId] = pathVehicle
	end;


end;

function AutoDrive:detectAdTrafficOnRoute(vehicle)
	--self.ad.wayPoints
	--self.nCurrentWayPoint
	if vehicle.bActive == true then
		local idToCheck = 3;
		local alreadyOnDualRoute = false;
		if vehicle.ad.wayPoints[vehicle.nCurrentWayPoint-2] ~= nil and vehicle.ad.wayPoints[vehicle.nCurrentWayPoint-1] ~= nil then
			if vehicle.ad.wayPoints[vehicle.nCurrentWayPoint-2].incoming ~= nil then
				for _,incoming in pairs(vehicle.ad.wayPoints[vehicle.nCurrentWayPoint-2].incoming) do
					if incoming == vehicle.ad.wayPoints[vehicle.nCurrentWayPoint-1].id then
						alreadyOnDualRoute = true;
					end;
				end;
			end;
		end;
		if vehicle.ad.wayPoints[vehicle.nCurrentWayPoint+idToCheck] ~= nil and vehicle.ad.wayPoints[vehicle.nCurrentWayPoint+idToCheck+1] ~= nil and not	alreadyOnDualRoute then
			local dualRoute = false;
			for _,incoming in pairs(vehicle.ad.wayPoints[vehicle.nCurrentWayPoint+idToCheck].incoming) do
				if incoming == vehicle.ad.wayPoints[vehicle.nCurrentWayPoint+idToCheck+1].id then
					dualRoute = true;
				end;
			end;

			local dualRoutePoints = {};
			local counter = 0;
			idToCheck = -3;
			while dualRoute == true or idToCheck < 3 do
				if vehicle.ad.wayPoints[vehicle.nCurrentWayPoint+idToCheck] ~= nil and vehicle.ad.wayPoints[vehicle.nCurrentWayPoint+idToCheck+1] ~= nil then
					local testDual = false;
					for _,incoming in pairs(vehicle.ad.wayPoints[vehicle.nCurrentWayPoint+idToCheck].incoming) do
						if incoming == vehicle.ad.wayPoints[vehicle.nCurrentWayPoint+idToCheck+1].id then
							testDual = true;
						end;
					end;
					if testDual == true then
						counter = counter + 1;
						dualRoutePoints[counter] = vehicle.ad.wayPoints[vehicle.nCurrentWayPoint+idToCheck].id;
					else
						dualRoute = false;
					end;
				end;
				idToCheck = idToCheck + 1;
			end;

			local trafficDetected = false;
			vehicle.trafficVehicle = nil;
			if counter > 0 then
				for _,other in pairs(g_currentMission.nodeToVehicle) do
					if other ~= vehicle and other.bActive == true then
						local onSameRoute = false;
						local window = 2;
						local i = -window;
						while i <= window do
							if other.ad.wayPoints[other.nCurrentWayPoint+i] ~= nil then
								for _,point in pairs(dualRoutePoints) do
									if point == other.ad.wayPoints[other.nCurrentWayPoint+i].id then
										onSameRoute = true;
									end;
								end;
							end;
							i = i + 1;
						end;
						if onSameRoute == true and other.trafficVehicle == nil then
							trafficDetected = true;
							vehicle.trafficVehicle = other;
						end;
					end;
				end;
			end;
			if trafficDetected == true then
				--print("Traffic deteced");
				return true;
			end;

		end;

	end;
	return false;

end

function AutoDrive:ExportRoutes()
	AutoDrive.adExportSaveFolderPath = getUserProfileAppPath() .. 'autoDriveExport';
	createFolder(AutoDrive.adExportSaveFolderPath);

	AutoDrive.adImportSaveFolderPath = getUserProfileAppPath() .. 'autoDriveImport';
	createFolder(AutoDrive.adImportSaveFolderPath);

	local exportFile = AutoDrive.adExportSaveFolderPath  .. "/AutoDrive_export.xml";

	print("AD: creating xml file at " .. exportFile);
	local exportXml = createXMLFile("AutoDrive_XML", exportFile, "AutoDrive");

	setXMLString(exportXml, "AutoDrive.Version", AutoDrive.Version);
	setXMLBool(exportXml, "AutoDrive.Recalculation", not g_currentMission.AutoDrive.handledRecalculation);

	local tagName = "AutoDrive"
	AutoDrive.writeWaypointsAndMarkers(exportXml, tagName)

	saveXMLFile(exportXml);
end;

function AutoDrive:ImportRoutes()
	AutoDrive.adImportSaveFolderPath = getUserProfileAppPath() .. 'autoDriveImport';

	local importFile = AutoDrive.adImportSaveFolderPath  .. "/AutoDrive_export.xml";

	if fileExists(importFile) then
		print("AD: Importing xml file from " .. importFile);
		local importXml = loadXMLFile("AutoDrive_XML", importFile);

		local tagName = "AutoDrive"
		AutoDrive.readWaypointsAndMarkers(importXml, tagName)

		AutoDrive.config_changed = true;
	else
		print("AD: Import File does not exist: " .. importFile);
	end;
end

addModEventListener(AutoDrive);

--InputEvent%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%	%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
--InputEvent%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%	%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
--InputEvent%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%	%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


AutoDriveInputEvent = {};
AutoDriveInputEvent_mt = Class(AutoDriveInputEvent, Event);

InitEventClass(AutoDriveInputEvent, "AutoDriveInputEvent");

function AutoDriveInputEvent:emptyNew()
    local self = Event:new(AutoDriveInputEvent_mt);
    self.className="AutoDriveInputEvent";
    return self;
end;

function AutoDriveInputEvent:new(vehicle)
    local self = AutoDriveInputEvent:emptyNew()
    self.vehicle = vehicle;

	self.bActive = vehicle.bActive;
	self.bRoundTrip = vehicle.bRoundTrip;
	self.bReverseTrack = vehicle.bReverseTrack;
	self.bDrivingForward = vehicle.bDrivingForward;
	self.nTargetX = vehicle.nTargetX;
	self.nTargetZ = vehicle.nTargetZ;
	self.bInitialized = vehicle.bInitialized;
	self.wayPoints = vehicle.ad.wayPoints;
	self.bcreateMode = vehicle.bcreateMode;
	self.nCurrentWayPoint = vehicle.nCurrentWayPoint;
	self.nlastLogged = vehicle.nlastLogged;
	self.nloggingInterval = vehicle.nloggingInterval;
	self.logMessage = vehicle.logMessage;
	self.nPrintTime = vehicle.nPrintTime;
	self.ntargetSelected = vehicle.ntargetSelected;
	self.bTargetMode = vehicle.bTargetMode;
	self.nMapMarkerSelected = vehicle.nMapMarkerSelected;
	self.nSpeed = vehicle.nSpeed;
	self.bCreateMapPoints = vehicle.bCreateMapPoints;
	self.bShowDebugMapMarker = vehicle.bShowDebugMapMarker;
	self.nSelectedDebugPoint = vehicle.nSelectedDebugPoint;
	self.bShowSelectedDebugPoint = vehicle.bShowSelectedDebugPoint;
	self.bChangeSelectedDebugPoint = vehicle.bChangeSelectedDebugPoint;
	self.DebugPointsIterated = vehicle.DebugPointsIterated;
	self.sTargetSelected = vehicle.sTargetSelected;
	self.bStopAD = vehicle.bStopAD;
	self.bforceIsActive = vehicle.forceIsActive;
	self.bStopMotorOnLeave = vehicle.stopMotorOnLeave;

	self.bDeadLock = vehicle.bDeadLock; --new
	self.nTimeToDeadLock = vehicle.nTimeToDeadLock;
	self.bDeadLockRepairCounter = vehicle.bDeadLockRepairCounter;
	self.bCreateMapMarker =  vehicle.bCreateMapMarker;
	self.bEnteringMapMarker =  vehicle.bEnteringMapMarker;
	self.sEnteredMapMarkerString =  vehicle.sEnteredMapMarkerString;
	self.currentInput = vehicle.currentInput;

	self.bUnloadAtTrigger = vehicle.bUnloadAtTrigger;
	self.bUnloading = vehicle.bUnloading;
	self.bPaused = vehicle.bPaused;
	self.bUnloadSwitch = vehicle.bUnloadSwitch;
	self.unloadType = vehicle.unloadType;
	self.bLoading = vehicle.bLoading;
	self.trailertipping = vehicle.trailertipping;

	self.ntargetSelected_Unload = vehicle.ntargetSelected_Unload;
	self.nMapMarkerSelected_Unload = vehicle.nMapMarkerSelected_Unload;
	self.sTargetSelected_Unload = vehicle.sTargetSelected_Unload;


	--print("event new")
    return self;
end;

function AutoDriveInputEvent:writeStream(streamId, connection)
    streamWriteInt32(streamId, networkGetObjectId(self.vehicle));

	streamWriteBool(streamId, self.bActive);
	streamWriteBool(streamId, self.bRoundTrip);
	streamWriteBool(streamId, self.bReverseTrack);
	streamWriteBool(streamId, self.bDrivingForward);

	streamWriteFloat32(streamId, self.nTargetX);
	streamWriteFloat32(streamId, self.nTargetZ);

	streamWriteBool(streamId, self.bInitialized);

	self.wayPointsString = "";
	for i, point in pairs(self.wayPoints) do
		if self.wayPointsString == "" then
			self.wayPointsString = self.wayPointsString .. point.id;
		else
			self.wayPointsString = self.wayPointsString .. "," .. point.id;
		end;
	end;
	streamWriteString(streamId, self.wayPointsString);

	streamWriteBool(streamId, self.bcreateMode);
	streamWriteFloat32(streamId, self.nCurrentWayPoint);
	streamWriteFloat32(streamId, self.nlastLogged);
	streamWriteFloat32(streamId, self.nloggingInterval);
	streamWriteString(streamId, self.logMessage);
	streamWriteFloat32(streamId, self.nPrintTime);
	streamWriteFloat32(streamId, self.ntargetSelected);
	streamWriteBool(streamId, self.bTargetMode);
	streamWriteFloat32(streamId, self.nMapMarkerSelected);
	streamWriteFloat32(streamId, self.nSpeed);
	streamWriteBool(streamId, self.bCreateMapPoints);
	streamWriteBool(streamId, self.bShowDebugMapMarker);
	streamWriteFloat32(streamId, self.nSelectedDebugPoint);
	streamWriteBool(streamId, self.bShowSelectedDebugPoint);
	streamWriteBool(streamId, self.bChangeSelectedDebugPoint);

	self.debugPointsIteratedString = "";
	for i, point in pairs(self.DebugPointsIterated) do
		if self.debugPointsIteratedString == "" then
			self.debugPointsIteratedString = debugPointsIteratedString .. point.id;
		else

			self.debugPointsIteratedString = debugPointsIteratedString .. "," .. point.id;
		end;
	end;
	streamWriteString(streamId, self.debugPointsIteratedString);


	streamWriteString(streamId, self.sTargetSelected);
	streamWriteBool(streamId, self.bStopAD);
	streamWriteBool(streamId, self.bforceIsActive);
	streamWriteBool(streamId, self.bStopMotorOnLeave);

	streamWriteBool(streamId, self.bDeadLock);
	streamWriteFloat32(streamId, self.nTimeToDeadLock);
	streamWriteFloat32(streamId, self.bDeadLockRepairCounter);
	streamWriteBool(streamId, self.bCreateMapMarker);
	streamWriteBool(streamId, self.bEnteringMapMarker);
	streamWriteString(streamId, self.sEnteredMapMarkerString);
	streamWriteString(streamId, self.currentInput);

	streamWriteBool(streamId, self.bUnloadAtTrigger);
	streamWriteBool(streamId, self.bUnloading);
	streamWriteBool(streamId, self.bPaused);
	streamWriteBool(streamId, self.bUnloadSwitch);
	streamWriteFloat32(streamId, self.unloadType);
	streamWriteBool(streamId, self.bLoading);
	streamWriteFloat32(streamId, self.trailertipping);

	streamWriteFloat32(streamId, self.ntargetSelected_Unload);
	streamWriteFloat32(streamId, self.nMapMarkerSelected_Unload);
	streamWriteString(streamId, self.sTargetSelected_Unload);

	-- print("event writeStream")
end;

function AutoDriveInputEvent:readStream(streamId, connection)
    --print("Received Event");

	local id = streamReadInt32(streamId);
    local vehicle = networkGetObject(id);

	local bActive = streamReadBool(streamId);
	local bRoundTrip = streamReadBool(streamId);
	local bReverseTrack = streamReadBool(streamId);
	local bDrivingForward = streamReadBool(streamId);
	local nTargetX = streamReadFloat32(streamId);
	local nTargetZ = streamReadFloat32(streamId);
	local bInitialized = streamReadBool(streamId);

	local wayPointsString = streamReadString(streamId);
	local wayPointID = Utils.splitString(",", wayPointsString);
	local wayPoints = {};
	for i,id in pairs(wayPointID) do
		wayPoints[i] = g_currentMission.AutoDrive.mapWayPoints[id];
	end;

	local bcreateMode = streamReadBool(streamId);
	local nCurrentWayPoint = streamReadFloat32(streamId);
	local nlastLogged = streamReadFloat32(streamId);
	local nloggingInterval = streamReadFloat32(streamId);
	local logMessage = streamReadString(streamId);
	local nPrintTime = streamReadFloat32(streamId);
	local ntargetSelected = streamReadFloat32(streamId);
	local bTargetMode = streamReadBool(streamId);
	local nMapMarkerSelected = streamReadFloat32(streamId);
	local nSpeed = streamReadFloat32(streamId);
	local bCreateMapPoints = streamReadBool(streamId);
	local bShowDebugMapMarker = streamReadBool(streamId);
	local nSelectedDebugPoint = streamReadFloat32(streamId);
	local bShowSelectedDebugPoint = streamReadBool(streamId);
	local bChangeSelectedDebugPoint = streamReadBool(streamId);

	local DebugPointsIteratedString = streamReadString(streamId);
	local DebugPointsID = Utils.splitString(",", DebugPointsIteratedString);
	local DebugPointsIterated = {};
	for i,id in pairs(DebugPointsID) do
		DebugPointsID[i] = g_currentMission.AutoDrive.mapWayPoints[id];
	end;

	local sTargetSelected = streamReadString(streamId);
	local bStopAD = streamReadBool(streamId);
	local bforceIsActive = streamReadBool(streamId);
	local bStopMotorOnLeave = streamReadBool(streamId);

	local bDeadLock = streamReadBool(streamId);
	local nTimeToDeadLock = streamReadFloat32(streamId);
	local bDeadLockRepairCounter = streamReadFloat32(streamId);
	local bCreateMapMarker = streamReadBool(streamId);
	local bEnteringMapMarker = streamReadBool(streamId);
	local sEnteredMapMarkerString = streamReadString(streamId);
	local currentInput = streamReadString(streamId);

	local bUnloadAtTrigger = streamReadBool(streamId);
	local bUnloading = streamReadBool(streamId);
	local bPaused = streamReadBool(streamId);
	local bUnload = streamReadBool(streamId);
	local unloadType = streamReadFloat32(streamId);
	local bLoading = streamReadBool(streamId);
	local trailertipping = streamReadFloat32(streamId);

	local ntargetSelected_Unload = streamReadFloat32(streamId);
	local nMapMarkerSelected_Unload = streamReadFloat32(streamId);
	local sTargetSelected_Unload = streamReadString(streamId);

	if g_server ~= nil then
		vehicle.currentInput = currentInput;
	else
		vehicle.bActive = bActive;
		vehicle.bRoundTrip = bRoundTrip;
		vehicle.bReverseTrack = bReverseTrack ;
		vehicle.bDrivingForward = bDrivingForward;
		vehicle.nTargetX = nTargetX ;
		vehicle.nTargetZ = nTargetZ;
		vehicle.bInitialized = bInitialized;
		if vehicle.ad ~= nil then
			vehicle.ad.wayPoints = wayPoints ;
		end;
		vehicle.bcreateMode = bcreateMode;
		vehicle.nCurrentWayPoint = nCurrentWayPoint ;
		vehicle.nlastLogged = nlastLogged;
		vehicle.nloggingInterval = nloggingInterval;
		vehicle.logMessage = logMessage;
		vehicle.nPrintTime = nPrintTime;
		vehicle.ntargetSelected = ntargetSelected;
		vehicle.bTargetMode = bTargetMode;
		vehicle.nMapMarkerSelected = nMapMarkerSelected ;
		vehicle.nSpeed = nSpeed;
		vehicle.bCreateMapPoints = bCreateMapPoints;
		vehicle.bShowDebugMapMarker = bShowDebugMapMarker;
		vehicle.nSelectedDebugPoint = nSelectedDebugPoint;
		vehicle.bShowSelectedDebugPoint = bShowSelectedDebugPoint;
		vehicle.bChangeSelectedDebugPoint = bChangeSelectedDebugPoint;
		vehicle.DebugPointsIterated = DebugPointsIterated ;
		vehicle.sTargetSelected = sTargetSelected;
		vehicle.bStopAD = bStopAD;
		vehicle.forceIsActive = bforceIsActive;
		vehicle.stopMotorOnLeave = bStopMotorOnLeave;

		vehicle.bDeadLock = bDeadLock;
		vehicle.nTimeToDeadLock = nTimeToDeadLock;
		vehicle.bDeadLockRepairCounter = bDeadLockRepairCounter;
		vehicle.bCreateMapMarker = bCreateMapMarker;
		vehicle.bEnteringMapMarker = bEnteringMapMarker;
		vehicle.sEnteredMapMarkerString = sEnteredMapMarkerString;

		vehicle.bUnloadAtTrigger = bUnloadAtTrigger;
		vehicle.bUnloading = bUnloading;
		vehicle.bPaused = bPaused;
		vehicle.bUnload = bUnload;
		vehicle.unloadType = unloadType;
		vehicle.bLoading = bLoading;
		vehicle.trailertipping = trailertipping;

		vehicle.ntargetSelected_Unload = ntargetSelected_Unload;
		vehicle.nMapMarkerSelected_Unload = nMapMarkerSelected_Unload;
		vehicle.sTargetSelected_Unload = sTargetSelected_Unload;

	end;




	if g_server ~= nil then
		g_server:broadcastEvent(AutoDriveInputEvent:new(vehicle), nil, nil, vehicle);
		-- print("broadcasting")
	end;
end;

function AutoDriveInputEvent:sendEvent(vehicle)
	if g_server ~= nil then
		g_server:broadcastEvent(AutoDriveInputEvent:new(vehicle), nil, nil, vehicle);
		-- print("broadcasting")
	else
		g_client:getServerConnection():sendEvent(AutoDriveInputEvent:new(vehicle));
		-- print("sending event to server...")
	end;
end;


--MapEvent%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%	%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
--MapEvent%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%	%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
--MapEvent%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%	%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


AutoDriveMapEvent = {};
AutoDriveMapEvent_mt = Class(AutoDriveMapEvent, Event);

InitEventClass(AutoDriveMapEvent, "AutoDriveMapEvent");

function AutoDriveMapEvent:emptyNew()
	local self = Event:new(AutoDriveMapEvent_mt);
	self.className="AutoDriveMapEvent";
	return self;
end;

function AutoDriveMapEvent:new(vehicle)
	local self = AutoDriveMapEvent:emptyNew()
	self.vehicle = vehicle;
	--print("event new")
	return self;
end;

function AutoDriveMapEvent:writeStream(streamId, connection)

	if g_server ~= nil then
		print("Broadcasting waypoints");

		local idFullTable = {};
		local idString = "";
		local idCounter = 0;

		local xTable = {};
		local xString = "";

		local yTable = {};
		local yString = "";

		local zTable = {};
		local zString = "";

		local outTable = {};
		local outString = "";

		local incomingTable = {};
		local incomingString = "";

		local out_costTable = {};
		local out_costString = "";

		local markerNamesTable = {};
		local markerNames = "";

		local markerIDsTable = {};
		local markerIDs = "";

		for i,p in pairs(g_currentMission.AutoDrive.mapWayPoints) do

			--idString = idString .. p.id .. ",";
			idFullTable[i] = p.id;
			idCounter = idCounter + 1;
			--xString = xString .. p.x .. ",";
			xTable[i] = p.x;
			--yString = yString .. p.y .. ",";
			yTable[i] = p.y;
			--zString = zString .. p.z .. ",";
			zTable[i] = p.z;

			--outString = outString .. table.concat(p.out, ",") .. ";";
			outTable[i] = table.concat(p.out, ",");

			local innerIncomingTable = {};
			local innerIncomingCounter = 1;
			for i2, p2 in pairs(g_currentMission.AutoDrive.mapWayPoints) do
				for i3, out2 in pairs(p2.out) do
					if out2 == p.id then
						innerIncomingTable[innerIncomingCounter] = p2.id;
						innerIncomingCounter = innerIncomingCounter + 1;
						--incomingString = incomingString .. p2.id .. ",";
					end;
				end;
			end;
			incomingTable[i] = table.concat(innerIncomingTable, ",");
			--incomingString = incomingString .. ";";

			out_costTable[i] = table.concat(p.out_cost, ",");
			--out_costString = out_costString .. table.concat(p.out_cost, ",") .. ";";

			local markerCounter = 1;
			local innerMarkerNamesTable = {};
			local innerMarkerIDsTable = {};
			for i2,marker in pairs(p.marker) do
				innerMarkerIDsTable[markerCounter] = marker;
				--markerIDs = markerIDs .. marker .. ",";
				innerMarkerNamesTable[markerCounter] = i2;
				--markerNames = markerNames .. i2 .. ",";
				markerCounter = markerCounter + 1;
			end;

			markerNamesTable[i] = table.concat(innerMarkerNamesTable, ",");
			markerIDsTable[i] = table.concat(innerMarkerIDsTable, ",");

			--markerIDs = markerIDs .. ";";
			--markerNames = markerNames .. ";";
		end;

		if idFullTable[1] ~= nil then
			streamWriteFloat32(streamId, idCounter);
			local i = 1;
			while i <= idCounter do
				streamWriteFloat32(streamId,idFullTable[i]);
				streamWriteFloat32(streamId,xTable[i]);
				streamWriteFloat32(streamId,yTable[i]);
				streamWriteFloat32(streamId,zTable[i]);
				streamWriteString(streamId,outTable[i]);
				streamWriteString(streamId,incomingTable[i]);
				streamWriteString(streamId,out_costTable[i]);
				if markerIDsTable[1] ~= nil then
					streamWriteString(streamId, markerIDsTable[i]);
					streamWriteString(streamId, markerNamesTable[i]);
				else
					streamWriteString(streamId, "");
					streamWriteString(streamId, "");
				end;
				i = i + 1;

			end;
		end;

		local markerIDs = "";
		local markerNames = "";
		local markerCounter = 0;
		for i in pairs(g_currentMission.AutoDrive.mapMarker) do
			markerCounter = markerCounter + 1;
		end;
		streamWriteFloat32(streamId, markerCounter);
		local i = 1;
		while i <= markerCounter do
			streamWriteFloat32(streamId, g_currentMission.AutoDrive.mapMarker[i].id);
			streamWriteString(streamId, g_currentMission.AutoDrive.mapMarker[i].name);
			i = i + 1;
		end;




	else
		print("Requesting waypoints");
		streamWriteInt32(streamId, networkGetObjectId(self.vehicle));
	end;

	--print("event writeStream")
end;

function AutoDriveMapEvent:readStream(streamId, connection)
	print("Received Event");

	if g_server ~= nil then
		print("Receiving request for broadcasting waypoints");
		local id = streamReadInt32(streamId);
		local vehicle = networkGetObject(id);

		AutoDriveMapEvent:sendEvent(vehicle)
	else
		print("Receiving waypoints");
		if g_currentMission.AutoDrive.receivedWaypoints ~= true then

			local pointCounter = streamReadFloat32(streamId);
			if pointCounter > 0 then
				g_currentMission.AutoDrive.mapWayPoints = {};
			end;

			local wp_counter = 0;
			while wp_counter < pointCounter do


					wp_counter = wp_counter +1;
					local wp = {};
					wp["id"] =  streamReadFloat32(streamId);
					wp.x = streamReadFloat32(streamId);
					wp.y =	streamReadFloat32(streamId);
					wp.z = streamReadFloat32(streamId);

					local outString = streamReadString(streamId);
					local outTable = Utils.splitString("," , outString);
					wp["out"] = {};
					for i2,outString in pairs(outTable) do
						wp["out"][i2] = tonumber(outString);
					end;

					local incomingString = streamReadString(streamId);
					local incomingTable = Utils.splitString("," , incomingString);
					wp["incoming"] = {};
					local incoming_counter = 1;
					for i2, incomingID in pairs(incomingTable) do
						if incomingID ~= "" then
							wp["incoming"][incoming_counter] = tonumber(incomingID);
						end;
						incoming_counter = incoming_counter +1;
					end;

					local out_costString = streamReadString(streamId);
					local out_costTable = Utils.splitString("," , out_costString);
					wp["out_cost"] = {};
					for i2,out_costString in pairs(out_costTable) do
						wp["out_cost"][i2] = tonumber(out_costString);
					end;



					local markerIDsString = streamReadString(streamId);
					local markerIDsTable = Utils.splitString("," , markerIDsString);
					local markerNamesString = streamReadString(streamId);
					local markerNamesTable = Utils.splitString("," , markerNamesString);
					wp["marker"] = {};
					for i2, markerName in pairs(markerNamesTable) do
						if markerName ~= "" then
							wp.marker[markerName] = tonumber(markerIDsTable[i2]);
						end;
					end;

					g_currentMission.AutoDrive.mapWayPoints[wp_counter] = wp;
			end;

			if g_currentMission.AutoDrive.mapWayPoints[wp_counter] ~= nil then
				print("AD: Loaded Waypoints: " .. wp_counter);
				g_currentMission.AutoDrive.mapWayPointsCounter = wp_counter;
			else
				g_currentMission.AutoDrive.mapWayPointsCounter = 0;
			end;

			local mapMarkerCounter = streamReadFloat32(streamId);
			local mapMarkerCount = 1;

			if mapMarkerCounter ~= 0 then
				g_currentMission.AutoDrive.mapMarker = {}
				print("AD: Loaded Destinations: " .. mapMarkerCounter);
			end;

			while mapMarkerCount <= mapMarkerCounter do
				local markerId = streamReadFloat32(streamId);
				local markerName = streamReadString(streamId);
				local marker = {};

				local node = createTransformGroup(markerName);
				setTranslation(node, g_currentMission.AutoDrive.mapWayPoints[markerId].x, g_currentMission.AutoDrive.mapWayPoints[markerId].y + 4 ,	g_currentMission.AutoDrive.mapWayPoints[markerId].z  );

				marker.node=node;

				marker.id = markerId;
				marker.name = markerName;

				g_currentMission.AutoDrive.mapMarker[mapMarkerCount] = marker;
				mapMarkerCount = mapMarkerCount + 1;
			end;
			g_currentMission.AutoDrive.mapMarkerCounter = mapMarkerCounter;

			g_currentMission.AutoDrive.receivedWaypoints = true;
		end;

	end;


end;

function AutoDriveMapEvent:sendEvent(vehicle)
	if g_server ~= nil then
		g_server:broadcastEvent(AutoDriveMapEvent:new(vehicle), nil, nil, nil);
		--print("broadcasting")
	else
		g_client:getServerConnection():sendEvent(AutoDriveMapEvent:new(vehicle));
		--print("sending event to server...")
	end;
end;

--StoreBackup%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%	%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
--StoreBackup%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%	%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
--StoreBackup%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%	%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


function AutoDrive.backupADFiles(self)
	if g_server == nil and g_dedicatedServerInfo == nil then return end;

	if not fileExists(g_currentMission.AutoDrive.xmlSaveFile) then
		return;
	end;

	local savegameIndex = g_currentMission.missionInfo.savegameIndex;
	AutoDrive.adTempSaveFolderPath = getUserProfileAppPath() .. 'autoDriveBackupSavegame' .. savegameIndex;
	createFolder(AutoDrive.adTempSaveFolderPath);

	AutoDrive.adFileBackupPath = AutoDrive.adTempSaveFolderPath .. '/AutoDrive_config.xml';
	copyFile(g_currentMission.AutoDrive.xmlSaveFile, AutoDrive.adFileBackupPath, true);

end;
g_careerScreen.saveSavegame = Utils.prependedFunction(g_careerScreen.saveSavegame, AutoDrive.backupADFiles);

function AutoDrive.restoreBackup(self)
	if g_server == nil and g_dedicatedServerInfo == nil then return end;

	if not AutoDrive.adFileBackupPath then return end;

	local savegameIndex = g_currentMission.missionInfo.savegameIndex;
	local savegameFolderPath = getUserProfileAppPath() .. "savegame" .. g_currentMission.missionInfo.savegameIndex;

	if fileExists(savegameFolderPath .. '/careerSavegame.xml') then
		-- savegame isn't corrupted and has been saved correctly
		-- copy backed up files back to our savegame directory
		copyFile(AutoDrive.adFileBackupPath, g_currentMission.AutoDrive.xmlSaveFile, true);
		AutoDrive.adFileBackupPath = nil;
	end;
end;
g_careerScreen.saveSavegame = Utils.appendedFunction(g_careerScreen.saveSavegame, AutoDrive.restoreBackup);
