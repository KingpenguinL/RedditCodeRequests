-- Author: KingpneguinL
-- Version: 1.3 [Kludge beta edition]
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



-- Clears and writes over previous line to save screen spaces
function CurUp()
	local curX,curY = term.getCursorPos()
	curY = curY - 1
	
	term.setCursorPos(1,curY)
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
			TurtleClear()
		end
	end
end



function ScanChest(intSlot)
	local Item = "Empty"
	local Count = 0
	
	if CFront.getItemDetail(intSlot) ~= nil then
		Item = CFront.getItemDetail(intSlot).name
		Count = CFront.getItemDetail(intSlot).count
	end
	
	return Item, Count
end



function ScanTurtle(intSlot)	-- Intended for a 1-slot check inside a loop
	local Item = "Empty"

	
	if turtle.getItemDetail(intSlot) ~= nil then
		Item = turtle.getItemDetail(intSlot).name
	end
	
	return Item
end


-- Sorts from a pre-established slot in turtle to item's appropriate storage slot
function SortTurtle(Item)
	if Item == itmEgg then
		turtle.transferTo(4,16)
	elseif Item == itmMilk then
		turtle.transferTo(8,16)
	elseif Item == itmSugar then
		turtle.transferTo(12,64)
	elseif Item == itmWheat then
		turtle.transferTo(16,64)
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
		CItem,CCount = ScanChest(i)
			if CItem == itmEgg then
				cntEgg = cntEgg + CCount
			elseif CItem == itmMilk then
				cntMilk = cntMilk + CCount
			elseif CItem == itmSugar then
				cntSugar = cntSugar + CCount
			elseif CItem == itmWheat then
				cntWheat = cntWheat + CCount
			elseif CItem == itmCake then
				blnCake = true
				break -- cake found, skip for loop
			elseif CItem == "Empty" and i > 4 then	-- disqualify slots 1-4 from empty list
				table.insert(aEmpty, i)
			end
	end
	
	if blnCake == false then
		-- Check egg
		if cntEgg < 0 then
			ResetScreen()
			print("Not enough eggs")
			blnEnable = false
		else
			print("Eggs: "..cntEgg)
		end
		
		-- Check milk
		if cntMilk < 3 then
			ResetScreen()
			print("Not enough milk")
			blnEnable = false
		else
			print("Milks: "..cntMilk)
		end
		
		-- Check sugar
		if cntSugar < 2 then
			ResetScreen()
			print("Not enough sugar")
			blnEnable = false
		else
			print("Sugar: "..cntSugar)
		end
		
		-- Check wheat
		if cntWheat < 3 then
			ResetScreen()
			print("Not enough wheat")
			blnEnable = false
		else
			print("Wheat: "..cntWheat)
		end
	else
		print("Cake found! Skipping process")
		blnEnable = true
	end
	
	return blnCake, blnEnable, aEmpty
end


-- Pulls 4 slots from chest to be sure there are 4 open slots to sort with
function ClearFirst4()	
	turtle.select(1)
	for i=1,4 do
		if ScanTurtle(1) == "Empty" then	-- If first turtle slot is empty
			turtle.select(1)
			turtle.suck()	-- Take 1st item stack from first available from chest
			SortTurtle(ScanTurtle(1))	-- Send item name to show where to store the stack, then store it if possible
		
		elseif ScanTurtle(2) == "Empty" then	-- If second turtle slot is empty
			turtle.select(2)
			turtle.suck()	-- Take 2nd item stack from first available from chest
			SortTurtle(ScanTurtle(2))	-- Send item name to show where to store the stack, then store it if possible
		
		elseif ScanTurtle(3) == "Empty" then	-- If third turtle slot is empty
			turtle.select(3)
			turtle.suck()	-- Take 3rd item stack from first available from chest
			SortTurtle(ScanTurtle(3))	-- Send item name to show where to store the stack, then store it if possible
		
		elseif ScanTurtle(4) == "Empty" then	-- If fourth turtle slot is empty
			turtle.select(4)
			turtle.suck()	-- Take 4th item stack from first available from chest
			SortTurtle(ScanTurtle(4))	-- Send item name to show where to store the stack, then store it if possible
		
		else
			error("Error in SortTurtle. Somehow all 4 slots are taken and a new entry was attempted.")
		end
	end
end



-- Moves all required items to first 4 slots of front chest
function SortChest()
	turtle.select(1)
	-- Sorts ingredients to first 4 slots, forces max stack if possible
	for i = 1, CFront.size() do
		local CItem = ScanChest(i)
		if CItem == itmEgg then
			CFront.pushItems("front",i,16,1)	-- Any eggs to slot 1
		elseif CItem == itmMilk then
			CFront.pushItems("front",i,16,2)	-- Any milk to slot 2
		elseif CItem == itmSugar then
			CFront.pushItems("front",i,64,3)	-- Any sugar to slot 3
		elseif CItem == itmWheat then
			CFront.pushItems("front",i,64,4)	-- Any wheat to slot 4
		end
	end
end



-- Inverse of PullFirst4() to return turtle's inventory.
function ReturnFirst4()
	local aClearOrder = {4,8,12,16,1,2,3}
	
	for i=1,table.maxn(aClearOrder) do				-- if a slot in 1-4 is not empty, skip the return until the end
		if i>=1 and i<=4 then
			local Name,Count = ScanChest(i)
			if Name == "Empty" then
				turtle.select(aClearOrder[i])	-- Select slots in return order
				turtle.drop()					-- Deposits Items
			end
		end
	end
	
	-- double check that turtle inventory is empty
	TurtleClear()
end



