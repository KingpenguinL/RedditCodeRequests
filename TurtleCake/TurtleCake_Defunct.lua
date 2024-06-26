--	==DEFUNCT COPY!!==
-- Author: KingpneguinL
-- Version: 1.1.1
-- Purpose: Making a cake from items in a chest in front, placing bottles in a chest underneath, placing a cake in-world above turtle.
-- REQUIRES: FARMER'S DELIGHT


-- PERIPHERALS --
CFront = peripheral.wrap("front") -- Chest in front
CBottom = peripheral.wrap("bottom") -- Chest under

-- ITEM CODES --
itmMilk = "farmersdelight:milk_bottle"
itmWheat = "minecraft:wheat"
itmSugar = "minecraft:sugar"
itmEgg = "minecraft:egg"
itmBottle = "minecraft:glass_bottle"
itmCake = "minecraft:cake"

-- COUNTING (for quality assurance) --
intCakeCount = 0

-- Functions --
-- Clear and reset terminal screen
function ResetScreen()
	term.clear()
	term.setCursorPos(1,1)
end



-- Clear turtle inventory
function TurtleClear()
	-- Loop attempt to clear every slot
	for i = 1, 16 do
		turtle.select(i)
		if turtle.getItemDetail(i) ~= nil then	-- If I didn't check prior, a empty slot would error out
			local ID = turtle.getItemDetail(i).name
			if ID == itmBottle or ID == itmBucket then
				turtle.dropDown()
			else
				turtle.drop()
			end
		end
	end
	
	-- Check if all areas are actually clear, else hold for user intervention
	for i = 1, 16 do
		turtle.select(i)
		if turtle.getItemDetail() ~= nil then
			print("Can't clear inventory, please remove manually.")
			os.pullEvent("turtle_inventory")
			
		end
	end
end



-- Checks chest for sufficient ingredients
function ChestCheck()
	local cntSugar = 0
	local cntMilk = 0
	local cntWheat = 0
	local cntEgg = 0
	local blnEnable = true
	local blnCake = false
	local aEmpty = {};
	
	turtle.select(1)
	for i = 1, CFront.size() do
		if CFront.getItemDetail(i) ~= nil then -- If I didn't check prior, a empty slot would error out
			local Item = CFront.getItemDetail(i).name
			local Count = CFront.getItemDetail(i).count
			if Item == itmEgg then
				cntEgg = cntEgg + Count
			elseif Item == itmMilk then
				cntMilk = cntMilk + Count
			elseif Item == itmSugar then
				cntSugar = cntSugar + Count
			elseif Item == itmWheat then
				cntWheat = cntWheat + Count
			elseif Item == itmCake then
				blnCake = true
				break -- cake found, skip for loop
			elseif Item == nil and i > 4 then	-- disqualify slots 1-4 from empty list
				table.insert(aEmpty, i)
			end
		end
	end
	
	if blnCake == false then
		-- Check egg
		if cntEgg < 0 then
			ResetScreen()
			print("Not enough eggs")
			blnEnable = false
		end
		
		-- Check milk
		if cntMilk < 3 then
			ResetScreen()
			print("Not enough milk")
			blnEnable = false
		end
		
		-- Check sugar
		if cntSugar < 2 then
			ResetScreen()
			print("Not enough sugar")
			blnEnable = false
		end
		
		-- Check wheat
		if cntWheat < 3 then
			ResetScreen()
			print("Not enough wheat")
			blnEnable = false
		end
	else
		print("Cake found! Skipping process")
		blnEnable = true
	end
	
	return blnCake, blnEnable, aEmpty
end



-- Confirms or clears first 4 slots of front chest
function ClearFirst4(aEmpty)
	local blnOverflow = false	-- If the first 4 slots cannot be cleared, consider it overflowing. Will be resolved later in script.
	if table.maxn(aEmpty) >= 4 then
		for i=1,4 do
			if CFront.getItemDetail(i) ~= nil then	-- If there's nothing blocking first 4, then skip clearing
				CFront.pushItems("front",i,64,aEmpty[i])	-- Shift items to clear 1-4
			end
		end
	else -- Not enough empty spaces, combine where possible then throw excess items and pick up later
		for i=1,4 do
			for j=5,CFront.size() do
				CFront.pushItems("front",i,64,j)
			end
			if CFront.getItemDetail(i) ~= nil then
				if blnOverflow == false then	-- won't overwrite a true
					blnOverflow = true
				end
			end
		end
	end
	
	return blnOverflow
end



-- Moves all required items to first 4 slots of front chest
function SortChest(blnOverflow)
	
	if blnOverflow == true then
		turtle.select(2)	-- Turtle's holding slot
		turtle.suck()	--pick up a slot in chest to free at least 1 for sorting, into the holding slot in turtle
	end
	turtle.select(1)
	-- Sorts ingredients to first 4 slots, forces max stack if possible
	for i = 1, CFront.size() do
		if CFront.getItemDetail(i) ~= nil then	-- skip if nil or it will break the program
			local ID = CFront.getItemDetail(i).name
			if ID == itmEgg then
				CFront.pushItems("front",i,16,1)	-- Any eggs to slot 1
			elseif ID == itmMilk then
				CFront.pushItems("front",i,64,2)	-- Any milk to slot 2
			elseif ID == itmSugar then
				CFront.pushItems("front",i,64,3)	-- Any sugar to slot 3
			elseif ID == itmWheat then
				CFront.pushItems("front",i,64,4)	-- Any wheat to slot 4
			end
		end
	end
	if blnOverflow == true then
		turtle.select(2)	-- Turtle's holding slot
		turtle.drop()		-- Return overflow item to Chest
	end