-- Pulls items from front chest to turtle (1st slot 'input'), divies up for recipe, puts excess on right most slots to be returned
function PullChest(blnCake)
	for i = 1,4 do
		local CItem, CCount = ScanChest(i)
		-- Select turtle slot 1
		turtle.select(1)
		turtle.suck()	-- Temporary skip limiting stack size. In theory this isn't an issue by this point.
		if CItem == itmEgg and CCount >= 1 then
			turtle.transferTo(10, 1)
			-- move excess aside
			turtle.transferTo(4,16)
		elseif CItem == itmMilk and CCount >= 3 then
			turtle.transferTo(5,1)
			turtle.transferTo(6,1)
			turtle.transferTo(7,1)
			-- move excess aside
			turtle.transferTo(8,16)
		elseif CItem == itmSugar and CCount >= 2 then
			turtle.transferTo(9, 1)
			turtle.transferTo(11, 1)
			-- move excess aside
			turtle.transferTo(12,64)
		elseif CItem == itmWheat and CCount >= 3 then
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



-- If cake detected in input chest, use this to take it from front chest
function TakeCake()
	-- Free chest slot 1 for cake)
	turtle.select(3)
	turtle.suck()
	
	-- Find and shift cake
	for i = 1, CFront.size() do

			if ScanChest(i) == itmCake then
				CFront.pushItems("front",i,1,1)	-- Move cake to front
			end
	end
	
	-- Obtain cake
	turtle.select(3)
	turtle.suck(1)
	
	-- Return held ITEM
	turtle.select(2)
	turtle.drop()
end


-- Clean Turtle excess for crafting
function PrepCraft()
	local aSlots = {1,2,3,4,8,12,16}	-- All slots in turtle we need to be empty
	local aCraft = {5,6,7,9,10,11,13,14,15}	-- All spaces used in crafting
	for i=1,table.maxn(aSlots) do
		turtle.select(aSlots[i])
		turtle.drop()
	end
	-- Emergancy catch if somehow the chest can't take remaining itmes. (yeet and collect later)
	for i=1,table.maxn(aSlots) do
		turtle.select(aSlots[i])
		turtle.dropUp()
	end
	-- Check recipe!!
	local blnRecipe = true
	for i=1,table.maxn(aCraft) do
		if turtle.getItemDetail(aCraft[i]) ~= nil then
			if i==1 or i==2 or i==3 then
				if turtle.getItemDetail(aCraft[i]).name ~= itmMilk then
					print("Wrong item! [slot "..i.."]")
					blnRecipe = false 
					--break
				else
					if blnRecipe == true then
						blnRecipe = true
					end
				end
			elseif i==4 or i==6 then
				if turtle.getItemDetail(aCraft[i]).name ~= itmSugar then
					print("Wrong item! [slot "..i.."]")
					blnRecipe = false 
					--break
				else
					if blnRecipe == true then
						blnRecipe = true
					end
				end
			elseif i==5 then
				if turtle.getItemDetail(aCraft[i]).name ~= itmEgg then
					print("Wrong item! [slot "..i.."]")
					blnRecipe = false 
					--break
				else
					if blnRecipe == true then
						blnRecipe = true
					end
				end
			elseif i==7 or i==8 or i==9 then
				if turtle.getItemDetail(aCraft[i]).name ~= itmWheat then
					print("Wrong item! [slot "..i.."]")
					blnRecipe = false 
					--break
				else
					if blnRecipe == true then
						blnRecipe = true
					end
				end
			end
		else
			print("Item missing! [slot "..i.."]")
			blnRecipe = false
		end
	end
	
	if blnRecipe == true then
		print("Cooking...")
		Bake()
	else
		print("Recipe isn't correct.")
		print("Waiting for user inspection, press any key to continue...")
		os.pullEvent("key")
		TurtleClear()
		MainLoop()
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
	turtle.placeUp(1)	-- Place cake slot on top of turtle
end



function MainLoop()
	local blnReady = false -- boolean enough chest ingredients
	local aEmpty = {} -- Empty chest spaces for sorting
	local aItem = {};
	local aCount= {};
	
	ResetScreen()
	print("Cakes since wake: "..intCakeCount)
	
	--
	print("Checking for ingredients...")
	
	-- Loop check until enough ingredients arre confirmed
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
		ClearFirst4()
		--
		print("Sorting chest...")
		SortChest()
		--
		print("Returning items...")
		ReturnFirst4()
		--
		print("Pulling from Chest to Turtle...")
		PullChest()
		--
		print("Preparing to cook...")
		PrepCraft()
		--
		-- something missing??
		--
		print("Cleaning any tossed items...")
		Recover()
	else
		-- Take cake from chest
		TakeCake()
	end
	
	--
	local blnSpaceTop = false	-- Assume cake can't be placed until it checks first.
	while blnSpaceTop == false do
		if turtle.detectUp() == false then
			blnSpaceTop = true
			print("Placing cake...")
			PlaceCake()
			print("Cake is served!")
		else
			CurUp()
			print("Cake present, wait 4 sec")
			os.sleep(4)	-- Cake present, sleep for 10 seconds
		end
	end
	-- Cleanup and count
	TurtleClear()
	intCakeCount = intCakeCount +  1
	print("Cakes since wake: "..intCakeCount)
	os.sleep(3)
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



-- SERIOUSLY BROKEN as of v1.2--
-- FIX: replace SortChest() with old system of going through slots, but impliment new Filter for eggs and milk slot limiting.
-- The new 'snapshot' methodology is not compatible with a full inventory.

-- FIX: if recipe is wrong, it might make it anyway. Double check that.