end



-- Pulls items from front chest to turtle (1st slot 'input'), divies up for recipe, puts excess on right most slots to be returned
function PullChest(blnCake)
	for i = 1,4 do
	turtle.select(1)
		turtle.suck() -- Pick item from 1st available slot in chest
		if turtle.getItemDetail() ~= false then
			local Item = turtle.getItemDetail(1).name
			local Count = turtle.getItemDetail(1).count
			if Item == itmEgg and Count >= 1 then
				turtle.transferTo(10, 1)
				-- move excess aside
				turtle.transferTo(4,64)
			elseif Item == itmMilk and Count >= 3 then
				turtle.transferTo(5,1)
				turtle.transferTo(6,1)
				turtle.transferTo(7,1)
				-- move excess aside
				turtle.transferTo(8,64)
			elseif Item == itmSugar and Count >= 2 then
				turtle.transferTo(9, 1)
				turtle.transferTo(11, 1)
				-- move excess aside
				turtle.transferTo(12,64)
			elseif Item == itmWheat and Count >= 3 then
				turtle.transferTo(13,1)
				turtle.transferTo(14,1)
				turtle.transferTo(15,1)
				-- move excess aside
				turtle.transferTo(16,64)
			else
				-- Junk, throw out.
				turtle.dropUp()
			end
		end
	end
end



-- If cake detected in input chest, use this to take it from front chest
function TakeCake()
	-- Free chest slot 1 for cake)
	turtle.select(2)
	turtle.suck()
	
	-- Find cake
	for i = 1, CFront.size() do
		if CFront.getItemDetail(i) ~= nil then	-- skip if nil or it will break the program
			local ID = CFront.getItemDetail(i).name
			if ID == itmCake then
				CFront.pushItems("front",i,1,1)	-- Any eggs to slot 1
			end
		end
	end
	
	-- Obtain cake
	turtle.select(3)
	turtle.suck()
	
	-- Return held ITEM
	turtle.select(2)
	turtle.drop()
end


-- Clean Turtle excess for crafting
function PrepCraft()
	local aSlots = {1,2,3,4,8,12,16}	-- All slots in turtle we need to be empty
	for i=1,table.maxn(aSlots) do
		turtle.select(aSlots[i])
		turtle.drop()
	end
	-- Emergancy catch if somehow the chest can't take remaining itmes. (yeet and collect later)
	for i=1,table.maxn(aSlots) do
		turtle.select(aSlots[i])
		turtle.dropUp()
	end
end


-- Craft the cake
function Bake()
	turtle.select(3)	-- Turtle's output slot
	local blnCrafted = turtle.craft(1)		-- Cakes do not stack, make 1
	if blnCrafted == false then
		print("Crafting failed... Clearing.")
		TurtleClear()
		print("I'm sorry :< I'll try again...")
		Recover()
		MainLoop()	-- Start over, hopefully it gets corrected
	end
	
end



-- Recover any items from PrepCraft() Emergancy dump
function Recover()
	turtle.suckUp()
end



-- Place cake
function PlaceCake()
	turtle.select(3)
	turtle.placeUp()	-- Place cake slot on top of turtle
end



function MainLoop()
	local blnReady = false -- boolean enough chest ingredients
	local aEmpty = {} -- Empty chest spaces for sorting
	
	ResetScreen()
	print("Cakes since wake: "..intCakeCount)
	if turtle.detectUp() == false then
		--
		print("Checking for ingredients...")
		while blnReady == false do
			blnCake, blnReady, aEmpty  = ChestCheck()
			if blnReady == false then
				print("Waiting for ingredients...")
				os.sleep(10) -- Wait 10 seconds and check again
				MainLoop()
			end
		end
		--
		if blnCake == false then
			--
			print("Clearing Turtle...")
			TurtleClear()
			--
			print("Clearing first 4 slots...")
			blnOverflow = ClearFirst4(aEmpty)
			--
			print("Sorting chest...")
			SortChest(blnOverflow)
			--
			print("Pulling from Chest to Turtle...")
			PullChest()
			--
			print("Preparing to cook...")
			PrepCraft()
			--
			print("Cooking...")
			Bake()
			--
			print("Cleaning any tossed items...")
			Recover()
		else
			-- Take cake from chest
			TakeCake()
		end
		--
		print("Placing cake...")
		PlaceCake()
		print("Cake is served!")
		
		-- Cleanup and count
		TurtleClear()
		intCakeCount = intCakeCount +  1
		print("Cakes since wake: "..intCakeCount)
		os.sleep(3)
	else
		print("Cake present, wait 10 sec")
		os.sleep(10)	-- Cake present, sleep for 10 seconds
	end
end



-- RUNTIME --
ResetScreen()
print("Program init, please hold...")
TurtleClear() -- Initial clearing of turtle inventory
while true do
	ResetScreen()
	MainLoop()
end


-- TODO: make MainLoop prints cleaner by term.setCursorPos(x,y) + term.clearLine() over previous status.

--I H O /e		1 	2 	3 	4		Input,Hold,Output
--m m m /m		5 	6 	7 	8
--s e s /s		9 	10 	11 	12
--w w w /w		13 	14 	15 	16